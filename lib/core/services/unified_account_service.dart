import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/account_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';

/// Unified Account Service
/// Handles all account operations (credit cards, debit cards, cash accounts) in a single service
class UnifiedAccountService {
  static const String _collectionName = 'accounts';

  /// Get all accounts for current user
  static Future<List<AccountModel>> getAllAccounts({
    bool forceServerRead = false,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final query = FirebaseFirestoreService.getCollection(
        _collectionName,
      ).where('is_active', isEqualTo: true);

      // Force server read if needed (to avoid stale cache)
      final snapshot = forceServerRead
          ? await query.get(const GetOptions(source: Source.server))
          : await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Ensure id is set correctly - use doc.id as the primary id
        final accountData = {
          ...data,
          'id': doc.id, // This should override any existing id in data
        };

        return AccountModel.fromJson(accountData);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      rethrow;
    }
  }

  /// Get accounts by type
  static Future<List<AccountModel>> getAccountsByType(AccountType type) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('type', isEqualTo: type.value)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AccountModel.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching accounts by type: $e');
      rethrow;
    }
  }

  /// Get account by ID
  static Future<AccountModel?> getAccountById(
    String accountId, {
    bool forceServerRead = false,
  }) async {
    try {
      final DocumentReference docRef = FirebaseFirestoreService.getDocument(
        _collectionName,
        accountId,
      );

      // Force server read if needed (to avoid stale cache)
      final doc = forceServerRead
          ? await docRef.get(const GetOptions(source: Source.server))
          : await docRef.get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return AccountModel.fromJson({'id': doc.id, ...data});
    } catch (e) {
      debugPrint('Error fetching account: $e');
      rethrow;
    }
  }

  /// Add new account
  static Future<String> addAccount(AccountModel account) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final accountData = {
        ...account.toJson(),
        'user_id': userId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: accountData,
      );

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update account
  static Future<bool> updateAccount(AccountModel account) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final accountData = {
        ...account.toJson(),
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: account.id,
        data: accountData,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update account balance
  static Future<bool> updateBalance({
    required String accountId,
    required double newBalance,
  }) async {
    try {
      // Get account to check credit limit
      final account = await getAccountById(accountId);
      if (account == null) throw Exception('Hesap bulunamadı');

      // For credit cards, validate against credit limit
      if (account.type == AccountType.credit && account.creditLimit != null) {
        // For credit cards, balance represents debt
        // newBalance should not exceed credit limit
        if (newBalance > account.creditLimit!) {
          throw Exception(
            'Kredi limiti aşıldı. Mevcut limit: ${account.creditLimit}, İstenen tutar: $newBalance',
          );
        }
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: accountId,
        data: {
          'balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating account balance: $e');
      return false;
    }
  }

  /// Increment account balance atomically (prevents race conditions)
  static Future<void> incrementBalance({
    required String accountId,
    required double amount,
  }) async {
    try {
      debugPrint('💰 incrementBalance (ATOMIC): Account ID: $accountId');
      debugPrint('   Increment Amount: $amount');

      // Get account before update to verify
      final accountBefore = await getAccountById(accountId);
      debugPrint(
        '   📊 ÖNCE - ${accountBefore?.name}: Balance = ${accountBefore?.balance}',
      );

      // Use FieldValue.increment for atomic update
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: accountId,
        data: {
          'balance': FieldValue.increment(amount),
          'updated_at': FieldValue.serverTimestamp(),
        },
      );

      // Get account after update to verify
      final accountAfter = await getAccountById(accountId);
      debugPrint(
        '   📊 SONRA - ${accountAfter?.name}: Balance = ${accountAfter?.balance}',
      );
      debugPrint('   ✅ Atomic increment başarılı');
    } catch (e) {
      debugPrint('   ❌ Atomic increment hatası: $e');
      rethrow;
    }
  }

  /// Add amount to account balance
  static Future<void> addToBalance({
    required String accountId,
    required double amount,
  }) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) throw Exception('Hesap bulunamadı');

      debugPrint('💰 addToBalance: ${account.name} (${account.type.value})');
      debugPrint('   Mevcut Balance: ${account.balance}');
      debugPrint('   Eklenecek Amount: $amount');
      final newBalance = account.balance + amount;
      debugPrint('   Yeni Balance: $newBalance');

      await updateBalance(accountId: accountId, newBalance: newBalance);
    } catch (e) {
      rethrow;
    }
  }

  /// Subtract amount from account balance
  static Future<void> subtractFromBalance({
    required String accountId,
    required double amount,
  }) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) throw Exception('Hesap bulunamadı');

      final newBalance = account.balance - amount;
      await updateBalance(accountId: accountId, newBalance: newBalance);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete account (soft delete)
  static Future<bool> deleteAccount(String accountId) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: accountId,
        data: {'is_active': false, 'updated_at': FieldValue.serverTimestamp()},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get real-time account updates stream
  static Stream<List<AccountModel>> getAccountStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return AccountModel.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Get accounts by type stream
  static Stream<List<AccountModel>> getAccountStreamByType(AccountType type) {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('type', isEqualTo: type.value)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return AccountModel.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Get total balance for all accounts
  static Future<double> getTotalBalance() async {
    try {
      final accounts = await getAllAccounts();
      double total = 0.0;
      for (final account in accounts) {
        total += account.balance;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  /// Get total credit limit for credit cards
  static Future<double> getTotalCreditLimit() async {
    try {
      final creditCards = await getAccountsByType(AccountType.credit);
      double total = 0.0;
      for (final card in creditCards) {
        total += (card.creditLimit ?? 0.0);
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  /// Get total used credit for credit cards
  static Future<double> getTotalUsedCredit() async {
    try {
      final creditCards = await getAccountsByType(AccountType.credit);
      double total = 0.0;
      for (final card in creditCards) {
        total += card.usedCredit;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  /// Get credit utilization percentage
  static Future<double> getCreditUtilization() async {
    try {
      final totalLimit = await getTotalCreditLimit();
      final usedCredit = await getTotalUsedCredit();

      if (totalLimit == 0) return 0.0;
      return (usedCredit / totalLimit) * 100;
    } catch (e) {
      rethrow;
    }
  }
}

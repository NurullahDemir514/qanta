import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/cash_account.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';

/// Firebase Cash Account Service
/// Handles all cash account operations for the Qanta app
class FirebaseCashAccountService {
  static const String _collectionName = 'cash_accounts';

  /// Get user's cash account
  static Future<CashAccount?> getUserCashAccount() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(
          _collectionName,
        ).where('user_id', isEqualTo: userId).limit(1),
      );

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return CashAccount.fromJson({'id': snapshot.docs.first.id, ...data});
    } catch (e) {
      debugPrint('Error getting cash account: $e');
      rethrow;
    }
  }

  /// Create or update cash account
  static Future<String> createOrUpdateCashAccount(CashAccount account) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final accountData = {
        ...account.toJson(),
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Check if account exists
      final existingAccount = await getUserCashAccount();

      if (existingAccount != null) {
        // Update existing account
        await FirebaseFirestoreService.updateDocument(
          collectionName: _collectionName,
          docId: existingAccount.id,
          data: accountData,
        );
        return existingAccount.id;
      } else {
        // Create new account
        final docRef = await FirebaseFirestoreService.addDocument(
          collectionName: _collectionName,
          data: accountData,
        );
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error creating/updating cash account: $e');
      rethrow;
    }
  }

  /// Update cash account balance
  static Future<void> updateBalance({
    required String accountId,
    required double newBalance,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: accountId,
        data: {
          'balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete cash account
  static Future<void> deleteCashAccount(String accountId) async {
    try {
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _collectionName,
        docId: accountId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get cash account stream for real-time updates
  static Stream<CashAccount?> getCashAccountStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(
        _collectionName,
      ).where('user_id', isEqualTo: FirebaseAuthService.currentUserId).limit(1),
    ).map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return CashAccount.fromJson({'id': snapshot.docs.first.id, ...data});
    });
  }

  /// Add amount to cash account
  static Future<void> addAmount({
    required String accountId,
    required double amount,
  }) async {
    try {
      final account = await getUserCashAccount();
      if (account == null) throw Exception('Nakit hesap bulunamadı');

      final newBalance = account.balance + amount;
      await updateBalance(accountId: accountId, newBalance: newBalance);
    } catch (e) {
      debugPrint('Error adding amount to cash account: $e');
      rethrow;
    }
  }

  /// Subtract amount from cash account
  static Future<void> subtractAmount({
    required String accountId,
    required double amount,
  }) async {
    try {
      final account = await getUserCashAccount();
      if (account == null) throw Exception('Nakit hesap bulunamadı');

      if (account.balance < amount) {
        throw Exception('Yetersiz bakiye');
      }

      final newBalance = account.balance - amount;
      await updateBalance(accountId: accountId, newBalance: newBalance);
    } catch (e) {
      debugPrint('Error subtracting amount from cash account: $e');
      rethrow;
    }
  }
}

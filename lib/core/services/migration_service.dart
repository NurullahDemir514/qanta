import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/account_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';
import 'unified_account_service.dart';
import 'unified_transaction_service.dart';

/// Migration Service
/// Handles migration from old structure to new unified structure
class MigrationService {
  
  /// Migrate all user data to new structure
  static Future<void> migrateUserData() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');


      // 1. Migrate credit cards
      await _migrateCreditCards(userId);
      
      // 2. Migrate debit cards
      await _migrateDebitCards(userId);
      
      // 3. Migrate cash accounts
      await _migrateCashAccounts(userId);
      
      // 4. Migrate transactions
      await _migrateTransactions(userId);
      
      // 5. Migrate categories
      await _migrateCategories(userId);

    } catch (e) {
      rethrow;
    }
  }

  /// Migrate credit cards from old structure to new accounts collection
  static Future<void> _migrateCreditCards(String userId) async {
    try {

      // Get old credit cards
      final oldCardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('credit_cards')
          .get();

      for (final doc in oldCardsSnapshot.docs) {
        final data = doc.data();
        
        // Convert to new AccountModel
        final account = AccountModel(
          id: doc.id,
          userId: userId,
          type: AccountType.credit,
          name: data['name'] ?? 'Credit Card',
          bankName: data['bank_name'],
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          creditLimit: (data['credit_limit'] as num?)?.toDouble(),
          statementDay: data['statement_day'] as int?,
          dueDay: data['due_day'] as int?,
          isActive: data['is_active'] ?? true,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        // Add to new accounts collection
        await UnifiedAccountService.addAccount(account);
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Migrate debit cards from old structure to new accounts collection
  static Future<void> _migrateDebitCards(String userId) async {
    try {

      // Get old debit cards
      final oldCardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('debit_cards')
          .get();

      for (final doc in oldCardsSnapshot.docs) {
        final data = doc.data();
        
        // Convert to new AccountModel
        final account = AccountModel(
          id: doc.id,
          userId: userId,
          type: AccountType.debit,
          name: data['name'] ?? 'Debit Card',
          bankName: data['bank_name'],
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          isActive: data['is_active'] ?? true,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        // Add to new accounts collection
        await UnifiedAccountService.addAccount(account);
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Migrate cash accounts from old structure to new accounts collection
  static Future<void> _migrateCashAccounts(String userId) async {
    try {

      // Get old cash accounts
      final oldAccountsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cash_accounts')
          .get();

      for (final doc in oldAccountsSnapshot.docs) {
        final data = doc.data();
        
        // Convert to new AccountModel
        final account = AccountModel(
          id: doc.id,
          userId: userId,
          type: AccountType.cash,
          name: data['name'] ?? 'Cash Account',
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          isActive: data['is_active'] ?? true,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        // Add to new accounts collection
        await UnifiedAccountService.addAccount(account);
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Migrate transactions from old structure to new transactions collection
  static Future<void> _migrateTransactions(String userId) async {
    try {

      // Get old transactions
      final oldTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      for (final doc in oldTransactionsSnapshot.docs) {
        final data = doc.data();
        
        // Convert to new TransactionWithDetailsV2
        final transaction = TransactionWithDetailsV2(
          id: doc.id,
          userId: userId,
          accountId: data['account_id'] ?? '',
          type: _convertTransactionType(data['type']),
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
          categoryId: data['category_id'],
          categoryName: data['category_name'],
          transactionDate: (data['transaction_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPaid: data['is_paid'] ?? true,
          installmentId: data['installment_id'],
          installmentNumber: data['installment_number'] as int?,
          totalInstallments: data['total_installments'] as int?,
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        // Add to new transactions collection
        await UnifiedTransactionService.addTransaction(transaction);
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Migrate categories from old structure to new categories collection
  static Future<void> _migrateCategories(String userId) async {
    try {

      // Get old categories
      final oldCategoriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      for (final doc in oldCategoriesSnapshot.docs) {
        final data = doc.data();
        
        // Convert to new category structure
        final categoryData = {
          'id': doc.id,
          'user_id': userId,
          'type': data['type'] ?? 'expense',
          'name': data['name'] ?? 'Category',
          'icon': data['icon'] ?? 'category',
          'color': data['color'] ?? '#6B7280',
          'parent_id': data['parent_id'],
          'is_system': data['is_system'] ?? false,
          'is_active': data['is_active'] ?? true,
          'sort_order': data['sort_order'] ?? 0,
          'created_at': (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updated_at': (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };

        // Add to new categories collection
        await FirebaseFirestoreService.addDocument(
          collectionName: 'categories',
          data: categoryData,
        );
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Convert old transaction type to new enum
  static TransactionType _convertTransactionType(String? oldType) {
    switch (oldType) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) return false;

      // Check if new accounts collection exists and has data
      final newAccountsSnapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: 'accounts',
        query: FirebaseFirestoreService.getCollection('accounts').limit(1),
      );

      // If new structure has data, migration is not needed
      if (newAccountsSnapshot.docs.isNotEmpty) return false;

      // Check if old structure has data
      final oldCreditCards = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('credit_cards')
          .limit(1)
          .get();

      final oldDebitCards = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('debit_cards')
          .limit(1)
          .get();

      final oldCashAccounts = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cash_accounts')
          .limit(1)
          .get();

      // If old structure has data, migration is needed
      return oldCreditCards.docs.isNotEmpty || 
             oldDebitCards.docs.isNotEmpty || 
             oldCashAccounts.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clean up old collections after successful migration
  static Future<void> cleanupOldCollections() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');


      // Delete old collections
      await _deleteCollection('users/$userId/credit_cards');
      await _deleteCollection('users/$userId/debit_cards');
      await _deleteCollection('users/$userId/cash_accounts');
      await _deleteCollection('users/$userId/transactions');
      await _deleteCollection('users/$userId/categories');

    } catch (e) {
      rethrow;
    }
  }

  /// Delete a collection and all its documents
  static Future<void> _deleteCollection(String collectionPath) async {
    try {
      final collection = FirebaseFirestore.instance.collection(collectionPath);
      final batch = FirebaseFirestore.instance.batch();
      
      final snapshot = await collection.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}

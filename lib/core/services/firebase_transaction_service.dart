import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/transaction_model_v2.dart';
import 'firebase_firestore_service.dart';

/// Firebase Transaction Service
/// Handles all transaction operations for the Qanta app
class FirebaseTransactionService {
  static const String _collectionName = 'transactions';

  /// Get real-time transaction updates stream
  static Stream<List<Map<String, dynamic>>> getTransactionStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(
        _collectionName,
      ).orderBy('transaction_date', descending: true),
    ).map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  /// Get all transactions for the current user
  static Future<List<TransactionWithDetailsV2>> getAllTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(
          _collectionName,
        ).orderBy('transaction_date', descending: true).limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Get transactions by type
  static Future<List<TransactionWithDetailsV2>> getTransactionsByType({
    required TransactionType type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('type', isEqualTo: type.value)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions by type: $e');
      rethrow;
    }
  }

  /// Get transactions for a specific account
  static Future<List<TransactionWithDetailsV2>> getTransactionsByAccount({
    required String accountId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('account_id', isEqualTo: accountId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions by account: $e');
      rethrow;
    }
  }

  /// Add new transaction
  static Future<String> addTransaction(
    TransactionWithDetailsV2 transaction,
  ) async {
    try {
      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: transaction.toJson(),
      );
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update transaction
  static Future<void> updateTransaction({
    required String transactionId,
    required TransactionWithDetailsV2 transaction,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: transactionId,
        data: transaction.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete transaction
  static Future<void> deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _collectionName,
        docId: transactionId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get transactions by date range
  static Future<List<TransactionWithDetailsV2>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where(
              'transaction_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'transaction_date',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions by date range: $e');
      rethrow;
    }
  }

  /// Get transactions by category
  static Future<List<TransactionWithDetailsV2>> getTransactionsByCategory({
    required String category,
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('category', isEqualTo: category)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions by category: $e');
      rethrow;
    }
  }

  /// Get monthly transaction summary
  static Future<Map<String, dynamic>> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final transactions = await getTransactionsByDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> categoryExpenses = {};
      Map<String, int> categoryCounts = {};

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpense += transaction.amount;
          final categoryKey = transaction.categoryName ?? 'Diğer';
          categoryExpenses[categoryKey] =
              (categoryExpenses[categoryKey] ?? 0) + transaction.amount;
          categoryCounts[categoryKey] = (categoryCounts[categoryKey] ?? 0) + 1;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
        'categoryExpenses': categoryExpenses,
        'categoryCounts': categoryCounts,
        'transactionCount': transactions.length,
      };
    } catch (e) {
      debugPrint('Error getting monthly summary: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/budget_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';

/// Unified Budget Service for Firebase operations
/// Handles all budget-related CRUD operations with real-time calculations
class UnifiedBudgetService {
  static const String _collectionName = 'budgets';

  /// Get all budgets for current user
  static Future<List<BudgetModel>> getAllBudgets() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final budgetData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };
        return BudgetModel.fromJson(budgetData);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      rethrow;
    }
  }

  /// Get budgets for specific month/year
  static Future<List<BudgetModel>> getBudgetsForMonth(
    int month,
    int year,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Get all budgets and filter in memory to avoid index issues
      final allBudgets = await getAllBudgets();

      return allBudgets
          .where((budget) => budget.month == month && budget.year == year)
          .toList();
    } catch (e) {
      debugPrint('Error fetching budgets for month: $e');
      rethrow;
    }
  }

  /// Get budget by ID
  static Future<BudgetModel?> getBudgetById(String budgetId) async {
    try {
      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _collectionName,
        docId: budgetId,
      );

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final budgetData = {...data, 'id': doc.id};
      return BudgetModel.fromJson(budgetData);
    } catch (e) {
      debugPrint('Error fetching budget: $e');
      rethrow;
    }
  }

  /// Add new budget
  static Future<String> addBudget(BudgetModel budget) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final budgetData = {
        ...budget.toJson(),
        'user_id': userId,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: budgetData,
      );

      final docId = docRef.id;
      return docId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update budget
  static Future<bool> updateBudget({
    required String budgetId,
    required BudgetModel budget,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final budgetData = {
        ...budget.toJson(),
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: budgetId,
        data: budgetData,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete budget (soft delete)
  static Future<bool> deleteBudget(String budgetId) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: budgetId,
        data: {'is_active': false, 'updated_at': FieldValue.serverTimestamp()},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculate spent amount for a budget from transactions
  static Future<double> calculateSpentAmount({
    required String categoryId,
    required int month,
    required int year,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Get start and end of month
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      // Get all transactions for user and filter in memory to avoid index issues
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: 'transactions',
        query: FirebaseFirestoreService.getCollection(
          'transactions',
        ).where('user_id', isEqualTo: userId),
      );

      double totalSpent = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Filter in memory
        final transactionCategoryId = data['category_id'] as String?;
        final transactionType = data['type'] as String?;
        final transactionDateField = data['transaction_date'];

        if (transactionCategoryId == categoryId &&
            transactionType == 'expense' &&
            transactionDateField != null) {
          DateTime? date;
          if (transactionDateField is Timestamp) {
            date = transactionDateField.toDate();
          } else if (transactionDateField is String) {
            date = DateTime.tryParse(transactionDateField);
          }

          if (date != null &&
              date.isAfter(startOfMonth) &&
              date.isBefore(endOfMonth)) {
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            totalSpent += amount;
          }
        }
      }

      return totalSpent;
    } catch (e) {
      debugPrint('Error calculating spent amount: $e');
      return 0.0;
    }
  }

  /// Update spent amounts for all budgets in a month
  static Future<void> updateSpentAmountsForMonth(int month, int year) async {
    try {
      // Get all budgets and filter in memory to avoid index issues
      final allBudgets = await getAllBudgets();
      final budgets = allBudgets
          .where((budget) => budget.month == month && budget.year == year)
          .toList();

      for (final budget in budgets) {
        final spentAmount = await calculateSpentAmount(
          categoryId: budget.categoryId,
          month: month,
          year: year,
        );

        if (spentAmount != budget.spentAmount) {
          final updatedBudget = budget.copyWith(spentAmount: spentAmount);
          await updateBudget(budgetId: budget.id, budget: updatedBudget);
        } else {}
      }
    } catch (e) {
      debugPrint('Error updating spent amounts: $e');
    }
  }

  /// Update budget category ID to match transaction category ID
  static Future<void> updateBudgetCategoryId(
    String oldCategoryId,
    String newCategoryId,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final budgets = await getAllBudgets();
      final budgetToUpdate = budgets.firstWhere(
        (budget) => budget.categoryId == oldCategoryId,
        orElse: () => throw Exception(
          'Budget not found with category ID: $oldCategoryId',
        ),
      );

      final updatedBudget = budgetToUpdate.copyWith(categoryId: newCategoryId);
      await updateBudget(budgetId: budgetToUpdate.id, budget: updatedBudget);
    } catch (e) {}
  }

  /// Get budget statistics for a month
  static Future<Map<String, dynamic>> getBudgetStatsForMonth(
    int month,
    int year,
  ) async {
    try {
      final budgets = await getBudgetsForMonth(month, year);

      double totalBudgetLimit = 0.0;
      double totalSpent = 0.0;
      int overBudgetCount = 0;
      int nearBudgetCount = 0; // 80% or more spent

      for (final budget in budgets) {
        totalBudgetLimit += budget.monthlyLimit;
        totalSpent += budget.spentAmount;

        if (budget.spentAmount > budget.monthlyLimit) {
          overBudgetCount++;
        } else if (budget.spentAmount >= budget.monthlyLimit * 0.8) {
          nearBudgetCount++;
        }
      }

      return {
        'totalBudgetLimit': totalBudgetLimit,
        'totalSpent': totalSpent,
        'remainingBudget': totalBudgetLimit - totalSpent,
        'overBudgetCount': overBudgetCount,
        'nearBudgetCount': nearBudgetCount,
        'budgetCount': budgets.length,
        'averageSpentPercentage': totalBudgetLimit > 0
            ? (totalSpent / totalBudgetLimit) * 100
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error calculating budget stats: $e');
      return {
        'totalBudgetLimit': 0.0,
        'totalSpent': 0.0,
        'remainingBudget': 0.0,
        'overBudgetCount': 0,
        'nearBudgetCount': 0,
        'budgetCount': 0,
        'averageSpentPercentage': 0.0,
      };
    }
  }
}

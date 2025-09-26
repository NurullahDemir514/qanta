import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/budget_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';

/// Firebase Budget Service V2
/// Handles all budget operations for the Qanta app
class FirebaseBudgetServiceV2 {
  static const String _collectionName = 'budgets';

  /// Get all budgets for current user
  static Future<List<BudgetModel>> getBudgets() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BudgetModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
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
      return BudgetModel.fromJson({
        'id': doc.id,
        ...data,
      });
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

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: {
          ...budget.toJson(),
          'user_id': userId,
        },
      );
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update budget
  static Future<void> updateBudget({
    required String budgetId,
    required BudgetModel budget,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: budgetId,
        data: budget.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete budget
  static Future<void> deleteBudget(String budgetId) async {
    try {
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _collectionName,
        docId: budgetId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get budget stream for real-time updates
  static Stream<List<BudgetModel>> getBudgetsStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('user_id', isEqualTo: FirebaseAuthService.currentUserId)
          .orderBy('created_at', descending: true),
    ).map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return BudgetModel.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList());
  }

  /// Get budgets for specific month and year
  static Future<List<BudgetModel>> getBudgetsForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('month', isEqualTo: month)
            .where('year', isEqualTo: year),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BudgetModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching budgets for month: $e');
      rethrow;
    }
  }

  /// Get budget by category
  static Future<BudgetModel?> getBudgetByCategory({
    required String category,
    required int year,
    required int month,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('category', isEqualTo: category)
            .where('month', isEqualTo: month)
            .where('year', isEqualTo: year)
            .limit(1),
      );

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return BudgetModel.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      debugPrint('Error fetching budget by category: $e');
      rethrow;
    }
  }

  /// Update budget spent amount
  static Future<void> updateBudgetSpent({
    required String budgetId,
    required double spentAmount,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: budgetId,
        data: {
          'spent_amount': spentAmount,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get budget summary for month
  static Future<Map<String, dynamic>> getBudgetSummary({
    required int year,
    required int month,
  }) async {
    try {
      final budgets = await getBudgetsForMonth(year: year, month: month);
      
      double totalBudget = 0;
      double totalSpent = 0;
      int budgetCount = budgets.length;
      int exceededBudgets = 0;

      for (final budget in budgets) {
        totalBudget += budget.amount;
        totalSpent += budget.spentAmount;
        if (budget.spentAmount > budget.amount) {
          exceededBudgets++;
        }
      }

      return {
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'remaining': totalBudget - totalSpent,
        'budgetCount': budgetCount,
        'exceededBudgets': exceededBudgets,
        'utilizationPercentage': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
      };
    } catch (e) {
      debugPrint('Error getting budget summary: $e');
      rethrow;
    }
  }

  /// Get budgets that are close to limit (over 80% spent)
  static Future<List<BudgetModel>> getBudgetsNearLimit() async {
    try {
      final budgets = await getBudgets();
      return budgets.where((budget) {
        if (budget.amount == 0) return false;
        final utilization = (budget.spentAmount / budget.amount) * 100;
        return utilization >= 80;
      }).toList();
    } catch (e) {
      debugPrint('Error getting budgets near limit: $e');
      return [];
    }
  }

  /// Get exceeded budgets
  static Future<List<BudgetModel>> getExceededBudgets() async {
    try {
      final budgets = await getBudgets();
      return budgets.where((budget) => budget.spentAmount > budget.amount).toList();
    } catch (e) {
      debugPrint('Error getting exceeded budgets: $e');
      return [];
    }
  }
}

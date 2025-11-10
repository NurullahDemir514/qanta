import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/recurring_transaction_model.dart';
import '../../modules/transactions/models/recurring_frequency.dart';
import '../services/recurring_transaction_service.dart';
import '../services/point_service.dart';
import '../services/country_detection_service.dart';
import '../../shared/models/point_activity_model.dart';
import '../../modules/profile/providers/point_provider.dart';

/// Recurring Transaction Provider - State management
class RecurringTransactionProvider extends ChangeNotifier {
  // Singleton pattern
  static final RecurringTransactionProvider _instance = RecurringTransactionProvider._internal();
  factory RecurringTransactionProvider() => _instance;
  static RecurringTransactionProvider get instance => _instance;

  RecurringTransactionProvider._internal();

  // State
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  List<RecurringTransaction> get activeSubscriptions => 
      _recurringTransactions.where((t) => t.isCurrentlyActive).toList();
  List<RecurringTransaction> get inactiveSubscriptions => 
      _recurringTransactions.where((t) => !t.isCurrentlyActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSubscriptions => _recurringTransactions.isNotEmpty;
  int get activeSubscriptionsCount => activeSubscriptions.length;

  /// Total monthly amount (normalized)
  double get totalMonthlyAmount => activeSubscriptions.fold<double>(
    0,
    (sum, transaction) => sum + transaction.monthlyAmount,
  );

  /// Total yearly amount (normalized)
  double get totalYearlyAmount => activeSubscriptions.fold<double>(
    0,
    (sum, transaction) => sum + transaction.yearlyAmount,
  );

  /// Load all recurring transactions
  Future<void> loadSubscriptions({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recurringTransactions = await RecurringTransactionService.getAllRecurringTransactions(
        includeInactive: true,
      );

      debugPrint('✅ Loaded ${_recurringTransactions.length} recurring transactions in provider');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading recurring transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new recurring transaction
  Future<String?> createSubscription(RecurringTransaction transaction) async {
    try {
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final transactionWithDates = transaction.copyWith(
        createdAt: now,
        updatedAt: now,
        nextExecutionDate: transaction.nextExecutionDate ?? 
            transaction.calculateNextExecutionDate(),
      );

      final id = await RecurringTransactionService.createRecurringTransaction(
        transactionWithDates,
      );

      // Reload subscriptions
      await loadSubscriptions(forceRefresh: true);

      // Check if this is the first subscription and award points
      await _awardFirstSubscriptionPoints();

      debugPrint('✅ Created subscription: ${transaction.name}');
      return id;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating subscription: $e');
      notifyListeners();
      return null;
    }
  }

  /// Update recurring transaction
  Future<bool> updateSubscription(
    String id,
    RecurringTransaction updatedTransaction,
  ) async {
    try {
      _error = null;
      notifyListeners();

      final transactionWithDates = updatedTransaction.copyWith(
        updatedAt: DateTime.now(),
        nextExecutionDate: updatedTransaction.nextExecutionDate ?? 
            updatedTransaction.calculateNextExecutionDate(),
      );

      final success = await RecurringTransactionService.updateRecurringTransaction(
        id,
        transactionWithDates,
      );

      if (success) {
        // Reload subscriptions
        await loadSubscriptions(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating subscription: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete recurring transaction
  Future<bool> deleteSubscription(String id) async {
    try {
      _error = null;
      notifyListeners();

      final success = await RecurringTransactionService.deleteRecurringTransaction(id);

      if (success) {
        // Reload subscriptions
        await loadSubscriptions(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting subscription: $e');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active status
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      _error = null;
      notifyListeners();

      final success = await RecurringTransactionService.toggleActiveStatus(id, isActive);

      if (success) {
        // Reload subscriptions
        await loadSubscriptions(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error toggling active status: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get subscription by ID
  RecurringTransaction? getSubscriptionById(String id) {
    try {
      return _recurringTransactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get subscriptions by category
  List<RecurringTransaction> getSubscriptionsByCategory(RecurringCategory category) {
    return _recurringTransactions.where(
      (t) => t.category == category && t.isCurrentlyActive,
    ).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Award points for first subscription - 250 points
  /// Only for Turkish users
  Future<void> _awardFirstSubscriptionPoints() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        debugPrint('⚠️ First subscription points: Points system is Turkey-only, user is not Turkish');
        return;
      }

      // Check if this is the first subscription
      // After reloadSubscriptions, check if total subscriptions = 1
      if (_recurringTransactions.length == 1) {
        // This is the first subscription - award 250 points
        final pointService = PointService();
        final pointsEarned = await pointService.earnPoints(
          userId,
          PointActivity.firstSubscription,
          description: 'İlk abonelik oluşturuldu',
        );

        if (pointsEarned > 0) {
          debugPrint('✅ First subscription points awarded: $pointsEarned');
          
          // Refresh PointProvider to update UI immediately
          try {
            final pointProvider = PointProvider();
            await pointProvider.refresh();
          } catch (e) {
            debugPrint('⚠️ RecurringTransactionProvider: Failed to refresh PointProvider: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error awarding first subscription points: $e');
      // Don't throw - this is a bonus feature, shouldn't break subscription creation
    }
  }

}


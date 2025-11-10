import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/point_activity_model.dart';
import '../../shared/models/point_transaction_model.dart';
import '../../shared/models/point_balance_model.dart';
import '../../shared/utils/date_utils.dart' as date_utils;
import 'premium_service.dart';
import 'country_detection_service.dart';
import 'remote_config_service.dart';

/// Point Service
/// Manages point earning and spending system
/// 
/// Point Values (Profit-Optimized):
/// - Rewarded Ad: 50 points (0.40 TL revenue → 0.20 TL cost → 50 points = 0.20 TL value)
/// - Transaction: 15 points (0.05 TL indirect revenue → 0.03 TL cost → 15 points = 0.03 TL value)
/// - Daily Login: 25 points (engagement bonus, no cost)
/// - Weekly Streak: 1000 points (7-day bonus, retention bonus, no cost)
/// - Monthly Goal: 50 points (engagement bonus, no cost)
  /// - Referral: 500 points (user acquisition, no cost)
/// 
/// Point Redemption (Amazon Gift Cards):
/// - 200 points = 1 TL Amazon gift card
/// - 20,000 points = 100 TL Amazon gift card
class PointService {
  static final PointService _instance = PointService._internal();
  factory PointService() => _instance;
  PointService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Daily limits (now from Remote Config, defaults for backward compatibility)
  static const int maxDailyAds = 10;
  static const int maxDailyTransactions = 20;
  static const int maxDailyLogin = 1;
  
  /// Get points for activity from Remote Config
  int _getPointsForActivity(PointActivity activity) {
    final remoteConfig = RemoteConfigService();
    switch (activity) {
      case PointActivity.rewardedAd:
        return remoteConfig.getPointRewardedAd();
      case PointActivity.transaction:
        return remoteConfig.getPointTransaction();
      case PointActivity.dailyLogin:
        return remoteConfig.getPointDailyLogin();
      case PointActivity.weeklyStreak:
        return remoteConfig.getPointWeeklyStreak();
      case PointActivity.monthlyGoal:
        return remoteConfig.getPointMonthlyGoal();
      case PointActivity.referral:
        return remoteConfig.getPointReferral();
      case PointActivity.budgetGoal:
        return remoteConfig.getPointBudgetGoal();
      case PointActivity.savingsMilestone:
        return remoteConfig.getPointSavingsMilestone();
      case PointActivity.premiumBonus:
        return remoteConfig.getPointPremiumBonus();
      case PointActivity.specialEvent:
        return remoteConfig.getPointSpecialEvent();
      case PointActivity.firstCard:
        return remoteConfig.getPointFirstCard();
      case PointActivity.firstBudget:
        return remoteConfig.getPointFirstBudget();
      case PointActivity.firstStockPurchase:
        return remoteConfig.getPointFirstStockPurchase();
      case PointActivity.firstSubscription:
        return remoteConfig.getPointFirstSubscription();
      case PointActivity.redemption:
        return 0;
    }
  }
  
  /// Get daily limit from Remote Config
  int _getDailyLimit(String limitType) {
    final remoteConfig = RemoteConfigService();
    switch (limitType) {
      case 'ads':
        return remoteConfig.getPointMaxDailyAds();
      case 'transactions':
        return remoteConfig.getPointMaxDailyTransactions();
      case 'login':
        return remoteConfig.getPointMaxDailyLogin();
      default:
        return 10; // Default fallback
    }
  }

  /// Earn points from rewarded ad
  /// Returns: points earned (0 if failed or limit reached)
  /// Note: Points system is Turkey-only
  Future<int> earnPointsFromAd(String userId) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('❌ PointService: userId is empty');
        return 0;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        if (kDebugMode) debugPrint('⚠️ PointService: Points system is Turkey-only, user is not Turkish');
        return 0;
      }
      
      // Check daily limit from Remote Config
      final today = DateTime.now();
      final dailyAdCount = await _getDailyAdCount(userId, today);
      final maxAds = _getDailyLimit('ads');
      if (dailyAdCount >= maxAds) {
        return 0;
      }

      // Get points for rewarded ad from Remote Config with premium multiplier
      final basePoints = _getPointsForActivity(PointActivity.rewardedAd);
      final points = _applyPremiumMultiplier(basePoints);
      final transactionId = _uuid.v4();
      final now = DateTime.now();

      final transaction = PointTransaction(
        id: transactionId,
        userId: userId,
        points: points,
        activity: PointActivity.rewardedAd,
        rewardedAdId: transactionId,
        earnedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save transaction
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('point_transactions')
            .doc(transactionId)
            .set(transaction.toFirestore());
      } catch (e) {
        if (kDebugMode) debugPrint('❌ PointService: Error saving transaction: $e');
        rethrow;
      }

      // Update balance
      try {
        await _updateBalanceAfterEarning(
          userId,
          points,
          PointActivity.rewardedAd,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('❌ PointService: Error updating balance: $e');
        rethrow;
      }

      return points;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error earning ad points: $e');
      return 0;
    }
  }

  /// Earn points from transaction
  /// Returns: points earned (0 if failed or limit reached)
  /// Note: Points system is Turkey-only
  Future<int> earnPointsFromTransaction(
    String userId,
    String transactionId,
  ) async {
    try {
      if (userId.isEmpty || transactionId.isEmpty) {
        if (kDebugMode) debugPrint('❌ PointService: userId or transactionId is empty');
        return 0;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        if (kDebugMode) debugPrint('⚠️ PointService: Points system is Turkey-only, user is not Turkish');
        return 0;
      }
      
      // Check if already earned for this transaction
      final existing = await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .where('transaction_id', isEqualTo: transactionId)
          .where('activity', isEqualTo: PointActivity.transaction.value)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return 0;
      }

      // Check daily limit from Remote Config
      final today = DateTime.now();
      final dailyTransactionCount = await _getDailyTransactionCount(
        userId,
        today,
      );
      final maxTransactions = _getDailyLimit('transactions');
      if (dailyTransactionCount >= maxTransactions) {
        return 0;
      }

      // Get points for transaction from Remote Config with premium multiplier
      final basePoints = _getPointsForActivity(PointActivity.transaction);
      final points = _applyPremiumMultiplier(basePoints);
      final pointTransactionId = _uuid.v4();
      final now = DateTime.now();

      final transaction = PointTransaction(
        id: pointTransactionId,
        userId: userId,
        points: points,
        activity: PointActivity.transaction,
        transactionId: transactionId,
        earnedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save transaction
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('point_transactions')
            .doc(pointTransactionId)
            .set(transaction.toFirestore());
      } catch (e) {
        if (kDebugMode) debugPrint('❌ PointService: Error saving transaction: $e');
        rethrow;
      }

      // Update balance
      try {
        await _updateBalanceAfterEarning(
          userId,
          points,
          PointActivity.transaction,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('❌ PointService: Error updating balance: $e');
        rethrow;
      }

      return points;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error earning transaction points: $e');
      return 0;
    }
  }

  /// Earn points from daily login
  /// Returns: points earned (0 if failed or limit reached)
  /// Note: Points system is Turkey-only
  Future<int> earnPointsFromDailyLogin(String userId) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('❌ PointService: userId is empty');
        return 0;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        if (kDebugMode) debugPrint('⚠️ PointService: Points system is Turkey-only, user is not Turkish');
        return 0;
      }

      final balance = await _getOrCreateBalance(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already logged in today
      if (balance.lastDailyLogin != null) {
        final lastLogin = DateTime(
          balance.lastDailyLogin!.year,
          balance.lastDailyLogin!.month,
          balance.lastDailyLogin!.day,
        );

        if (lastLogin.year == today.year &&
            lastLogin.month == today.month &&
            lastLogin.day == today.day) {
          return 0;
        }

        // Check if streak continues (yesterday)
        final yesterday = today.subtract(const Duration(days: 1));
        final isStreakContinuing = lastLogin.year == yesterday.year &&
            lastLogin.month == yesterday.month &&
            lastLogin.day == yesterday.day;

        // Update streak
        int newStreak = isStreakContinuing
            ? balance.weeklyStreakCount + 1
            : 1; // Reset if broken

        // Check for weekly streak bonus (7 days)
        int basePoints = _getPointsForActivity(PointActivity.dailyLogin);
        int weeklyBonus = 0;
        if (newStreak >= 7 && newStreak % 7 == 0) {
          // Weekly streak bonus from Remote Config
          weeklyBonus = _getPointsForActivity(PointActivity.weeklyStreak);
        }
        // Apply premium multiplier to both base points and weekly bonus
        int points = _applyPremiumMultiplier(basePoints) + _applyPremiumMultiplier(weeklyBonus);

        // Update longest streak
        final longestStreak = newStreak > balance.longestStreak
            ? newStreak
            : balance.longestStreak;

        final transactionId = _uuid.v4();
        final hasWeeklyBonus = newStreak >= 7 && newStreak % 7 == 0;
        final transaction = PointTransaction(
          id: transactionId,
          userId: userId,
          points: points,
          activity: PointActivity.dailyLogin,
          earnedAt: now,
          description: hasWeeklyBonus
              ? 'Günlük giriş + Haftalık seri bonusu'
              : 'Günlük giriş',
          createdAt: now,
          updatedAt: now,
        );

        // Save transaction
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('point_transactions')
            .doc(transactionId)
            .set(transaction.toFirestore());

        // Update balance with streak info
        await _updateBalanceAfterDailyLogin(
          userId,
          points,
          newStreak,
          longestStreak,
          now,
        );

        return points;
      } else {
        // First login ever
        final basePoints = _getPointsForActivity(PointActivity.dailyLogin);
        final points = _applyPremiumMultiplier(basePoints);
        final transactionId = _uuid.v4();
        final transaction = PointTransaction(
          id: transactionId,
          userId: userId,
          points: points,
          activity: PointActivity.dailyLogin,
          earnedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Save transaction
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('point_transactions')
            .doc(transactionId)
            .set(transaction.toFirestore());

        // Update balance
        await _updateBalanceAfterDailyLogin(
          userId,
          points,
          1, // First day
          1, // Longest streak
          now,
        );

        return points;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error earning daily login points: $e');
      return 0;
    }
  }

  /// Earn points (general method)
  /// Returns: points earned (0 if failed)
  /// Note: Points system is Turkey-only
  Future<int> earnPoints(
    String userId,
    PointActivity activity, {
    String? referenceId,
    String? description,
    int? customPoints,
  }) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('❌ PointService: userId is empty');
        return 0;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        if (kDebugMode) debugPrint('⚠️ PointService: Points system is Turkey-only, user is not Turkish');
        return 0;
      }

      final points = customPoints ?? _getPointsForActivity(activity);
      final transactionId = _uuid.v4();
      final now = DateTime.now();

      final transaction = PointTransaction(
        id: transactionId,
        userId: userId,
        points: points,
        activity: activity,
        referenceId: referenceId,
        description: description,
        earnedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .doc(transactionId)
          .set(transaction.toFirestore());

      // Update balance
      await _updateBalanceAfterEarning(userId, points, activity);

      return points;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error earning points: $e');
      return 0;
    }
  }

  /// Spend points (redemption)
  /// Returns: true if successful
  /// Note: Points system is Turkey-only
  Future<bool> spendPoints(
    String userId,
    int points,
    String description,
  ) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('❌ PointService: userId is empty');
        return false;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        if (kDebugMode) debugPrint('⚠️ PointService: Points system is Turkey-only, user is not Turkish');
        return false;
      }

      final balance = await _getOrCreateBalance(userId);

      if (balance.totalPoints < points) {
        return false;
      }

      final transactionId = _uuid.v4();
      final now = DateTime.now();

      final transaction = PointTransaction(
        id: transactionId,
        userId: userId,
        points: -points, // Negative for spending
        activity: PointActivity.redemption,
        description: description,
        earnedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .doc(transactionId)
          .set(transaction.toFirestore());

      // Update balance
      await _updateBalanceAfterSpending(userId, points);

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error spending points: $e');
      return false;
    }
  }

  /// Get current point balance
  Future<int> getCurrentBalance(String userId) async {
    try {
      final balance = await _getOrCreateBalance(userId);
      return balance.totalPoints;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error getting balance: $e');
      return 0;
    }
  }

  /// Get point balance with statistics
  Future<PointBalance?> getBalance(String userId) async {
    try {
      return await _getOrCreateBalance(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error getting balance: $e');
      return null;
    }
  }

  /// Get or create balance document
  Future<PointBalance> _getOrCreateBalance(String userId) async {
    try {
      final balanceDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_balance')
          .doc('balance')
          .get();

      if (balanceDoc.exists) {
        return PointBalance.fromFirestore(balanceDoc);
      }

      // Create new balance
      final now = DateTime.now();
      final newBalance = PointBalance(
        userId: userId,
        totalPoints: 0,
        totalEarned: 0,
        totalSpent: 0,
        rewardedAdCount: 0,
        transactionCount: 0,
        dailyLoginCount: 0,
        weeklyStreakCount: 0,
        longestStreak: 0,
        lastEarnedAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_balance')
          .doc('balance')
          .set(newBalance.toFirestore());

      return newBalance;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error getting balance: $e');
      rethrow;
    }
  }

  /// Update balance after earning points
  Future<void> _updateBalanceAfterEarning(
    String userId,
    int points,
    PointActivity activity,
  ) async {
    try {
      final balance = await _getOrCreateBalance(userId);
      final now = DateTime.now();

      final updatedBalance = balance.copyWith(
        totalPoints: balance.totalPoints + points,
        totalEarned: balance.totalEarned + points,
        rewardedAdCount: activity == PointActivity.rewardedAd
            ? balance.rewardedAdCount + 1
            : balance.rewardedAdCount,
        transactionCount: activity == PointActivity.transaction
            ? balance.transactionCount + 1
            : balance.transactionCount,
        lastEarnedAt: now,
        updatedAt: now,
      );

      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('point_balance')
            .doc('balance')
            .update(updatedBalance.toFirestore());
      } catch (e) {
        if (kDebugMode) debugPrint('❌ PointService: Error updating balance document: $e');
        // If update fails, try to set (create if doesn't exist)
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('point_balance')
              .doc('balance')
              .set(updatedBalance.toFirestore(), SetOptions(merge: true));
        } catch (e2) {
          if (kDebugMode) debugPrint('❌ PointService: Error setting balance document: $e2');
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error updating balance after earning: $e');
      rethrow;
    }
  }

  /// Update balance after daily login
  Future<void> _updateBalanceAfterDailyLogin(
    String userId,
    int points,
    int newStreak,
    int longestStreak,
    DateTime loginDate,
  ) async {
    try {
      final balance = await _getOrCreateBalance(userId);
      final now = DateTime.now();

      final updatedBalance = balance.copyWith(
        totalPoints: balance.totalPoints + points,
        totalEarned: balance.totalEarned + points,
        dailyLoginCount: balance.dailyLoginCount + 1,
        weeklyStreakCount: newStreak,
        longestStreak: longestStreak,
        lastDailyLogin: loginDate,
        lastEarnedAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_balance')
          .doc('balance')
          .update(updatedBalance.toFirestore());
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error updating balance after daily login: $e');
    }
  }

  /// Update balance after spending points
  Future<void> _updateBalanceAfterSpending(
    String userId,
    int points,
  ) async {
    try {
      final balance = await _getOrCreateBalance(userId);
      final now = DateTime.now();

      final updatedBalance = balance.copyWith(
        totalPoints: balance.totalPoints - points,
        totalSpent: balance.totalSpent + points,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_balance')
          .doc('balance')
          .update(updatedBalance.toFirestore());
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error updating balance after spending: $e');
    }
  }

  /// Get daily ad count for today
  Future<int> _getDailyAdCount(String userId, DateTime today) async {
    try {
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final transactions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .where('activity', isEqualTo: PointActivity.rewardedAd.value)
          .where('earned_at',
              isGreaterThanOrEqualTo: date_utils.DateUtils.toFirebase(startOfDay))
          .where('earned_at',
              isLessThan: date_utils.DateUtils.toFirebase(endOfDay))
          .get();

      return transactions.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error getting daily ad count: $e');
      return 0;
    }
  }

  /// Get daily transaction count for today
  Future<int> _getDailyTransactionCount(String userId, DateTime today) async {
    try {
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final transactions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .where('activity', isEqualTo: PointActivity.transaction.value)
          .where('earned_at',
              isGreaterThanOrEqualTo: date_utils.DateUtils.toFirebase(startOfDay))
          .where('earned_at',
              isLessThan: date_utils.DateUtils.toFirebase(endOfDay))
          .get();

      return transactions.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error getting daily transaction count: $e');
      return 0;
    }
  }

  /// Apply premium multiplier to points
  /// Premium: 1.5x, Premium Plus: 2x
  int _applyPremiumMultiplier(int basePoints) {
    try {
      final premiumService = PremiumService();
      if (premiumService.isPremiumPlus) {
        // Premium Plus: 2x multiplier
        return (basePoints * 2).round();
      } else if (premiumService.isPremium) {
        // Premium: 1.5x multiplier
        return (basePoints * 1.5).round();
      }
      // Free users: no multiplier
      return basePoints;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PointService: Error applying premium multiplier: $e');
      return basePoints;
    }
  }
}


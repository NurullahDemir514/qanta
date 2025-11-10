import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/amazon_reward_credit_model.dart';
import '../../shared/models/amazon_reward_stats_model.dart';
import '../../shared/utils/date_utils.dart' as date_utils;
import 'country_detection_service.dart';
import 'remote_config_service.dart';

/// Amazon Reward Service
/// Manages Amazon gift card reward credits for Turkish users
/// 
/// Features:
/// - Earn credits from rewarded ads (0.20 TL)
/// - Earn credits from transactions (0.03 TL)
/// - Track balance and statistics
/// - Check threshold and convert to gift card
class AmazonRewardService {
  static final AmazonRewardService _instance = AmazonRewardService._internal();
  factory AmazonRewardService() => _instance;
  AmazonRewardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Earn reward from rewarded ad
  /// Returns: true if credit was added successfully
  Future<bool> earnRewardFromAd(String userId) async {
    try {
      // Check if user is eligible (Turkish Play Store user)
      final isEligible = await CountryDetectionService()
          .shouldShowAmazonRewards();
      if (!isEligible) {
        debugPrint(
          '⚠️ AmazonRewardService: User not eligible for Amazon rewards',
        );
        return false;
      }

      // Check daily limit (max 10 ads/day)
      final stats = await _getOrCreateStats(userId);
      final today = DateTime.now();
      final lastEarned = stats.lastEarnedAt;

      // Reset daily count if new day
      if (lastEarned.year != today.year ||
          lastEarned.month != today.month ||
          lastEarned.day != today.day) {
        // New day, reset daily count
        await _resetDailyCount(userId);
      }

      // Get daily limit from Remote Config
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      final maxDailyAds = remoteConfig.getAmazonRewardMaxDailyAds();
      
      // Check daily limit
      final dailyAdCount = await _getDailyAdCount(userId, today);
      if (dailyAdCount >= maxDailyAds) {
        debugPrint(
          '⚠️ AmazonRewardService: Daily ad limit reached ($maxDailyAds ads/day)',
        );
        return false;
      }

      // Get reward amount from Remote Config
      final rewardAmount = remoteConfig.getAmazonRewardRewardedAdAmount();
      final creditId = _uuid.v4();
      final now = DateTime.now();

      final credit = AmazonRewardCredit(
        id: creditId,
        userId: userId,
        amount: rewardAmount,
        source: RewardSource.rewardedAd,
        rewardedAdId: creditId, // Use credit ID as ad ID
        earnedAt: now,
        status: RewardStatus.accumulated,
        createdAt: now,
        updatedAt: now,
      );

      // Save credit to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .doc(creditId)
          .set(credit.toFirestore());

      // Update stats
      await _updateStatsAfterEarning(
        userId,
        rewardAmount,
        RewardSource.rewardedAd,
      );

      // Note: Gift card conversion is now manual - user must request it
      // We don't auto-convert anymore

      debugPrint(
        '✅ AmazonRewardService: Added ${rewardAmount} TL credit from ad',
      );
      return true;
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error earning ad reward: $e');
      return false;
    }
  }

  /// Earn reward from transaction
  /// Returns: true if credit was added successfully
  Future<bool> earnRewardFromTransaction(
    String userId,
    String transactionId,
  ) async {
    try {
      // Check if user is eligible
      final isEligible = await CountryDetectionService()
          .shouldShowAmazonRewards();
      if (!isEligible) {
        debugPrint(
          '⚠️ AmazonRewardService: User not eligible for Amazon rewards',
        );
        return false;
      }

      // Check if already earned for this transaction
      final existingCredit = await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .where('transaction_id', isEqualTo: transactionId)
          .where('source', isEqualTo: RewardSource.transaction.value)
          .limit(1)
          .get();

      if (existingCredit.docs.isNotEmpty) {
        debugPrint(
          '⚠️ AmazonRewardService: Already earned credit for transaction $transactionId',
        );
        return false;
      }

      // Get daily limit from Remote Config
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      final maxDailyTransactions = remoteConfig.getAmazonRewardMaxDailyTransactions();
      
      // Check daily limit
      final today = DateTime.now();
      final dailyTransactionCount = await _getDailyTransactionCount(
        userId,
        today,
      );
      if (dailyTransactionCount >= maxDailyTransactions) {
        debugPrint(
          '⚠️ AmazonRewardService: Daily transaction limit reached ($maxDailyTransactions/day)',
        );
        return false;
      }

      // Get reward amount from Remote Config
      final rewardAmount = remoteConfig.getAmazonRewardTransactionAmount();
      final creditId = _uuid.v4();
      final now = DateTime.now();

      final credit = AmazonRewardCredit(
        id: creditId,
        userId: userId,
        amount: rewardAmount,
        source: RewardSource.transaction,
        transactionId: transactionId,
        earnedAt: now,
        status: RewardStatus.accumulated,
        createdAt: now,
        updatedAt: now,
      );

      // Save credit to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .doc(creditId)
          .set(credit.toFirestore());

      // Update stats
      await _updateStatsAfterEarning(
        userId,
        rewardAmount,
        RewardSource.transaction,
      );

      // Note: Gift card conversion is now manual - user must request it
      // We don't auto-convert anymore

      debugPrint(
        '✅ AmazonRewardService: Added ${rewardAmount} TL credit from transaction',
      );
      return true;
    } catch (e) {
      debugPrint(
        '❌ AmazonRewardService: Error earning transaction reward: $e',
      );
      return false;
    }
  }

  /// Get current balance
  Future<double> getCurrentBalance(String userId) async {
    try {
      final stats = await _getOrCreateStats(userId);
      return stats.currentBalance;
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error getting balance: $e');
      return 0.0;
    }
  }

  /// Get reward statistics
  Future<AmazonRewardStats?> getRewardStats(String userId) async {
    try {
      return await _getOrCreateStats(userId);
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error getting stats: $e');
      return null;
    }
  }

  /// Request gift card conversion for a specific amount
  /// Amount must be at least 50 TL and a multiple of 50
  /// Returns: true if conversion was successful
  Future<bool> requestGiftCard(
    String userId,
    String amazonEmail,
    double amount,
  ) async {
    try {
      final stats = await _getOrCreateStats(userId);
      
      // Get threshold and gift card amount from Remote Config
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      final minimumThreshold = remoteConfig.getAmazonRewardMinimumThreshold();
      final giftCardAmount = remoteConfig.getAmazonRewardGiftCardAmount();
      
      // Validate amount
      if (amount < minimumThreshold) {
        debugPrint(
          '⚠️ AmazonRewardService: Amount $amount TL is below minimum ($minimumThreshold TL)',
        );
        return false;
      }
      
      if (amount % giftCardAmount != 0) {
        debugPrint(
          '⚠️ AmazonRewardService: Amount $amount TL must be a multiple of $giftCardAmount',
        );
        return false;
      }
      
      if (stats.currentBalance < amount) {
        debugPrint(
          '⚠️ AmazonRewardService: Balance ${stats.currentBalance} TL is less than requested amount $amount TL',
        );
        return false;
      }

      debugPrint(
        '✅ AmazonRewardService: Requesting gift card conversion for $amount TL...',
      );
      
      // Call Cloud Function to convert with email and specific amount
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('checkAndConvertToGiftCard');
        
        final result = await callable.call({
          'userId': userId,
          'amazonEmail': amazonEmail,
          'amount': amount,
        });
        final data = Map<String, dynamic>.from(result.data);
        
        if (data['success'] == true) {
          debugPrint(
            '✅ AmazonRewardService: Gift card request successful! '
            'Created ${data['giftCardsCreated']} request(s), '
            'Remaining balance: ${data['remainingBalance']} TL',
          );
          return true;
        } else {
          debugPrint(
            '⚠️ AmazonRewardService: Request failed: ${data['message']}',
          );
          return false;
        }
      } catch (e) {
        debugPrint(
          '❌ AmazonRewardService: Cloud Function error: $e',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error requesting gift card: $e');
      return false;
    }
  }

  /// Create gift card request directly without balance check
  /// This is used when points have already been spent
  /// Returns: true if request was created successfully
  Future<bool> createGiftCardRequestDirectly(
    String userId,
    String amazonEmail,
    double amount,
    int pointsSpent, {
    String? provider,
    String? phoneNumber,
  }) async {
    try {
      // Get threshold and gift card amount from Remote Config
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      final minimumThreshold = remoteConfig.getAmazonRewardMinimumThreshold();
      final giftCardAmount = remoteConfig.getAmazonRewardGiftCardAmount();
      
      // Validate amount
      if (amount < minimumThreshold) {
        debugPrint(
          '⚠️ AmazonRewardService: Amount $amount TL is below minimum ($minimumThreshold TL)',
        );
        return false;
      }
      
      if (amount % giftCardAmount != 0) {
        debugPrint(
          '⚠️ AmazonRewardService: Amount $amount TL must be a multiple of $giftCardAmount',
        );
        return false;
      }

      // Ensure provider is always sent (default to 'amazon' if not provided)
      final providerToSend = (provider != null && provider.isNotEmpty) ? provider! : 'amazon';
      
      debugPrint(
        '✅ AmazonRewardService: Creating gift card request directly for $amount TL (${pointsSpent} points spent)...',
      );
      debugPrint(
        '📦 Provider info: provided=$provider, sending=$providerToSend',
      );
      
      // Call Cloud Function with skipBalanceCheck flag
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('createGiftCardRequestFromPoints');
        
        final result = await callable.call({
          'userId': userId,
          'amazonEmail': amazonEmail,
          'amount': amount,
          'pointsSpent': pointsSpent,
          'provider': providerToSend, // Always send provider (never null/empty)
          'phoneNumber': phoneNumber ?? '',
        });
        final data = Map<String, dynamic>.from(result.data);
        
        if (data['success'] == true) {
          debugPrint(
            '✅ AmazonRewardService: Gift card request created successfully! '
            'Created ${data['giftCardsCreated']} request(s)',
          );
          return true;
        } else {
          debugPrint(
            '⚠️ AmazonRewardService: Request failed: ${data['message']}',
          );
          return false;
        }
      } catch (e) {
        debugPrint(
          '❌ AmazonRewardService: Cloud Function error: $e',
        );
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ AmazonRewardService: Error requesting gift card: $e',
      );
      return false;
    }
  }

  /// Check if threshold reached (for UI to show button)
  /// This method doesn't trigger conversion, just checks balance
  Future<bool> canRequestGiftCard(String userId) async {
    try {
      final stats = await _getOrCreateStats(userId);
      
      // Get threshold from Remote Config
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      final minimumThreshold = remoteConfig.getAmazonRewardMinimumThreshold();
      
      return stats.currentBalance >= minimumThreshold;
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error checking threshold: $e');
      return false;
    }
  }

  /// Check if threshold reached and convert to gift card
  /// Calls Cloud Function to handle conversion automatically
  /// DEPRECATED: Use requestGiftCard() instead
  @Deprecated('Use requestGiftCard() with email parameter')
  Future<void> _checkAndConvertToGiftCard(String userId) async {
    // This method is kept for backward compatibility but should not be called
    // The new flow requires email input from user
  }

  /// Get or create stats document
  Future<AmazonRewardStats> _getOrCreateStats(String userId) async {
    try {
      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_stats')
          .doc('stats')
          .get();

      if (statsDoc.exists) {
        return AmazonRewardStats.fromFirestore(statsDoc);
      }

      // Create new stats
      final now = DateTime.now();
      final newStats = AmazonRewardStats(
        userId: userId,
        totalEarned: 0.0,
        currentBalance: 0.0,
        totalConverted: 0.0,
        totalGiftCards: 0,
        rewardedAdCount: 0,
        transactionCount: 0,
        lastEarnedAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_stats')
          .doc('stats')
          .set(newStats.toFirestore());

      return newStats;
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error getting stats: $e');
      rethrow;
    }
  }

  /// Update stats after earning credit
  Future<void> _updateStatsAfterEarning(
    String userId,
    double amount,
    RewardSource source,
  ) async {
    try {
      final stats = await _getOrCreateStats(userId);
      final now = DateTime.now();

      final updatedStats = stats.copyWith(
        totalEarned: stats.totalEarned + amount,
        currentBalance: stats.currentBalance + amount,
        rewardedAdCount: source == RewardSource.rewardedAd
            ? stats.rewardedAdCount + 1
            : stats.rewardedAdCount,
        transactionCount: source == RewardSource.transaction
            ? stats.transactionCount + 1
            : stats.transactionCount,
        lastEarnedAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_stats')
          .doc('stats')
          .update(updatedStats.toFirestore());
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error updating stats: $e');
    }
  }

  /// Get daily ad count for today
  Future<int> _getDailyAdCount(String userId, DateTime today) async {
    try {
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final credits = await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .where('source', isEqualTo: RewardSource.rewardedAd.value)
          .where('earned_at',
              isGreaterThanOrEqualTo: date_utils.DateUtils.toFirebase(startOfDay))
          .where('earned_at',
              isLessThan: date_utils.DateUtils.toFirebase(endOfDay))
          .get();

      return credits.docs.length;
    } catch (e) {
      debugPrint('❌ AmazonRewardService: Error getting daily ad count: $e');
      return 0;
    }
  }

  /// Get daily transaction count for today
  Future<int> _getDailyTransactionCount(String userId, DateTime today) async {
    try {
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final credits = await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .where('source', isEqualTo: RewardSource.transaction.value)
          .where('earned_at',
              isGreaterThanOrEqualTo: date_utils.DateUtils.toFirebase(startOfDay))
          .where('earned_at',
              isLessThan: date_utils.DateUtils.toFirebase(endOfDay))
          .get();

      return credits.docs.length;
    } catch (e) {
      debugPrint(
        '❌ AmazonRewardService: Error getting daily transaction count: $e',
      );
      return 0;
    }
  }

  /// Reset daily count (called when new day starts)
  Future<void> _resetDailyCount(String userId) async {
    // This is handled by checking date in _getDailyAdCount and _getDailyTransactionCount
    // No need to reset explicitly
  }
}


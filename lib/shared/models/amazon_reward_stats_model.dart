import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart' as date_utils;

/// Amazon reward statistics model
/// Tracks user's reward earning and conversion statistics
class AmazonRewardStats {
  final String userId;
  final double totalEarned; // Total credits earned
  final double currentBalance; // Current accumulated (not yet converted)
  final double totalConverted; // Total converted to gift cards
  final int totalGiftCards; // Number of gift cards received
  final int rewardedAdCount; // Number of ads watched
  final int transactionCount; // Number of transactions rewarded
  final DateTime lastEarnedAt;
  final DateTime? lastConvertedAt;
  final DateTime updatedAt;

  const AmazonRewardStats({
    required this.userId,
    required this.totalEarned,
    required this.currentBalance,
    required this.totalConverted,
    required this.totalGiftCards,
    required this.rewardedAdCount,
    required this.transactionCount,
    required this.lastEarnedAt,
    this.lastConvertedAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory AmazonRewardStats.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AmazonRewardStats(
      userId: data['user_id'] as String,
      totalEarned: (data['total_earned'] as num).toDouble(),
      currentBalance: (data['current_balance'] as num).toDouble(),
      totalConverted: (data['total_converted'] as num).toDouble(),
      totalGiftCards: data['total_gift_cards'] as int,
      rewardedAdCount: data['rewarded_ad_count'] as int,
      transactionCount: data['transaction_count'] as int,
      lastEarnedAt: date_utils.DateUtils.fromFirebase(data['last_earned_at']),
      lastConvertedAt: data['last_converted_at'] != null
          ? date_utils.DateUtils.fromFirebase(data['last_converted_at'])
          : null,
      updatedAt: date_utils.DateUtils.fromFirebase(data['updated_at']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'total_earned': totalEarned,
      'current_balance': currentBalance,
      'total_converted': totalConverted,
      'total_gift_cards': totalGiftCards,
      'rewarded_ad_count': rewardedAdCount,
      'transaction_count': transactionCount,
      'last_earned_at': date_utils.DateUtils.toFirebase(lastEarnedAt),
      'last_converted_at': lastConvertedAt != null
          ? date_utils.DateUtils.toFirebase(lastConvertedAt!)
          : null,
      'updated_at': date_utils.DateUtils.toFirebase(updatedAt),
    };
  }

  /// Create copy with updated fields
  AmazonRewardStats copyWith({
    String? userId,
    double? totalEarned,
    double? currentBalance,
    double? totalConverted,
    int? totalGiftCards,
    int? rewardedAdCount,
    int? transactionCount,
    DateTime? lastEarnedAt,
    DateTime? lastConvertedAt,
    DateTime? updatedAt,
  }) {
    return AmazonRewardStats(
      userId: userId ?? this.userId,
      totalEarned: totalEarned ?? this.totalEarned,
      currentBalance: currentBalance ?? this.currentBalance,
      totalConverted: totalConverted ?? this.totalConverted,
      totalGiftCards: totalGiftCards ?? this.totalGiftCards,
      rewardedAdCount: rewardedAdCount ?? this.rewardedAdCount,
      transactionCount: transactionCount ?? this.transactionCount,
      lastEarnedAt: lastEarnedAt ?? this.lastEarnedAt,
      lastConvertedAt: lastConvertedAt ?? this.lastConvertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Progress to next gift card (calculated in provider with Remote Config threshold)
  /// @deprecated Use provider's progressToNextGiftCard getter instead
  @Deprecated('Use provider getter with Remote Config threshold')
  double get progressToNextGiftCard {
    // Default to 100.0 for backward compatibility, but provider will use Remote Config
    if (currentBalance >= 100.0) return 1.0;
    return currentBalance / 100.0;
  }

  /// Remaining amount to next gift card (calculated in provider with Remote Config threshold)
  /// @deprecated Use provider's remainingToNextGiftCard getter instead
  @Deprecated('Use provider getter with Remote Config threshold')
  double get remainingToNextGiftCard {
    // Default to 100.0 for backward compatibility, but provider will use Remote Config
    if (currentBalance >= 100.0) return 0.0;
    return 100.0 - currentBalance;
  }

  @override
  String toString() {
    return 'AmazonRewardStats(userId: $userId, balance: $currentBalance, totalEarned: $totalEarned)';
  }
}


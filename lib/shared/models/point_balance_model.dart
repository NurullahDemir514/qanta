import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart' as date_utils;

/// Point balance model
/// Represents user's point balance and statistics
class PointBalance {
  final String userId;
  final int totalPoints; // Current available points
  final int totalEarned; // Total points ever earned
  final int totalSpent; // Total points ever spent
  final int rewardedAdCount; // Number of rewarded ads watched
  final int transactionCount; // Number of transactions that earned points
  final int dailyLoginCount; // Number of daily logins
  final int weeklyStreakCount; // Current weekly streak
  final int longestStreak; // Longest streak ever
  final DateTime? lastDailyLogin; // Last daily login date
  final DateTime lastEarnedAt; // Last time points were earned
  final DateTime updatedAt; // Last update time

  const PointBalance({
    required this.userId,
    required this.totalPoints,
    required this.totalEarned,
    required this.totalSpent,
    required this.rewardedAdCount,
    required this.transactionCount,
    required this.dailyLoginCount,
    required this.weeklyStreakCount,
    required this.longestStreak,
    this.lastDailyLogin,
    required this.lastEarnedAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory PointBalance.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PointBalance(
      userId: data['user_id'] as String,
      totalPoints: data['total_points'] as int? ?? 0,
      totalEarned: data['total_earned'] as int? ?? 0,
      totalSpent: data['total_spent'] as int? ?? 0,
      rewardedAdCount: data['rewarded_ad_count'] as int? ?? 0,
      transactionCount: data['transaction_count'] as int? ?? 0,
      dailyLoginCount: data['daily_login_count'] as int? ?? 0,
      weeklyStreakCount: data['weekly_streak_count'] as int? ?? 0,
      longestStreak: data['longest_streak'] as int? ?? 0,
      lastDailyLogin: data['last_daily_login'] != null
          ? date_utils.DateUtils.fromFirebase(data['last_daily_login'])
          : null,
      lastEarnedAt: date_utils.DateUtils.fromFirebase(data['last_earned_at']),
      updatedAt: date_utils.DateUtils.fromFirebase(data['updated_at']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'rewarded_ad_count': rewardedAdCount,
      'transaction_count': transactionCount,
      'daily_login_count': dailyLoginCount,
      'weekly_streak_count': weeklyStreakCount,
      'longest_streak': longestStreak,
      'last_daily_login': lastDailyLogin != null
          ? date_utils.DateUtils.toFirebase(lastDailyLogin!)
          : null,
      'last_earned_at': date_utils.DateUtils.toFirebase(lastEarnedAt),
      'updated_at': date_utils.DateUtils.toFirebase(updatedAt),
    };
  }

  /// Create copy with updated fields
  PointBalance copyWith({
    String? userId,
    int? totalPoints,
    int? totalEarned,
    int? totalSpent,
    int? rewardedAdCount,
    int? transactionCount,
    int? dailyLoginCount,
    int? weeklyStreakCount,
    int? longestStreak,
    DateTime? lastDailyLogin,
    DateTime? lastEarnedAt,
    DateTime? updatedAt,
  }) {
    return PointBalance(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      rewardedAdCount: rewardedAdCount ?? this.rewardedAdCount,
      transactionCount: transactionCount ?? this.transactionCount,
      dailyLoginCount: dailyLoginCount ?? this.dailyLoginCount,
      weeklyStreakCount: weeklyStreakCount ?? this.weeklyStreakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      lastDailyLogin: lastDailyLogin ?? this.lastDailyLogin,
      lastEarnedAt: lastEarnedAt ?? this.lastEarnedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert points to TL value for Amazon gift cards (200 points = 1 TL)
  /// Note: This is for Amazon gift card redemption only
  double get pointsToTL => totalPoints / 200.0;

  /// Check if user can redeem points for Amazon gift card (minimum 20,000 points = 100 TL)
  bool get canRedeem => totalPoints >= 20000;

  @override
  String toString() {
    return 'PointBalance(userId: $userId, totalPoints: $totalPoints, totalEarned: $totalEarned)';
  }
}


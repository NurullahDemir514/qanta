import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart' as date_utils;
import 'point_activity_model.dart';

/// Point transaction model
/// Represents a single point earning or spending transaction
class PointTransaction {
  final String id;
  final String userId;
  final int points; // Positive for earning, negative for spending
  final PointActivity activity;
  final String? transactionId; // If from transaction
  final String? rewardedAdId; // If from ad
  final String? referenceId; // Generic reference (goal ID, referral ID, etc.)
  final DateTime earnedAt;
  final String? description; // Optional description
  final DateTime createdAt;
  final DateTime updatedAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.activity,
    this.transactionId,
    this.rewardedAdId,
    this.referenceId,
    required this.earnedAt,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory PointTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PointTransaction(
      id: doc.id,
      userId: data['user_id'] as String,
      points: data['points'] as int,
      activity: PointActivity.fromString(data['activity'] as String),
      transactionId: data['transaction_id'] as String?,
      rewardedAdId: data['rewarded_ad_id'] as String?,
      referenceId: data['reference_id'] as String?,
      earnedAt: date_utils.DateUtils.fromFirebase(data['earned_at']),
      description: data['description'] as String?,
      createdAt: date_utils.DateUtils.fromFirebase(data['created_at']),
      updatedAt: date_utils.DateUtils.fromFirebase(data['updated_at']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'points': points,
      'activity': activity.value,
      'transaction_id': transactionId,
      'rewarded_ad_id': rewardedAdId,
      'reference_id': referenceId,
      'earned_at': date_utils.DateUtils.toFirebase(earnedAt),
      'description': description,
      'created_at': date_utils.DateUtils.toFirebase(createdAt),
      'updated_at': date_utils.DateUtils.toFirebase(updatedAt),
    };
  }

  /// Create copy with updated fields
  PointTransaction copyWith({
    String? id,
    String? userId,
    int? points,
    PointActivity? activity,
    String? transactionId,
    String? rewardedAdId,
    String? referenceId,
    DateTime? earnedAt,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PointTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      activity: activity ?? this.activity,
      transactionId: transactionId ?? this.transactionId,
      rewardedAdId: rewardedAdId ?? this.rewardedAdId,
      referenceId: referenceId ?? this.referenceId,
      earnedAt: earnedAt ?? this.earnedAt,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this is an earning transaction
  bool get isEarning => points > 0;

  /// Check if this is a spending transaction
  bool get isSpending => points < 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PointTransaction(id: $id, points: $points, activity: ${activity.value})';
  }
}


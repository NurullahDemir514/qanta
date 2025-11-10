import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart' as date_utils;

/// Amazon reward credit model
/// Represents a single credit earned by user (from ad or transaction)
class AmazonRewardCredit {
  final String id;
  final String userId;
  final double amount; // 0.20 (ad) or 0.03 (transaction)
  final RewardSource source; // rewardedAd or transaction
  final String? transactionId; // If from transaction
  final String? rewardedAdId; // If from ad
  final DateTime earnedAt;
  final RewardStatus status; // pending, accumulated, converted
  final String? giftCardId; // When converted to gift card
  final DateTime createdAt;
  final DateTime updatedAt;

  const AmazonRewardCredit({
    required this.id,
    required this.userId,
    required this.amount,
    required this.source,
    this.transactionId,
    this.rewardedAdId,
    required this.earnedAt,
    required this.status,
    this.giftCardId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory AmazonRewardCredit.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AmazonRewardCredit(
      id: doc.id,
      userId: data['user_id'] as String,
      amount: (data['amount'] as num).toDouble(),
      source: RewardSource.fromString(data['source'] as String),
      transactionId: data['transaction_id'] as String?,
      rewardedAdId: data['rewarded_ad_id'] as String?,
      earnedAt: date_utils.DateUtils.fromFirebase(data['earned_at']),
      status: RewardStatus.fromString(data['status'] as String),
      giftCardId: data['gift_card_id'] as String?,
      createdAt: date_utils.DateUtils.fromFirebase(data['created_at']),
      updatedAt: date_utils.DateUtils.fromFirebase(data['updated_at']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'amount': amount,
      'source': source.value,
      'transaction_id': transactionId,
      'rewarded_ad_id': rewardedAdId,
      'earned_at': date_utils.DateUtils.toFirebase(earnedAt),
      'status': status.value,
      'gift_card_id': giftCardId,
      'created_at': date_utils.DateUtils.toFirebase(createdAt),
      'updated_at': date_utils.DateUtils.toFirebase(updatedAt),
    };
  }

  /// Create copy with updated fields
  AmazonRewardCredit copyWith({
    String? id,
    String? userId,
    double? amount,
    RewardSource? source,
    String? transactionId,
    String? rewardedAdId,
    DateTime? earnedAt,
    RewardStatus? status,
    String? giftCardId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AmazonRewardCredit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      transactionId: transactionId ?? this.transactionId,
      rewardedAdId: rewardedAdId ?? this.rewardedAdId,
      earnedAt: earnedAt ?? this.earnedAt,
      status: status ?? this.status,
      giftCardId: giftCardId ?? this.giftCardId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmazonRewardCredit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AmazonRewardCredit(id: $id, amount: $amount, source: ${source.value}, status: ${status.value})';
  }
}

/// Reward source enum
enum RewardSource {
  rewardedAd('rewardedAd'),
  transaction('transaction');

  const RewardSource(this.value);
  final String value;

  static RewardSource fromString(String value) {
    return RewardSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => RewardSource.transaction,
    );
  }
}

/// Reward status enum
enum RewardStatus {
  pending('pending'),
  accumulated('accumulated'),
  converted('converted');

  const RewardStatus(this.value);
  final String value;

  static RewardStatus fromString(String value) {
    return RewardStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RewardStatus.pending,
    );
  }
}


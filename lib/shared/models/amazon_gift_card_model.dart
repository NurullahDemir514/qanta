import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart' as date_utils;

/// Amazon gift card model
/// Represents a gift card purchased and sent to user
class AmazonGiftCard {
  final String id;
  final String userId;
  final double amount; // Always 50.00 TL minimum
  final String? amazonCode; // Gift card code from Amazon (null when pending)
  final String? amazonClaimCode; // Claim code for user (null when pending)
  final DateTime? purchasedAt; // Null when pending
  final DateTime? sentAt;
  final GiftCardStatus status; // purchased, sent, redeemed
  final String recipientEmail; // User's email (for Amazon delivery)
  final List<String> creditIds; // Which credits were converted
  final DateTime createdAt;
  final DateTime updatedAt;

  const AmazonGiftCard({
    required this.id,
    required this.userId,
    required this.amount,
    this.amazonCode,
    this.amazonClaimCode,
    this.purchasedAt,
    this.sentAt,
    required this.status,
    required this.recipientEmail,
    required this.creditIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory AmazonGiftCard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AmazonGiftCard(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      amazonCode: data['amazon_code'] as String?,
      amazonClaimCode: data['amazon_claim_code'] as String?,
      purchasedAt: data['purchased_at'] != null
          ? date_utils.DateUtils.fromFirebase(data['purchased_at'])
          : null,
      sentAt: data['sent_at'] != null
          ? date_utils.DateUtils.fromFirebase(data['sent_at'])
          : null,
      status: GiftCardStatus.fromString(data['status'] as String? ?? 'pending'),
      recipientEmail: data['recipient_email'] as String? ?? '',
      creditIds: data['credit_ids'] != null 
          ? List<String>.from(data['credit_ids'] as List)
          : [],
      createdAt: data['created_at'] != null
          ? date_utils.DateUtils.fromFirebase(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? date_utils.DateUtils.fromFirebase(data['updated_at'])
          : DateTime.now(),
    );
  }

  /// Create from QueryDocumentSnapshot (for queries)
  factory AmazonGiftCard.fromQueryDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AmazonGiftCard.fromFirestore(doc);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'amount': amount,
      'amazon_code': amazonCode,
      'amazon_claim_code': amazonClaimCode,
      'purchased_at': purchasedAt != null
          ? date_utils.DateUtils.toFirebase(purchasedAt!)
          : null,
      'sent_at': sentAt != null
          ? date_utils.DateUtils.toFirebase(sentAt!)
          : null,
      'status': status.value,
      'recipient_email': recipientEmail,
      'credit_ids': creditIds,
      'created_at': date_utils.DateUtils.toFirebase(createdAt),
      'updated_at': date_utils.DateUtils.toFirebase(updatedAt),
    }..removeWhere((key, value) => value == null);
  }

  /// Create copy with updated fields
  AmazonGiftCard copyWith({
    String? id,
    String? userId,
    double? amount,
    String? amazonCode,
    String? amazonClaimCode,
    DateTime? purchasedAt,
    DateTime? sentAt,
    GiftCardStatus? status,
    String? recipientEmail,
    List<String>? creditIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AmazonGiftCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      amazonCode: amazonCode ?? this.amazonCode,
      amazonClaimCode: amazonClaimCode ?? this.amazonClaimCode,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      creditIds: creditIds ?? this.creditIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmazonGiftCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AmazonGiftCard(id: $id, amount: $amount, status: ${status.value})';
  }
}

/// Gift card status enum
enum GiftCardStatus {
  pending('pending'), // Waiting for admin to process
  purchased('purchased'),
  sent('sent'),
  redeemed('redeemed');

  const GiftCardStatus(this.value);
  final String value;

  static GiftCardStatus fromString(String value) {
    return GiftCardStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GiftCardStatus.pending,
    );
  }
}


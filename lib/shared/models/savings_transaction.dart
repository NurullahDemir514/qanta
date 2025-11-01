import 'package:cloud_firestore/cloud_firestore.dart';

/// Tasarruf işlem türü
enum SavingsTransactionType {
  deposit('deposit', 'Para Ekleme', '➕'),
  withdraw('withdraw', 'Para Çekme', '➖'),
  autoTransfer('auto_transfer', 'Otomatik Transfer', '🔄'),
  roundUp('round_up', 'Round-up', '⬆️'),
  interest('interest', 'Faiz', '💵');

  final String id;
  final String label;
  final String emoji;

  const SavingsTransactionType(this.id, this.label, this.emoji);

  static SavingsTransactionType fromId(String id) {
    return SavingsTransactionType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => SavingsTransactionType.deposit,
    );
  }
}

/// Tasarruf işlemi modeli
class SavingsTransaction {
  final String id;
  final String savingsGoalId;
  final String userId;
  final double amount;
  final SavingsTransactionType type;
  final String? sourceAccountId; // Nereden geldi/gitti
  final String? note;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Ek bilgiler (round-up detayları vs.)

  SavingsTransaction({
    required this.id,
    required this.savingsGoalId,
    required this.userId,
    required this.amount,
    required this.type,
    this.sourceAccountId,
    this.note,
    required this.createdAt,
    this.metadata,
  });

  /// Pozitif mi negatif mi?
  bool get isPositive => type == SavingsTransactionType.deposit ||
      type == SavingsTransactionType.autoTransfer ||
      type == SavingsTransactionType.roundUp ||
      type == SavingsTransactionType.interest;

  /// Görüntülenecek miktar (işaretli)
  double get signedAmount => isPositive ? amount : -amount;

  /// Firebase'e dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savings_goal_id': savingsGoalId,
      'user_id': userId,
      'amount': amount,
      'type': type.id,
      'source_account_id': sourceAccountId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Firebase'den oluştur
  factory SavingsTransaction.fromJson(Map<String, dynamic> json) {
    return SavingsTransaction(
      id: json['id'] as String,
      savingsGoalId: json['savings_goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: SavingsTransactionType.fromId(json['type'] as String),
      sourceAccountId: json['source_account_id'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Kopyalama metodu
  SavingsTransaction copyWith({
    String? id,
    String? savingsGoalId,
    String? userId,
    double? amount,
    SavingsTransactionType? type,
    String? sourceAccountId,
    String? note,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return SavingsTransaction(
      id: id ?? this.id,
      savingsGoalId: savingsGoalId ?? this.savingsGoalId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}


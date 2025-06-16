/// Transaction types supported by the system
enum TransactionType {
  income('income'),
  expense('expense'),
  transfer('transfer');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.expense,
    );
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Gelir';
      case TransactionType.expense:
        return 'Gider';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

/// Unified transaction model for all financial transactions
class TransactionModelV2 {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime transactionDate;
  
  // References
  final String? categoryId;
  final String sourceAccountId;
  final String? targetAccountId; // for transfers
  final String? installmentId;
  
  // Additional fields
  final bool isRecurring;
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModelV2({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.categoryId,
    required this.sourceAccountId,
    this.targetAccountId,
    this.installmentId,
    this.isRecurring = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this is an income transaction
  bool get isIncome => type == TransactionType.income;

  /// Whether this is an expense transaction
  bool get isExpense => type == TransactionType.expense;

  /// Whether this is a transfer transaction
  bool get isTransfer => type == TransactionType.transfer;

  /// Whether this is part of an installment
  bool get isInstallment => installmentId != null;

  /// Amount with sign (positive for income, negative for expense)
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return amount; // Neutral for transfers
    }
  }

  /// Display description with installment info if applicable
  String get displayDescription {
    if (notes != null && notes!.contains('installment')) {
      return description;
    }
    return description;
  }

  /// Create from JSON
  factory TransactionModelV2.fromJson(Map<String, dynamic> json) {
    return TransactionModelV2(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      categoryId: json['category_id'] as String?,
      sourceAccountId: json['source_account_id'] as String,
      targetAccountId: json['target_account_id'] as String?,
      installmentId: json['installment_id'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'category_id': categoryId,
      'source_account_id': sourceAccountId,
      'target_account_id': targetAccountId,
      'installment_id': installmentId,
      'is_recurring': isRecurring,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  TransactionModelV2 copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
    String? categoryId,
    String? sourceAccountId,
    String? targetAccountId,
    String? installmentId,
    bool? isRecurring,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModelV2(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      categoryId: categoryId ?? this.categoryId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      installmentId: installmentId ?? this.installmentId,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModelV2 && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModelV2(id: $id, type: ${type.value}, amount: $amount, description: $description)';
  }
}

/// Extended transaction model with joined data for display
class TransactionWithDetailsV2 extends TransactionModelV2 {
  final String? sourceAccountName;
  final String? sourceAccountType;
  final String? targetAccountName;
  final String? targetAccountType;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const TransactionWithDetailsV2({
    required super.id,
    required super.userId,
    required super.type,
    required super.amount,
    required super.description,
    required super.transactionDate,
    super.categoryId,
    required super.sourceAccountId,
    super.targetAccountId,
    super.installmentId,
    super.isRecurring = false,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    this.sourceAccountName,
    this.sourceAccountType,
    this.targetAccountName,
    this.targetAccountType,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  /// Create from JSON with joined data
  factory TransactionWithDetailsV2.fromJson(Map<String, dynamic> json) {
    return TransactionWithDetailsV2(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      categoryId: json['category_id'] as String?,
      sourceAccountId: json['source_account_id'] as String,
      targetAccountId: json['target_account_id'] as String?,
      installmentId: json['installment_id'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sourceAccountName: json['source_account_name'] as String?,
      sourceAccountType: json['source_account_type'] as String?,
      targetAccountName: json['target_account_name'] as String?,
      targetAccountType: json['target_account_type'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
    );
  }

  /// Display name for the account involved
  String get accountDisplayName {
    if (isTransfer) {
      return '$sourceAccountName → $targetAccountName';
    }
    return sourceAccountName ?? 'Unknown Account';
  }
} 
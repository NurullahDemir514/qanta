import '../design_system/transaction_design_system.dart';

/// Master installment transaction model
class InstallmentTransactionModel {
  final String id;
  final String userId;
  final String sourceAccountId;
  final double totalAmount;
  final double monthlyAmount;
  final int count;
  final DateTime startDate;
  final String description;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentTransactionModel({
    required this.id,
    required this.userId,
    required this.sourceAccountId,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.count,
    required this.startDate,
    required this.description,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage => 0.0; // Will be calculated with details

  /// Create from JSON
  factory InstallmentTransactionModel.fromJson(Map<String, dynamic> json) {
    return InstallmentTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceAccountId: json['source_account_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      monthlyAmount: (json['monthly_amount'] as num).toDouble(),
      count: json['count'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      description: json['description'] as String,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'source_account_id': sourceAccountId,
      'total_amount': totalAmount,
      'monthly_amount': monthlyAmount,
      'count': count,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'description': description,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  InstallmentTransactionModel copyWith({
    String? id,
    String? userId,
    String? sourceAccountId,
    double? totalAmount,
    double? monthlyAmount,
    int? count,
    DateTime? startDate,
    String? description,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      totalAmount: totalAmount ?? this.totalAmount,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      count: count ?? this.count,
      startDate: startDate ?? this.startDate,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallmentTransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InstallmentTransactionModel(id: $id, description: $description, count: $count)';
  }
}

/// Individual installment detail model
class InstallmentDetailModel {
  final String id;
  final String installmentTransactionId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final bool isPaid;
  final DateTime? paidDate;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentDetailModel({
    required this.id,
    required this.installmentTransactionId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    this.isPaid = false,
    this.paidDate,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this installment is overdue
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  /// Whether this installment is due soon (within 7 days)
  bool get isDueSoon {
    if (isPaid) return false;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }

  /// Days until due (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Create from JSON
  factory InstallmentDetailModel.fromJson(Map<String, dynamic> json) {
    return InstallmentDetailModel(
      id: json['id'] as String,
      installmentTransactionId: json['installment_transaction_id'] as String,
      installmentNumber: json['installment_number'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
      paidDate: json['paid_date'] != null 
          ? DateTime.parse(json['paid_date'] as String) 
          : null,
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installment_transaction_id': installmentTransactionId,
      'installment_number': installmentNumber,
      'due_date': dueDate.toIso8601String().split('T')[0], // Date only
      'amount': amount,
      'is_paid': isPaid,
      'paid_date': paidDate?.toIso8601String(),
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  InstallmentDetailModel copyWith({
    String? id,
    String? installmentTransactionId,
    int? installmentNumber,
    DateTime? dueDate,
    double? amount,
    bool? isPaid,
    DateTime? paidDate,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentDetailModel(
      id: id ?? this.id,
      installmentTransactionId: installmentTransactionId ?? this.installmentTransactionId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallmentDetailModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InstallmentDetailModel(id: $id, number: $installmentNumber, isPaid: $isPaid)';
  }
}

/// Combined installment model with progress information
class InstallmentWithProgressModel extends InstallmentTransactionModel {
  final String? accountName;
  final int paidCount;
  final int totalCount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime? nextDueDate;

  const InstallmentWithProgressModel({
    required super.id,
    required super.userId,
    required super.sourceAccountId,
    required super.totalAmount,
    required super.monthlyAmount,
    required super.count,
    required super.startDate,
    required super.description,
    super.categoryId,
    required super.createdAt,
    required super.updatedAt,
    this.accountName,
    required this.paidCount,
    required this.totalCount,
    required this.paidAmount,
    required this.remainingAmount,
    this.nextDueDate,
  });

  /// Progress percentage (0.0 to 1.0)
  @override
  double get progressPercentage => totalCount > 0 ? paidCount / totalCount : 0.0;

  /// Whether all installments are paid
  bool get isCompleted => paidCount >= totalCount;

  /// Whether there are overdue installments
  bool get hasOverduePayments => nextDueDate != null && nextDueDate!.isBefore(DateTime.now());

  /// Create from JSON with progress data
  factory InstallmentWithProgressModel.fromJson(Map<String, dynamic> json) {
    return InstallmentWithProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceAccountId: json['source_account_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      monthlyAmount: (json['monthly_amount'] as num).toDouble(),
      count: json['count'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      description: json['description'] as String,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      accountName: json['account_name'] as String?,
      paidCount: json['paid_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      nextDueDate: json['next_due_date'] != null 
          ? DateTime.parse(json['next_due_date'] as String) 
          : null,
    );
  }

  /// Display progress as text
  String get progressText => '$paidCount/$totalCount';

  /// Display remaining amount with currency
  String get remainingAmountText => '₺${TransactionDesignSystem.formatNumber(remainingAmount)}';
} 
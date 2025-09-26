class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double monthlyLimit;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double spentAmount;

  // Computed properties
  double get amount => monthlyLimit;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
    this.spentAmount = 0.0,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'monthly_limit': monthlyLimit,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'spent_amount': spentAmount,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? monthlyLimit,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? spentAmount,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}

class BudgetCategoryStats {
  final String categoryId;
  final String categoryName;
  final double monthlyLimit;
  final double currentSpent;
  final int transactionCount;
  final double percentage;
  final bool isOverBudget;

  BudgetCategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.currentSpent,
    required this.transactionCount,
    required this.percentage,
    required this.isOverBudget,
  });

  double get remainingAmount => monthlyLimit - currentSpent;
  double get overBudgetAmount => isOverBudget ? currentSpent - monthlyLimit : 0.0;
  double get progressPercentage => (currentSpent / monthlyLimit).clamp(0.0, 1.0);
} 
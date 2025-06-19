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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double limit;
  final BudgetPeriod period;
  final int month;
  final int year;
  final int? week; // Haftalık limitler için
  final int? budgetYear; // Yıllık limitler için (aylık limitlerde de kullanılır)
  final bool isRecurring; // Otomatik yenileme
  final DateTime startDate; // Başlangıç tarihi
  final DateTime createdAt;
  final DateTime updatedAt;
  final double spentAmount;

  // Computed properties
  double get amount => limit;
  
  /// Calculate end date based on start date and period
  DateTime get endDate {
    switch (period) {
      case BudgetPeriod.weekly:
        // 7 gün sonraki gün (dahil değil, son gün = startDate + 6 gün)
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        // 1 ay sonraki ayın aynı günü (dahil değil) - 1 gün = son gün
        // Örnek: 1 Ocak başlangıç -> 31 Ocak bitiş
        final nextMonthSameDay = DateTime(startDate.year, startDate.month + 1, startDate.day);
        // 1 gün geri git ki son gün dahil olsun
        return nextMonthSameDay.subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        // 1 yıl sonraki yılın aynı günü (dahil değil) - 1 gün = son gün
        final nextYearSameDay = DateTime(startDate.year + 1, startDate.month, startDate.day);
        return nextYearSameDay.subtract(const Duration(days: 1));
    }
  }
  
  // Backward compatibility
  double get monthlyLimit => period == BudgetPeriod.monthly ? limit : 0.0;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.period,
    required this.month,
    required this.year,
    this.week,
    this.budgetYear,
    this.isRecurring = false,
    required this.startDate,
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
      limit: (json['limit'] as num?)?.toDouble() ?? (json['monthly_limit'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (p) => p.name == json['period'],
        orElse: () => BudgetPeriod.monthly, // Default to monthly for backward compatibility
      ),
      month: json['month'] as int,
      year: json['year'] as int,
      week: json['week'] as int?,
      budgetYear: json['budget_year'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      startDate: _parseDateTime(json['start_date'] ?? json['created_at']), // Fallback to created_at for backward compatibility
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
        final parsed = DateTime.parse(value);
        // Prevent UTC conversion
        return DateTime(parsed.year, parsed.month, parsed.day, 
                       parsed.hour, parsed.minute, parsed.second);
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
      'limit': limit,
      'period': period.name,
      'month': month,
      'year': year,
      'week': week,
      'budget_year': budgetYear,
      'is_recurring': isRecurring,
      'start_date': startDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'spent_amount': spentAmount,
      // Backward compatibility
      'monthly_limit': monthlyLimit,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? limit,
    BudgetPeriod? period,
    int? month,
    int? year,
    int? week,
    int? budgetYear,
    bool? isRecurring,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? spentAmount,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      month: month ?? this.month,
      year: year ?? this.year,
      week: week ?? this.week,
      budgetYear: budgetYear ?? this.budgetYear,
      isRecurring: isRecurring ?? this.isRecurring,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}

class BudgetCategoryStats {
  final String categoryId;
  final String categoryName;
  final double limit;
  final BudgetPeriod period;
  final double currentSpent;
  final int transactionCount;
  final double percentage;
  final bool isOverBudget;
  final bool isRecurring;
  final DateTime startDate;

  BudgetCategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.period,
    required this.currentSpent,
    required this.transactionCount,
    required this.percentage,
    required this.isOverBudget,
    required this.isRecurring,
    required this.startDate,
  });

  /// Calculate end date based on start date and period
  DateTime get endDate {
    switch (period) {
      case BudgetPeriod.weekly:
        // 7 gün sonraki gün (dahil değil, son gün = startDate + 6 gün)
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        // 1 ay sonraki ayın aynı günü (dahil değil) - 1 gün = son gün
        // Örnek: 1 Ocak başlangıç -> 31 Ocak bitiş
        final nextMonthSameDay = DateTime(startDate.year, startDate.month + 1, startDate.day);
        // 1 gün geri git ki son gün dahil olsun
        return nextMonthSameDay.subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        // 1 yıl sonraki yılın aynı günü (dahil değil) - 1 gün = son gün
        final nextYearSameDay = DateTime(startDate.year + 1, startDate.month, startDate.day);
        return nextYearSameDay.subtract(const Duration(days: 1));
    }
  }

  // Backward compatibility
  double get monthlyLimit => period == BudgetPeriod.monthly ? limit : 0.0;
  
  double get remainingAmount => limit - currentSpent;
  double get overBudgetAmount => isOverBudget ? currentSpent - limit : 0.0;
  double get progressPercentage => (currentSpent / limit).clamp(0.0, 1.0);
  
  String get periodDisplayName {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Haftalık'; // Fallback - should use localized version
      case BudgetPeriod.monthly:
        return 'Aylık'; // Fallback - should use localized version
      case BudgetPeriod.yearly:
        return 'Yıllık'; // Fallback - should use localized version
    }
  }
} 
class IncomeStatsModel {
  final String category;
  final String categoryDisplayName;
  final double totalAmount;
  final int transactionCount;
  final double avgAmount;
  final double percentage;

  const IncomeStatsModel({
    required this.category,
    required this.categoryDisplayName,
    required this.totalAmount,
    required this.transactionCount,
    required this.avgAmount,
    required this.percentage,
  });

  factory IncomeStatsModel.fromJson(Map<String, dynamic> json) {
    return IncomeStatsModel(
      category: json['category'] as String,
      categoryDisplayName: json['category_display_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      avgAmount: (json['avg_amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'category_display_name': categoryDisplayName,
      'total_amount': totalAmount,
      'transaction_count': transactionCount,
      'avg_amount': avgAmount,
      'percentage': percentage,
    };
  }

  @override
  String toString() {
    return 'IncomeStatsModel(category: $category, totalAmount: $totalAmount, percentage: $percentage%)';
  }
}

class MonthlyIncomeTrendModel {
  final String monthYear;
  final String monthName;
  final double totalIncome;
  final int transactionCount;
  final String topCategory;
  final double topCategoryAmount;
  final double growthPercentage;

  const MonthlyIncomeTrendModel({
    required this.monthYear,
    required this.monthName,
    required this.totalIncome,
    required this.transactionCount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.growthPercentage,
  });

  factory MonthlyIncomeTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyIncomeTrendModel(
      monthYear: json['month_year'] as String,
      monthName: json['month_name'] as String,
      totalIncome: (json['total_income'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      topCategory: json['top_category'] as String,
      topCategoryAmount: (json['top_category_amount'] as num).toDouble(),
      growthPercentage: (json['growth_percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month_year': monthYear,
      'month_name': monthName,
      'total_income': totalIncome,
      'transaction_count': transactionCount,
      'top_category': topCategory,
      'top_category_amount': topCategoryAmount,
      'growth_percentage': growthPercentage,
    };
  }

  // Büyüme durumu
  bool get isGrowthPositive => growthPercentage > 0;
  bool get isGrowthNegative => growthPercentage < 0;
  bool get isGrowthStable => growthPercentage == 0;

  @override
  String toString() {
    return 'MonthlyIncomeTrendModel(monthYear: $monthYear, totalIncome: $totalIncome, growth: $growthPercentage%)';
  }
}

class IncomeComparisonModel {
  final double currentTotal;
  final double previousTotal;
  final double difference;
  final double growthPercentage;
  final double currentAvg;
  final double previousAvg;
  final int currentCount;
  final int previousCount;

  const IncomeComparisonModel({
    required this.currentTotal,
    required this.previousTotal,
    required this.difference,
    required this.growthPercentage,
    required this.currentAvg,
    required this.previousAvg,
    required this.currentCount,
    required this.previousCount,
  });

  factory IncomeComparisonModel.fromJson(Map<String, dynamic> json) {
    return IncomeComparisonModel(
      currentTotal: (json['current_total'] as num).toDouble(),
      previousTotal: (json['previous_total'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      growthPercentage: (json['growth_percentage'] as num).toDouble(),
      currentAvg: (json['current_avg'] as num).toDouble(),
      previousAvg: (json['previous_avg'] as num).toDouble(),
      currentCount: json['current_count'] as int,
      previousCount: json['previous_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_total': currentTotal,
      'previous_total': previousTotal,
      'difference': difference,
      'growth_percentage': growthPercentage,
      'current_avg': currentAvg,
      'previous_avg': previousAvg,
      'current_count': currentCount,
      'previous_count': previousCount,
    };
  }

  // Durum kontrolleri
  bool get isImprovement => difference > 0;
  bool get isDecline => difference < 0;
  bool get isStable => difference == 0;

  // Büyüme durumu
  bool get isGrowthPositive => growthPercentage > 0;
  bool get isGrowthNegative => growthPercentage < 0;
  bool get isGrowthStable => growthPercentage == 0;

  @override
  String toString() {
    return 'IncomeComparisonModel(current: $currentTotal, previous: $previousTotal, growth: $growthPercentage%)';
  }
}

class TopIncomeSourceModel {
  final String category;
  final String categoryDisplayName;
  final double totalAmount;
  final int transactionCount;
  final double avgAmount;
  final DateTime lastTransactionDate;
  final double percentageOfTotal;

  const TopIncomeSourceModel({
    required this.category,
    required this.categoryDisplayName,
    required this.totalAmount,
    required this.transactionCount,
    required this.avgAmount,
    required this.lastTransactionDate,
    required this.percentageOfTotal,
  });

  factory TopIncomeSourceModel.fromJson(Map<String, dynamic> json) {
    return TopIncomeSourceModel(
      category: json['category'] as String,
      categoryDisplayName: json['category_display_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      avgAmount: (json['avg_amount'] as num).toDouble(),
      lastTransactionDate: DateTime.parse(json['last_transaction_date'] as String),
      percentageOfTotal: (json['percentage_of_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'category_display_name': categoryDisplayName,
      'total_amount': totalAmount,
      'transaction_count': transactionCount,
      'avg_amount': avgAmount,
      'last_transaction_date': lastTransactionDate.toIso8601String(),
      'percentage_of_total': percentageOfTotal,
    };
  }

  // Son işlemden bu yana geçen gün sayısı
  int get daysSinceLastTransaction {
    return DateTime.now().difference(lastTransactionDate).inDays;
  }

  // Aktif mi (son 30 gün içinde işlem var mı)
  bool get isActive => daysSinceLastTransaction <= 30;

  @override
  String toString() {
    return 'TopIncomeSourceModel(category: $categoryDisplayName, totalAmount: $totalAmount, percentage: $percentageOfTotal%)';
  }
} 
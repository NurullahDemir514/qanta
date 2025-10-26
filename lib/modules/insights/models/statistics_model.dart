import 'package:flutter/foundation.dart';

enum TimePeriod {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  yearToDate,
}

class CategoryStatistic {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final int transactionCount;

  const CategoryStatistic({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  factory CategoryStatistic.fromJson(Map<String, dynamic> json) {
    return CategoryStatistic(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryIcon: json['categoryIcon'] ?? '💰',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'amount': amount,
      'percentage': percentage,
      'transactionCount': transactionCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryStatistic &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categoryIcon == categoryIcon &&
        other.amount == amount &&
        other.percentage == percentage &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode {
    return categoryId.hashCode ^
        categoryName.hashCode ^
        categoryIcon.hashCode ^
        amount.hashCode ^
        percentage.hashCode ^
        transactionCount.hashCode;
  }
}

class MonthlyTrend {
  final String monthYear;
  final double income;
  final double expenses;
  final double netBalance;
  final int transactionCount;

  const MonthlyTrend({
    required this.monthYear,
    required this.income,
    required this.expenses,
    required this.netBalance,
    required this.transactionCount,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      monthYear: json['monthYear'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthYear': monthYear,
      'income': income,
      'expenses': expenses,
      'netBalance': netBalance,
      'transactionCount': transactionCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyTrend &&
        other.monthYear == monthYear &&
        other.income == income &&
        other.expenses == expenses &&
        other.netBalance == netBalance &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode {
    return monthYear.hashCode ^
        income.hashCode ^
        expenses.hashCode ^
        netBalance.hashCode ^
        transactionCount.hashCode;
  }
}

class StatisticsData {
  final TimePeriod period;
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double averageSpending;
  final double highestSpending;
  final double lowestSpending;
  final double savingsRate;
  final int totalTransactions;
  final List<CategoryStatistic> categoryBreakdown;
  final List<MonthlyTrend> monthlyTrends;
  final DateTime startDate;
  final DateTime endDate;

  const StatisticsData({
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.averageSpending,
    required this.highestSpending,
    required this.lowestSpending,
    required this.savingsRate,
    required this.totalTransactions,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    required this.startDate,
    required this.endDate,
  });

  factory StatisticsData.empty(TimePeriod period) {
    final now = DateTime.now();
    return StatisticsData(
      period: period,
      totalIncome: 0,
      totalExpenses: 0,
      netBalance: 0,
      averageSpending: 0,
      highestSpending: 0,
      lowestSpending: 0,
      savingsRate: 0,
      totalTransactions: 0,
      categoryBreakdown: [],
      monthlyTrends: [],
      startDate: now,
      endDate: now,
    );
  }

  factory StatisticsData.fromJson(Map<String, dynamic> json) {
    return StatisticsData(
      period: TimePeriod.values[json['period'] ?? 0],
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
      averageSpending: (json['averageSpending'] ?? 0).toDouble(),
      highestSpending: (json['highestSpending'] ?? 0).toDouble(),
      lowestSpending: (json['lowestSpending'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
          ?.map((item) => CategoryStatistic.fromJson(item))
          .toList() ?? [],
      monthlyTrends: (json['monthlyTrends'] as List<dynamic>?)
          ?.map((item) => MonthlyTrend.fromJson(item))
          .toList() ?? [],
      startDate: _parseLocalDate(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: _parseLocalDate(json['endDate'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  /// Helper to parse date without UTC conversion
  static DateTime _parseLocalDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateTime(parsed.year, parsed.month, parsed.day, 
                     parsed.hour, parsed.minute, parsed.second);
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.index,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': netBalance,
      'averageSpending': averageSpending,
      'highestSpending': highestSpending,
      'lowestSpending': lowestSpending,
      'savingsRate': savingsRate,
      'totalTransactions': totalTransactions,
      'categoryBreakdown': categoryBreakdown.map((item) => item.toJson()).toList(),
      'monthlyTrends': monthlyTrends.map((item) => item.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  bool get hasData => totalTransactions > 0;

  double get expensePercentage {
    if (totalIncome == 0) return 0;
    return (totalExpenses / totalIncome) * 100;
  }

  double get incomePercentage {
    if (totalIncome == 0) return 0;
    return 100.0;
  }

  StatisticsData copyWith({
    TimePeriod? period,
    double? totalIncome,
    double? totalExpenses,
    double? netBalance,
    double? averageSpending,
    double? highestSpending,
    double? lowestSpending,
    double? savingsRate,
    int? totalTransactions,
    List<CategoryStatistic>? categoryBreakdown,
    List<MonthlyTrend>? monthlyTrends,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return StatisticsData(
      period: period ?? this.period,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netBalance: netBalance ?? this.netBalance,
      averageSpending: averageSpending ?? this.averageSpending,
      highestSpending: highestSpending ?? this.highestSpending,
      lowestSpending: lowestSpending ?? this.lowestSpending,
      savingsRate: savingsRate ?? this.savingsRate,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      monthlyTrends: monthlyTrends ?? this.monthlyTrends,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatisticsData &&
        other.period == period &&
        other.totalIncome == totalIncome &&
        other.totalExpenses == totalExpenses &&
        other.netBalance == netBalance &&
        other.averageSpending == averageSpending &&
        other.highestSpending == highestSpending &&
        other.lowestSpending == lowestSpending &&
        other.savingsRate == savingsRate &&
        other.totalTransactions == totalTransactions &&
        listEquals(other.categoryBreakdown, categoryBreakdown) &&
        listEquals(other.monthlyTrends, monthlyTrends) &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return period.hashCode ^
        totalIncome.hashCode ^
        totalExpenses.hashCode ^
        netBalance.hashCode ^
        averageSpending.hashCode ^
        highestSpending.hashCode ^
        lowestSpending.hashCode ^
        savingsRate.hashCode ^
        totalTransactions.hashCode ^
        categoryBreakdown.hashCode ^
        monthlyTrends.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }

  @override
  String toString() {
    return 'StatisticsData(period: $period, totalIncome: $totalIncome, totalExpenses: $totalExpenses, netBalance: $netBalance, totalTransactions: $totalTransactions)';
  }
} 
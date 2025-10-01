import 'package:flutter/foundation.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/category_model.dart';
import '../models/statistics_model.dart';

class StatisticsProvider extends ChangeNotifier {
  final UnifiedProviderV2 _unifiedProvider;
  
  StatisticsData? _statistics;
  bool _isLoading = false;
  String? _error;

  StatisticsProvider(this._unifiedProvider);

  // Getters
  StatisticsData? get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  // Load statistics for a specific time period
  Future<void> loadStatistics(TimePeriod period) async {
    _setLoading(true);
    _clearError();

    try {
      final dateRange = _getDateRangeForPeriod(period);
      final transactions = _getTransactionsInRange(dateRange.start, dateRange.end);
      
      if (transactions.isEmpty) {
        _statistics = StatisticsData.empty(period);
      } else {
        _statistics = _calculateStatistics(period, transactions, dateRange.start, dateRange.end);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('İstatistikler yüklenirken bir hata oluştu: ${e.toString()}');
      debugPrint('Error loading statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get transactions within a date range
  List<TransactionWithDetailsV2> _getTransactionsInRange(DateTime startDate, DateTime endDate) {
    return _unifiedProvider.transactions.where((transaction) {
      final transactionDate = transaction.transactionDate;
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate statistics from transactions
  StatisticsData _calculateStatistics(
    TimePeriod period,
    List<TransactionWithDetailsV2> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Separate income and expense transactions
    final incomeTransactions = transactions.where((t) => t.signedAmount > 0).toList();
    final expenseTransactions = transactions.where((t) => t.signedAmount < 0).toList();

    // Calculate totals
    final totalIncome = incomeTransactions.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = expenseTransactions.fold<double>(0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;

    // Calculate spending statistics
    final expenseAmounts = expenseTransactions.map((t) => t.amount).toList();
    final averageSpending = expenseAmounts.isEmpty ? 0.0 : expenseAmounts.reduce((a, b) => a + b) / expenseAmounts.length;
    final highestSpending = expenseAmounts.isEmpty ? 0.0 : expenseAmounts.reduce((a, b) => a > b ? a : b);
    final lowestSpending = expenseAmounts.isEmpty ? 0.0 : expenseAmounts.reduce((a, b) => a < b ? a : b);

    // Calculate savings rate
    final savingsRate = totalIncome == 0 ? 0.0 : (netBalance / totalIncome) * 100;

    // Calculate category breakdown
    final categoryBreakdown = _calculateCategoryBreakdown(expenseTransactions, totalExpenses);

    // Calculate monthly trends
    final monthlyTrends = _calculateMonthlyTrends(transactions, period);

    return StatisticsData(
      period: period,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netBalance,
      averageSpending: averageSpending,
      highestSpending: highestSpending,
      lowestSpending: lowestSpending,
      savingsRate: savingsRate,
      totalTransactions: transactions.length,
      categoryBreakdown: categoryBreakdown,
      monthlyTrends: monthlyTrends,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Calculate category breakdown
  List<CategoryStatistic> _calculateCategoryBreakdown(
    List<TransactionWithDetailsV2> expenseTransactions,
    double totalExpenses,
  ) {
    if (expenseTransactions.isEmpty || totalExpenses == 0) return [];

    // Group transactions by category
    final Map<String, List<TransactionWithDetailsV2>> categoryGroups = {};
    for (final transaction in expenseTransactions) {
      final categoryId = transaction.categoryId ?? 'other';
      categoryGroups.putIfAbsent(categoryId, () => []).add(transaction);
    }

    // Calculate statistics for each category
    final List<CategoryStatistic> categoryStats = [];
    for (final entry in categoryGroups.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      final categoryAmount = categoryTransactions.fold<double>(0, (sum, t) => sum + (t as TransactionWithDetailsV2).amount);
      final percentage = (categoryAmount / totalExpenses) * 100;

      // Get category info
      final category = _getCategoryInfo(categoryId);
      
      categoryStats.add(CategoryStatistic(
        categoryId: categoryId,
        categoryName: category.name,
        categoryIcon: category.icon,
        amount: categoryAmount,
        percentage: percentage,
        transactionCount: categoryTransactions.length,
      ));
    }

    // Sort by amount (highest first)
    categoryStats.sort((a, b) => b.amount.compareTo(a.amount));
    
    return categoryStats;
  }

  // Get category information
  ({String name, String icon}) _getCategoryInfo(String categoryId) {
    final category = _unifiedProvider.categories
        .cast<CategoryModel>()
        .firstWhere((c) => c.id == categoryId, orElse: () => CategoryModel(
          id: '', 
          name: 'Unknown', 
          icon: '💰',
          type: CategoryType.expense,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
    
    return (name: category.name, icon: category.icon ?? '💰');
  }

  // Calculate monthly trends
  List<MonthlyTrend> _calculateMonthlyTrends(
    List<TransactionWithDetailsV2> transactions,
    TimePeriod period,
  ) {
    if (transactions.isEmpty) return [];

    // Group transactions by month
    final Map<String, List<TransactionWithDetailsV2>> monthlyGroups = {};
    for (final transaction in transactions) {
      final monthYear = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      monthlyGroups.putIfAbsent(monthYear, () => []).add(transaction);
    }

    // Calculate trends for each month
    final List<MonthlyTrend> trends = [];
    for (final entry in monthlyGroups.entries) {
      final monthYear = entry.key;
      final monthTransactions = entry.value;
      
      final income = monthTransactions.where((t) => (t as TransactionWithDetailsV2).signedAmount > 0).fold<double>(0, (sum, t) => sum + (t as TransactionWithDetailsV2).amount);
      final expenses = monthTransactions.where((t) => (t as TransactionWithDetailsV2).signedAmount < 0).fold<double>(0, (sum, t) => sum + (t as TransactionWithDetailsV2).amount);
      final netBalance = income - expenses;
      
      trends.add(MonthlyTrend(
        monthYear: monthYear,
        income: income,
        expenses: expenses,
        netBalance: netBalance,
        transactionCount: monthTransactions.length,
      ));
    }

    // Sort by month (most recent first)
    trends.sort((a, b) => b.monthYear.compareTo(a.monthYear));
    
    return trends;
  }

  // Get date range for a specific period
  ({DateTime start, DateTime end}) _getDateRangeForPeriod(TimePeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case TimePeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (start: startOfMonth, end: today);

      case TimePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return (start: lastMonth, end: endOfLastMonth);

      case TimePeriod.last3Months:
        final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
        return (start: threeMonthsAgo, end: today);

      case TimePeriod.last6Months:
        final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
        return (start: sixMonthsAgo, end: today);

      case TimePeriod.yearToDate:
        final startOfYear = DateTime(now.year, 1, 1);
        return (start: startOfYear, end: today);
    }
  }

  // Refresh statistics
  Future<void> refreshStatistics() async {
    if (_statistics != null) {
      await loadStatistics(_statistics!.period);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
} 
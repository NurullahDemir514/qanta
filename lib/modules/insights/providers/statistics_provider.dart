import 'package:flutter/foundation.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/unified_category_model.dart';
import '../models/statistics_model.dart';

class StatisticsProvider extends ChangeNotifier {
  final UnifiedProviderV2 _unifiedProvider;

  StatisticsData? _statistics;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  StatisticsProvider(this._unifiedProvider) {
    _initializeListener();
  }

  /// Initialize listener for automatic updates
  void _initializeListener() {
    if (!_isInitialized) {
      _unifiedProvider.addListener(_onUnifiedProviderChanged);
      _isInitialized = true;
    }
  }

  /// Handle UnifiedProviderV2 changes - automatically refresh statistics
  void _onUnifiedProviderChanged() {
    // Only refresh if we have existing statistics (don't auto-load on first change)
    if (_statistics != null && !_isLoading && _isInitialized) {
      // Debounce: Don't refresh too frequently (200ms delay)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_statistics != null && !_isLoading && _isInitialized) {
          refreshStatistics();
        }
      });
    }
  }

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
      final transactions = _getTransactionsInRange(
        dateRange.start,
        dateRange.end,
      );

      if (transactions.isEmpty) {
        _statistics = StatisticsData.empty(period);
      } else {
        _statistics = _calculateStatistics(
          period,
          transactions,
          dateRange.start,
          dateRange.end,
        );
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
  List<TransactionWithDetailsV2> _getTransactionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _unifiedProvider.transactions.where((transaction) {
      final transactionDate = transaction.transactionDate;
      return transactionDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
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
    // Filter out transfers and stock transactions
    final filteredTransactions = transactions.where((t) {
      return t.type != TransactionType.transfer && !t.isStockTransaction;
    }).toList();
    
    // Separate income and expense transactions by type (more reliable than signedAmount)
    final incomeTransactions = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenseTransactions = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    

    // Calculate totals
    final totalIncome = incomeTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final totalExpenses = expenseTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final netBalance = totalIncome - totalExpenses;

    // Calculate spending statistics
    final expenseAmounts = expenseTransactions.map((t) => t.amount).toList();
    final averageSpending = expenseAmounts.isEmpty
        ? 0.0
        : expenseAmounts.reduce((a, b) => a + b) / expenseAmounts.length;
    final highestSpending = expenseAmounts.isEmpty
        ? 0.0
        : expenseAmounts.reduce((a, b) => a > b ? a : b);
    final lowestSpending = expenseAmounts.isEmpty
        ? 0.0
        : expenseAmounts.reduce((a, b) => a < b ? a : b);

    // Calculate savings rate
    final savingsRate = totalIncome == 0
        ? 0.0
        : (netBalance / totalIncome) * 100;

    // Calculate category breakdown
    final categoryBreakdown = _calculateCategoryBreakdown(
      expenseTransactions,
      totalExpenses,
    );

    // Calculate monthly trends
    final monthlyTrends = _calculateMonthlyTrends(filteredTransactions, period);

    return StatisticsData(
      period: period,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netBalance,
      averageSpending: averageSpending,
      highestSpending: highestSpending,
      lowestSpending: lowestSpending,
      savingsRate: savingsRate,
      totalTransactions: filteredTransactions.length,
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

    // Group transactions by category - normalize category IDs
    final Map<String, List<TransactionWithDetailsV2>> categoryGroups = {};
    for (final transaction in expenseTransactions) {
      // Normalize category ID: null, empty string, or whitespace -> 'other'
      final rawCategoryId = transaction.categoryId;
      final categoryId = (rawCategoryId == null || rawCategoryId.trim().isEmpty) 
          ? 'other' 
          : rawCategoryId.trim();
      
      categoryGroups.putIfAbsent(categoryId, () => []).add(transaction);
    }

    // Calculate statistics for each category
    final List<CategoryStatistic> categoryStats = [];
    for (final entry in categoryGroups.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      
      final categoryAmount = categoryTransactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );
      final percentage = (categoryAmount / totalExpenses) * 100;

      // Get category info
      final categoryInfo = _getCategoryInfo(categoryId);

      categoryStats.add(
        CategoryStatistic(
          categoryId: categoryId,
          categoryName: categoryInfo.name,
          categoryIcon: categoryInfo.icon,
          amount: categoryAmount,
          percentage: percentage,
          transactionCount: categoryTransactions.length,
        ),
      );
    }

    // Sort by amount (highest first)
    categoryStats.sort((a, b) => b.amount.compareTo(a.amount));

    return categoryStats;
  }

  // Get category information
  ({String name, String icon}) _getCategoryInfo(String categoryId) {
    try {
      final category = _unifiedProvider.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => UnifiedCategoryModel(
          id: '',
          name: 'Unknown',
          displayName: 'Unknown',
          description: 'Unknown category',
          iconName: 'money',
          colorHex: '#FF6B6B',
          sortOrder: 999,
          categoryType: CategoryType.expense,
        ),
      );

      return (name: category.displayName, icon: category.iconName);
    } catch (e) {
      debugPrint('❌ Error getting category info: $e');
      return (name: 'Unknown', icon: 'money');
    }
  }

  // Calculate monthly trends
  List<MonthlyTrend> _calculateMonthlyTrends(
    List<TransactionWithDetailsV2> transactions,
    TimePeriod period,
  ) {
    if (transactions.isEmpty) return [];

    // Filter out transfers and stock transactions
    final filteredTransactions = transactions.where((t) {
      return t.type != TransactionType.transfer && !t.isStockTransaction;
    }).toList();

    // Group transactions by month
    final Map<String, List<TransactionWithDetailsV2>> monthlyGroups = {};
    for (final transaction in filteredTransactions) {
      final monthYear =
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      monthlyGroups.putIfAbsent(monthYear, () => []).add(transaction);
    }

    // Calculate trends for each month
    final List<MonthlyTrend> trends = [];
    for (final entry in monthlyGroups.entries) {
      final monthYear = entry.key;
      final monthTransactions = entry.value;

      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final expenses = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final netBalance = income - expenses;

      trends.add(
        MonthlyTrend(
          monthYear: monthYear,
          income: income,
          expenses: expenses,
          netBalance: netBalance,
          transactionCount: monthTransactions.length,
        ),
      );
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
    if (_isInitialized) {
      _unifiedProvider.removeListener(_onUnifiedProviderChanged);
      _isInitialized = false;
    }
    super.dispose();
  }
}

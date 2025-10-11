import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/providers/unified_provider_v2.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/design_system/transaction_design_system.dart' as TDS;
import '../../shared/services/category_icon_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late AppLocalizations l10n;
  DateTime _currentMonth = DateTime.now();
  late DateTime _firstDayOfMonth;
  late DateTime _lastDayOfMonth;
  late int _daysInMonth;
  late int _firstWeekday;

  @override
  void initState() {
    super.initState();
    _updateMonthData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  void _updateMonthData() {
    _firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    _lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    _daysInMonth = _lastDayOfMonth.day;
    _firstWeekday = _firstDayOfMonth.weekday;
  }

  String _getLocalizedMonthName(int month) {
    switch (month) {
      case 1:
        return l10n.january;
      case 2:
        return l10n.february;
      case 3:
        return l10n.march;
      case 4:
        return l10n.april;
      case 5:
        return l10n.may;
      case 6:
        return l10n.june;
      case 7:
        return l10n.july;
      case 8:
        return l10n.august;
      case 9:
        return l10n.september;
      case 10:
        return l10n.october;
      case 11:
        return l10n.november;
      case 12:
        return l10n.december;
      default:
        return '';
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _updateMonthData();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _updateMonthData();
    });
  }

  Map<String, double> _getDailyAmounts(
    List<TransactionWithDetailsV2> transactions,
  ) {
    final Map<String, double> dailyAmounts = {};

    for (final transaction in transactions) {
      final dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(transaction.transactionDate);
      final amount = transaction.signedAmount;

      if (dailyAmounts.containsKey(dateKey)) {
        dailyAmounts[dateKey] = dailyAmounts[dateKey]! + amount;
      } else {
        dailyAmounts[dateKey] = amount;
      }
    }

    return dailyAmounts;
  }

  void _showDayTransactions(
    DateTime date,
    List<TransactionWithDetailsV2> dayTransactions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayTransactionsBottomSheet(
        date: date,
        transactions: dayTransactions,
        l10n: l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendar,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            Text(
              '${_getLocalizedMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<UnifiedProviderV2>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;
          final dailyAmounts = _getDailyAmounts(transactions);

          return Column(
            children: [
              // Month Navigation
              _buildMonthNavigation(isDark),

              // Analysis Section
              _buildAnalysisSection(dailyAmounts, transactions, isDark),

              // Calendar Grid
              Expanded(
                child: _buildCalendarGrid(dailyAmounts, transactions, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthNavigation(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          Text(
            '${_getLocalizedMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
    Map<String, double> dailyAmounts,
    List<TransactionWithDetailsV2> transactions,
    bool isDark,
  ) {
    final monthlyStats = _calculateMonthlyStats(dailyAmounts, transactions);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.secondary.withValues(alpha: 0.1)
              : AppColors.secondary.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Income
          Expanded(
            child: _buildCompactStat(
              label: l10n.income,
              amount: monthlyStats['totalIncome']!,
              color: Colors.green,
              isDark: isDark,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 32,
            color: isDark
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.secondary.withValues(alpha: 0.1),
          ),
          // Expense
          Expanded(
            child: _buildCompactStat(
              label: l10n.expense,
              amount: monthlyStats['totalExpense']!,
              color: Colors.red,
              isDark: isDark,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 32,
            color: isDark
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.secondary.withValues(alpha: 0.1),
          ),
          // Net Balance
          Expanded(
            child: _buildCompactStat(
              label: l10n.net,
              amount: monthlyStats['netBalance']!,
              color: monthlyStats['netBalance']! >= 0
                  ? Colors.blue
                  : Colors.orange,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateMonthlyStats(
    Map<String, double> dailyAmounts,
    List<TransactionWithDetailsV2> transactions,
  ) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      final monthDate = DateTime(_currentMonth.year, _currentMonth.month, 1);

      // Check if transaction is in current month
      if (transactionDate.year == monthDate.year &&
          transactionDate.month == monthDate.month) {
        if (transaction.signedAmount > 0) {
          totalIncome += transaction.signedAmount;
        } else {
          totalExpense += transaction.signedAmount.abs();
        }
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': totalIncome - totalExpense,
    };
  }

  Widget _buildCompactStat({
    required String label,
    required double amount,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).formatAmount(amount),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    Map<String, double> dailyAmounts,
    List<TransactionWithDetailsV2> transactions,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Weekday Headers
          _buildWeekdayHeaders(isDark),

          // Calendar Days
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: _firstWeekday - 1 + _daysInMonth,
              itemBuilder: (context, index) {
                if (index < _firstWeekday - 1) {
                  return const SizedBox(); // Empty cells for days before month start
                }

                final day = index - (_firstWeekday - 1) + 1;
                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                );
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final amount = dailyAmounts[dateKey] ?? 0.0;

                // Get transactions for this day
                final dayTransactions = transactions.where((t) {
                  final transactionDate = DateTime(
                    t.transactionDate.year,
                    t.transactionDate.month,
                    t.transactionDate.day,
                  );
                  return transactionDate.isAtSameMomentAs(date);
                }).toList();

                return _buildDayCell(
                  date,
                  day,
                  amount,
                  dayTransactions,
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(bool isDark) {
    final weekdays = [
      l10n.mondayShort,
      l10n.tuesdayShort,
      l10n.wednesdayShort,
      l10n.thursdayShort,
      l10n.fridayShort,
      l10n.saturdayShort,
      l10n.sundayShort,
    ];

    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.secondary : AppColors.secondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int day,
    double amount,
    List<TransactionWithDetailsV2> dayTransactions,
    bool isDark,
  ) {
    final isToday = date.isAtSameMomentAs(DateTime.now());
    final isIncome = amount > 0;
    final isExpense = amount < 0;
    final hasTransactions = dayTransactions.isNotEmpty;

    return GestureDetector(
      onTap: hasTransactions
          ? () => _showDayTransactions(date, dayTransactions)
          : null,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
              ? AppColors.darkCard
              : AppColors.lightCard,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 1.5)
              : hasTransactions
              ? Border.all(
                  color: isDark
                      ? AppColors.secondary.withValues(alpha: 0.2)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  width: 0.5,
                )
              : null,
          boxShadow: hasTransactions
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              day.toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                color: isToday
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
            ),

            // Amount display with smart formatting
            if (amount != 0) ...[
              const SizedBox(height: 3),
              _buildSmartAmountDisplay(
                amount,
                isIncome,
                isExpense,
                isDark,
                hasTransactions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartAmountDisplay(
    double amount,
    bool isIncome,
    bool isExpense,
    bool isDark,
    bool hasTransactions,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final formattedAmount = themeProvider.formatAmount(amount);

    // Determine if we need compact display
    final needsCompactDisplay = _needsCompactDisplay(formattedAmount);

    if (needsCompactDisplay) {
      return _buildCompactAmountDisplay(amount, isIncome, isExpense, isDark);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isIncome
            ? Colors.green.withValues(alpha: 0.1)
            : isExpense
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        formattedAmount,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isIncome
              ? Colors.green.shade600
              : isExpense
              ? Colors.red.shade600
              : isDark
              ? AppColors.darkText
              : AppColors.lightText,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCompactAmountDisplay(
    double amount,
    bool isIncome,
    bool isExpense,
    bool isDark,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final compactAmount = _formatCompactAmount(amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: isIncome
            ? Colors.green.withValues(alpha: 0.15)
            : isExpense
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        compactAmount,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isIncome
              ? Colors.green.shade600
              : isExpense
              ? Colors.red.shade600
              : isDark
              ? AppColors.darkText
              : AppColors.lightText,
        ),
      ),
    );
  }

  bool _needsCompactDisplay(String formattedAmount) {
    // Check if the formatted amount is too long for the cell
    return formattedAmount.length > 8; // Adjust threshold as needed
  }

  String _formatCompactAmount(double amount) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final sign = isNegative ? '-' : '';

    if (absAmount >= 1000000) {
      return '$sign₺${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      return '$sign₺${(absAmount / 1000).toStringAsFixed(1)}K';
    } else if (absAmount >= 100) {
      return '$sign₺${absAmount.toStringAsFixed(0)}';
    } else {
      return '$sign₺${absAmount.toStringAsFixed(1)}';
    }
  }
}

class _DayTransactionsBottomSheet extends StatelessWidget {
  final DateTime date;
  final List<TransactionWithDetailsV2> transactions;
  final AppLocalizations l10n;

  const _DayTransactionsBottomSheet({
    required this.date,
    required this.transactions,
    required this.l10n,
  });

  String _getLocalizedMonthName(int month) {
    switch (month) {
      case 1:
        return l10n.january;
      case 2:
        return l10n.february;
      case 3:
        return l10n.march;
      case 4:
        return l10n.april;
      case 5:
        return l10n.may;
      case 6:
        return l10n.june;
      case 7:
        return l10n.july;
      case 8:
        return l10n.august;
      case 9:
        return l10n.september;
      case 10:
        return l10n.october;
      case 11:
        return l10n.november;
      case 12:
        return l10n.december;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = transactions.fold(
      0.0,
      (sum, t) => sum + t.signedAmount,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.secondary : AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day} ${_getLocalizedMonthName(date.month)} ${date.year}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    Text(
                      '${transactions.length} ${l10n.transactions}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).formatAmount(totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: totalAmount >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTransactionsFound,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItemWithDesignSystem(
                        context,
                        transaction,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionWithDetailsV2 transaction,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.type),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.categoryName ?? l10n.unknownCategory,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).formatAmount(transaction.signedAmount),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: transaction.signedAmount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemWithDesignSystem(
    BuildContext context,
    TransactionWithDetailsV2 transaction,
    bool isDark,
  ) {
    // Convert V2 transaction type to design system type
    TDS.TransactionType transactionType;
    switch (transaction.type) {
      case TransactionType.income:
        transactionType = TDS.TransactionType.income;
        break;
      case TransactionType.expense:
        transactionType = TDS.TransactionType.expense;
        break;
      case TransactionType.transfer:
        transactionType = TDS.TransactionType.transfer;
        break;
      case TransactionType.stock:
        transactionType =
            TDS.TransactionType.income; // Treat stock as income for display
        break;
    }

    // Get category info from provider
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    final category = transaction.categoryId != null
        ? providerV2.getCategoryById(transaction.categoryId!)
        : null;

    // Get category icon using CategoryIconService
    IconData? categoryIcon;
    if (transaction.categoryName != null) {
      categoryIcon = CategoryIconService.getIcon(
        transaction.categoryName!.toLowerCase(),
      );
    }

    if (categoryIcon == null || categoryIcon == Icons.more_horiz_rounded) {
      if (category?.icon != null && category!.icon != 'category') {
        categoryIcon = CategoryIconService.getIcon(category.iconName);
      }
    }

    // Use transaction type color instead of category color
    // This ensures all income transactions are green, all expense transactions are red

    // Use displayTime from transaction model
    final time = transaction.displayTime;

    // Card name - centralized logic
    final cardName = TDS.TransactionDesignSystem.formatCardName(
      cardName: transaction.sourceAccountName ?? l10n.account,
      transactionType: transactionType.name,
      sourceAccountName: transaction.sourceAccountName,
      targetAccountName: transaction.targetAccountName,
      context: context,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TDS.TransactionDesignSystem.buildTransactionItemFromV2(
        context: context,
        transaction: transaction,
        isDark: isDark,
        time: time,
        categoryIconData: categoryIcon,
        onLongPress: () {
          // Optional: Add long press functionality
        },
        isFirst: true,
        isLast: true,
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.stock:
        return Icons.show_chart;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      case TransactionType.stock:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

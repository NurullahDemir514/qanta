import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/statement_summary.dart';
import '../models/transaction_model_v2.dart';
import '../utils/date_utils.dart';
import '../services/category_icon_service.dart';
import '../design_system/transaction_design_system.dart';
import '../../core/theme/theme_provider.dart';

/// **Shared Statement UI Components**
/// 
/// Centralized widgets for consistent statement display across:
/// - Active Statement Tab
/// - Future Statements Tab  
/// - Past Statements Tab
/// 
/// **Benefits:**
/// - Consistent styling and behavior
/// - Reduced code duplication
/// - Easier maintenance and updates
/// - Centralized animation logic

// ===============================
// STATEMENT CARD - Main Container
// ===============================

/// **Unified Statement Card Widget**
/// 
/// Replaces `AppleCardStatementWidget` and `_AppleCardPastStatement`
/// with a single, configurable component.
class StatementCard extends StatefulWidget {
  final StatementSummary statement;
  final ThemeProvider themeProvider;
  final bool isDark;
  final bool isNextStatement;
  final List<TransactionWithDetailsV2> transactions;
  final List<UpcomingInstallment> installments;
  final double? previousMonthTotal;
  final VoidCallback? onTap;
  final bool showMonthlyChange;
  final bool showTransactionCount;

  const StatementCard({
    super.key,
    required this.statement,
    required this.themeProvider,
    required this.isDark,
    this.isNextStatement = false,
    required this.transactions,
    required this.installments,
    this.previousMonthTotal,
    this.onTap,
    this.showMonthlyChange = true,
    this.showTransactionCount = true,
  });

  @override
  State<StatementCard> createState() => _StatementCardState();
}

class _StatementCardState extends State<StatementCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 350)
    );
    _expandAnim = CurvedAnimation(
      parent: _controller, 
      curve: Curves.easeInOut
    );
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    
    // Call external tap handler if provided
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statement = widget.statement;
    final totalAmount = statement.remainingAmount; // Use remainingAmount instead of totalWithInstallments
    final hasTransactions = widget.transactions.isNotEmpty || widget.installments.isNotEmpty;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF18181A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _buildStatementTitle(),
                      ),
                      StatementBadge(
                        statement: statement,
                        isDark: widget.isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Amount and Monthly Change Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.themeProvider.formatAmount(totalAmount),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (widget.showMonthlyChange && widget.previousMonthTotal != null)
                        MonthlyChangeBadge(
                          currentAmount: totalAmount,
                          previousAmount: widget.previousMonthTotal!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Period and Due Date Row
                  _buildPeriodInfoRow(),
                ],
              ),
            ),
            
            // Expandable Content
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1.0,
              child: Column(
                children: [
                  if (hasTransactions)
                    StatementTransactionsList(
                      transactions: widget.transactions,
                      installments: widget.installments,
                      themeProvider: widget.themeProvider,
                      isDark: widget.isDark,
                    ),
                  if (!hasTransactions)
                    StatementEmptyState(isDark: widget.isDark),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementTitle() {
    final statement = widget.statement;
    
    if (widget.isNextStatement) {
      return Text(
        'Sonraki Ekstre',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
        ),
      );
    }
    
    if (statement.isPaid) {
      // Past statement
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statement.period.periodText,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Son Ödeme: ${statement.period.dueDateText}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
        ],
      );
    }
    
    // Active/Future statement
    return Text(
      statement.period.periodText,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
      ),
    );
  }

  Widget _buildPeriodInfoRow() {
    final statement = widget.statement;
    
    if (statement.isPaid && widget.showTransactionCount) {
      // Past statement: show transaction count
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              '${widget.transactions.length} işlem',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ),
        ],
      );
    }
    
    // Active/Future statement: show period and due date
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Icon(
            Icons.calendar_today,
            size: 14,
            color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 2,
          child: Text(
            'Dönem: ${statement.period.periodText}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 0,
          child: Icon(
            Icons.payments,
            size: 14,
            color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 2,
          child: Text(
            'Son Ödeme: ${statement.period.dueDateText}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ===============================
// STATEMENT BADGE - Status Indicator
// ===============================

/// **Statement Status Badge**
/// 
/// Shows payment status with appropriate colors and text
class StatementBadge extends StatelessWidget {
  final StatementSummary statement;
  final bool isDark;

  const StatementBadge({
    super.key,
    required this.statement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: statusData.color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusData.text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: statusData.color,
        ),
      ),
    );
  }

  ({String text, Color color}) _getStatusData() {
    if (statement.isPaid) {
      return (text: 'Ödendi', color: const Color(0xFF4CAF50));
    }
    
    if (statement.period.isOverdue) {
      return (text: 'Vadesi geçti', color: const Color(0xFFFF453A));
    }
    
    if (statement.period.isDueSoon) {
      return (text: '${statement.period.daysUntilDue} gün kaldı', color: const Color(0xFF8E8E93));
    }
    
    return (text: '${statement.period.daysUntilDue} gün kaldı', color: const Color(0xFF8E8E93));
  }
}

// ===============================
// MONTHLY CHANGE BADGE
// ===============================

/// **Monthly Change Indicator**
/// 
/// Shows percentage change from previous month
class MonthlyChangeBadge extends StatelessWidget {
  final double currentAmount;
  final double previousAmount;

  const MonthlyChangeBadge({
    super.key,
    required this.currentAmount,
    required this.previousAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (previousAmount <= 0) return const SizedBox.shrink();
    
    final change = ((currentAmount - previousAmount) / previousAmount) * 100;
    final isIncrease = change > 0.5;
    final isDecrease = change < -0.5;
    final isNeutral = !isIncrease && !isDecrease;
    
    Color badgeColor;
    String arrow;
    
    if (isIncrease) {
      badgeColor = const Color(0xFFFF453A); // Red for increase (bad for credit cards)
      arrow = '↑';
    } else if (isDecrease) {
      badgeColor = const Color(0xFF30D158); // Green for decrease (good for credit cards)
      arrow = '↓';
    } else {
      badgeColor = const Color(0xFF007AFF); // Blue for neutral
      arrow = '';
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(isNeutral ? 0.10 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (arrow.isNotEmpty) ...[
            Text(
              arrow,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
            const SizedBox(width: 2),
          ],
          Text(
            '%${change.abs().toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// TRANSACTIONS LIST
// ===============================

/// **Statement Transactions List**
/// 
/// Unified list for both regular transactions and installments
class StatementTransactionsList extends StatelessWidget {
  final List<TransactionWithDetailsV2> transactions;
  final List<UpcomingInstallment> installments;
  final ThemeProvider themeProvider;
  final bool isDark;

  const StatementTransactionsList({
    super.key,
    required this.transactions,
    required this.installments,
    required this.themeProvider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out installment master transactions (show only regular transactions)
    final filteredTransactions = transactions.where((tx) => tx.installmentId == null).toList();
    
    // Combine transactions and installments with sorting
    final List<({String type, dynamic data, DateTime date})> allItems = [];
    
    // Add regular transactions
    for (final transaction in filteredTransactions) {
      allItems.add((
        type: 'transaction',
        data: transaction,
        date: transaction.transactionDate,
      ));
    }
    
    // Add installments
    for (final installment in installments) {
      allItems.add((
        type: 'installment',
        data: installment,
        date: installment.dueDate,
      ));
    }
    
    // Sort by date (newest first)
    allItems.sort((a, b) => b.date.compareTo(a.date));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: allItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isFirst = index == 0;
          final isLast = index == allItems.length - 1;
          
          if (item.type == 'transaction') {
            return _buildTransactionItem(
              item.data as TransactionWithDetailsV2,
              isFirst,
              isLast,
            );
          } else {
            return _buildInstallmentItem(
              item.data as UpcomingInstallment,
              isFirst,
              isLast,
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(
    TransactionWithDetailsV2 transaction,
    bool isFirst,
    bool isLast,
  ) {
    final categoryIcon = CategoryIconService.getIcon(transaction.categoryName ?? 'other');
    final categoryColor = CategoryIconService.getColorFromMap(transaction.categoryName ?? 'other');
    
    return Column(
      children: [
        TransactionDesignSystem.buildTransactionItemWithIcon(
          title: transaction.displayTitle,
          subtitle: transaction.displaySubtitle,
          amount: themeProvider.formatAmount(transaction.amount),
          time: null,
          isDark: isDark,
          specificIcon: categoryIcon,
          specificIconColor: categoryColor,
          specificBackgroundColor: categoryColor.withValues(alpha: 0.1),
          specificAmountColor: const Color(0xFFFF453A),
          onTap: () {},
          isFirst: isFirst,
          isLast: isLast,
          isPaid: transaction.isPaid,
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  Widget _buildInstallmentItem(
    UpcomingInstallment installment,
    bool isFirst,
    bool isLast,
  ) {
    final categoryIcon = CategoryIconService.getIcon(installment.categoryName ?? 'other');
    final categoryColor = CategoryIconService.getColorFromMap(installment.categoryName ?? 'other');
    
    return Column(
      children: [
        TransactionDesignSystem.buildTransactionItemWithIcon(
          title: installment.displayTitle,
          subtitle: installment.displaySubtitle,
          amount: themeProvider.formatAmount(installment.amount),
          time: null,
          isDark: isDark,
          specificIcon: categoryIcon,
          specificIconColor: categoryColor,
          specificBackgroundColor: categoryColor.withValues(alpha: 0.1),
          specificAmountColor: const Color(0xFFFF453A),
          onTap: () {},
          isFirst: isFirst,
          isLast: isLast,
          isPaid: installment.isPaid,
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(
        height: 0.5,
        color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
      ),
    );
  }
}

// ===============================
// EMPTY STATE
// ===============================

/// **Statement Empty State**
/// 
/// Shown when no transactions or installments exist
class StatementEmptyState extends StatelessWidget {
  final bool isDark;

  const StatementEmptyState({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'Bu ekstrede işlem bulunmuyor',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
      ),
    );
  }
}

// ===============================
// LOADING STATE
// ===============================

/// **Statement Loading State**
/// 
/// Standardized loading indicator for all statement widgets
class StatementLoadingState extends StatelessWidget {
  final bool isDark;
  final String? message;

  const StatementLoadingState({
    super.key,
    required this.isDark,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? Colors.white : const Color(0xFF6D6D70),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===============================
// ERROR STATE
// ===============================

/// **Statement Error State**
/// 
/// Standardized error display with retry functionality
class StatementErrorState extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback? onRetry;

  const StatementErrorState({
    super.key,
    required this.isDark,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

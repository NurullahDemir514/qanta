import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';

/// Monthly Balance Chart Widget
/// Shows monthly balance, income, expenses and balance trend over time
class MonthlyBalanceChart extends StatefulWidget {
  const MonthlyBalanceChart({super.key});

  @override
  State<MonthlyBalanceChart> createState() => _MonthlyBalanceChartState();
}

class _MonthlyBalanceChartState extends State<MonthlyBalanceChart> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer2<UnifiedProviderV2, ThemeProvider>(
      builder: (context, dataProvider, themeProvider, child) {
        // Get current month transactions
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        
        // Get last month transactions
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        
        final currentMonthTransactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(currentMonthEnd.add(const Duration(days: 1))) &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();
        
        final lastMonthTransactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(lastMonthEnd.add(const Duration(days: 1))) &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();
        
        // Calculate monthly totals
        final currentMonthIncome = currentMonthTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final currentMonthExpenses = currentMonthTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final monthlyBalance = currentMonthIncome - currentMonthExpenses;
        
        // Calculate daily balance for current month
        final currentMonthDailyBalance = _calculateDailyBalance(
          currentMonthTransactions,
          currentMonthStart,
          now,
        );
        
        // Calculate daily balance for last month
        final lastMonthDailyBalance = _calculateDailyBalance(
          lastMonthTransactions,
          lastMonthStart,
          lastMonthEnd,
        );
        
        // Check if we have enough data to show chart
        // Show empty state if no transactions at all
        if (currentMonthTransactions.isEmpty && lastMonthTransactions.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }
        
        return Container(
          margin: EdgeInsets.only(bottom: 20.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Monthly Balance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AYLIK BAKİYE',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          CurrencyUtils.formatAmount(monthlyBalance, themeProvider.currency),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.3,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Income
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GELİR',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '+${CurrencyUtils.formatAmount(currentMonthIncome, themeProvider.currency)}',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50),
                            letterSpacing: -0.3,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Expenses
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GİDER',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '-${CurrencyUtils.formatAmount(currentMonthExpenses, themeProvider.currency)}',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF4C4C),
                            letterSpacing: -0.3,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Category-based Donut Chart - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive dimensions based on available width
                  final chartHeight = (constraints.maxWidth * 0.85).clamp(160.0, 240.0);
                  final centerSpaceRadius = (chartHeight * 0.25).clamp(40.0, 65.0);
                  final sectionRadius = (chartHeight * 0.23).clamp(35.0, 60.0);
                  
                  return SizedBox(
                    height: chartHeight,
                    child: _buildCategoryDonutChart(
                      currentMonthTransactions,
                      isDark,
                      themeProvider.currency,
                      context,
                      centerSpaceRadius: centerSpaceRadius,
                      sectionRadius: sectionRadius,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build category-based donut chart
  Widget _buildCategoryDonutChart(
    List<TransactionWithDetailsV2> transactions,
    bool isDark,
    Currency currency,
    BuildContext context, {
    double centerSpaceRadius = 50,
    double sectionRadius = 45,
  }) {
    // Filter expense transactions
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenseTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            SizedBox(height: 12.h),
            Text(
              'Harcama yok',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, List<TransactionWithDetailsV2>> categoryGroups = {};
    for (final transaction in expenseTransactions) {
      final categoryId = transaction.categoryId?.trim() ?? 'other';
      categoryGroups.putIfAbsent(categoryId, () => []).add(transaction);
    }

    // Calculate category totals
    final categoryTotals = <String, double>{};
    for (final entry in categoryGroups.entries) {
      final total = entry.value.fold<double>(
        0.0,
        (sum, t) => sum + t.amount,
      );
      categoryTotals[entry.key] = total;
    }

    // Sort by amount (descending) and take top 6
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(6).toList();
    final totalExpenses = categoryTotals.values.fold<double>(0.0, (sum, val) => sum + val);

    if (totalExpenses == 0) {
      return Center(
        child: Text(
          'Veri yok',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      );
    }

    // Create pie chart sections with category info
    final sections = <PieChartSectionData>[];
    final categoryInfoMap = <int, Map<String, dynamic>>{};

    // Professional finance app color palette
    // Modern, vibrant colors harmonized with app's primary colors (Mint #34D399, Blue #007AFF)
    // Colors optimized for data visualization with excellent contrast and accessibility
    final colors = [
      Colors.green.shade500, // Mint Green (app's secondary color)
      const Color(0xFF007AFF), // iOS Blue (app's primary blue)
      const Color(0xFF8B5CF6), // Vibrant Purple
      const Color(0xFFF59E0B), // Amber Orange
      const Color(0xFFEF4444), // Coral Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Electric Pink
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFF97316), // Deep Orange
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFA855F7), // Purple
    ];

    for (int i = 0; i < topCategories.length; i++) {
      final categoryEntry = topCategories[i];
      final categoryId = categoryEntry.key;
      final amount = categoryEntry.value;
      final percentage = (amount / totalExpenses) * 100;

      // Get category name and icon (colors come from vibrant palette)
      String categoryName = 'Diğer';
      String? categoryIcon;
      int transactionCount = 0;
      try {
        final firstTransaction = categoryGroups[categoryId]?.first;
        if (firstTransaction != null) {
          categoryName = firstTransaction.categoryName ?? 'Diğer';
          categoryIcon = firstTransaction.categoryIcon;
          transactionCount = categoryGroups[categoryId]!.length;
        }
      } catch (e) {
        // Use default
      }

      // Get icon from CategoryIconService (only icons, not colors)
      IconData iconData;
      if (categoryIcon != null && categoryIcon.isNotEmpty) {
        iconData = CategoryIconService.getIcon(categoryIcon);
      } else {
        // Fallback to category name
        iconData = CategoryIconService.getIcon(categoryName.toLowerCase());
      }

      // Use vibrant color palette directly (don't use CategoryIconService for colors)
      Color categoryColor = colors[i % colors.length];

      // Store category info for tooltip
      categoryInfoMap[i] = {
        'name': categoryName,
        'icon': iconData,
        'amount': amount,
        'percentage': percentage,
        'color': categoryColor,
        'transactionCount': transactionCount,
      };

      sections.add(
        PieChartSectionData(
          value: amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          color: categoryColor,
          radius: sectionRadius,
          titleStyle: GoogleFonts.inter(
            fontSize: (sectionRadius * 0.18).clamp(9.0, 12.0).sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add "Other" section if there are more categories
    if (sortedCategories.length > 6) {
      final otherTotal = sortedCategories
          .skip(6)
          .fold<double>(0.0, (sum, entry) => sum + entry.value);
      final otherPercent = (otherTotal / totalExpenses) * 100;
      final otherCount = sortedCategories.length - 6;
      
      // Use vibrant color for "Other" category from palette
      // Use the last color from palette or a muted vibrant color
      Color otherColor = isDark 
          ? const Color(0xFF6B7280) // Slate gray for dark mode
          : const Color(0xFF94A3B8); // Lighter slate for light mode
      
      categoryInfoMap[topCategories.length] = {
        'name': 'Diğer',
        'icon': CategoryIconService.getIcon('diğer'), // Turkish name for 'other'
        'amount': otherTotal,
        'percentage': otherPercent,
        'color': otherColor,
        'transactionCount': otherCount,
      };
      
      sections.add(
        PieChartSectionData(
          value: otherTotal,
          title: otherPercent >= 5 ? '${otherPercent.toStringAsFixed(0)}%' : '',
          color: otherColor,
          radius: sectionRadius,
          titleStyle: GoogleFonts.inter(
            fontSize: (sectionRadius * 0.18).clamp(9.0, 12.0).sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: centerSpaceRadius,
            sections: sections,
            pieTouchData: PieTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (pieTouchResponse == null || 
                    pieTouchResponse.touchedSection == null ||
                    event.localPosition == null) {
                  _removeOverlay();
                  return;
                }
                
                final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                if (categoryInfoMap.containsKey(touchedIndex)) {
                  final categoryInfo = categoryInfoMap[touchedIndex]!;
                  // Show tooltip overlay at touch location
                  _showTooltip(
                    context,
                    event.localPosition!,
                    categoryInfo['name'] as String,
                    categoryInfo['icon'] as IconData,
                    categoryInfo['amount'] as double,
                    categoryInfo['percentage'] as double,
                    categoryInfo['transactionCount'] as int,
                    categoryInfo['color'] as Color,
                    currency,
                    isDark,
                  );
                } else {
                  _removeOverlay();
                }
              },
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 500),
          swapAnimationCurve: Curves.easeInOut,
        ),
        // Center text showing total expenses - Responsive font sizes
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Toplam Harcama',
              style: GoogleFonts.inter(
                fontSize: (centerSpaceRadius * 0.18).clamp(10.0, 13.0).sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyUtils.formatAmount(totalExpenses, currency),
                style: GoogleFonts.inter(
                  fontSize: (centerSpaceRadius * 0.3).clamp(14.0, 22.0).sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${topCategories.length}${sortedCategories.length > 6 ? '+' : ''} kategori',
              style: GoogleFonts.inter(
                fontSize: (centerSpaceRadius * 0.16).clamp(9.0, 11.0).sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Show tooltip overlay at touch location
  void _showTooltip(
    BuildContext context,
    Offset touchLocation,
    String categoryName,
    IconData categoryIcon,
    double amount,
    double percentage,
    int transactionCount,
    Color color,
    Currency currency,
    bool isDark,
  ) {
    _removeOverlay();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPosition = renderBox.localToGlobal(touchLocation);
    final screenSize = MediaQuery.of(context).size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: (globalPosition.dx - 100).clamp(10.0, screenSize.width - 210),
        top: (globalPosition.dy - 90).clamp(10.0, screenSize.height - 190),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 150),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 200.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name with icon - compact
                    Row(
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIcon,
                            color: Colors.white,
                            size: 16.w,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // Amount - compact
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyUtils.formatAmount(amount, currency),
                              style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // Stats row - compact
                    Row(
                      children: [
                        // Percentage badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 12.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '%${percentage.toStringAsFixed(1)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Transaction count
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 12.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$transactionCount',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Aylık Bakiye',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noDataAvailable ?? 'Veri yok',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChart(
    List<MapEntry<DateTime, double>> currentMonthData,
    List<MapEntry<DateTime, double>> lastMonthData,
    DateTime monthStart,
    DateTime today,
    bool isDark,
    double currentBalance,
    Currency currency,
  ) {
    // Check if we have enough data
    final hasEnoughCurrentData = currentMonthData.length >= 3;
    final hasLastMonthData = lastMonthData.isNotEmpty;
    
    // If not enough data, show simple bar chart or empty state
    if (!hasEnoughCurrentData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            SizedBox(height: 12.h),
            Text(
              'Yeterli veri yok',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Daha fazla işlem ekleyin',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }
    
    // If no last month data, show simplified bar chart
    if (!hasLastMonthData) {
      return _buildBarChart(
        currentMonthData,
        monthStart,
        today,
        isDark,
        currentBalance,
        currency,
      );
    }
    
    // Combine all dates and find min/max values for line chart
    final allDates = <DateTime>{};
    allDates.addAll(currentMonthData.map((e) => e.key));
    allDates.addAll(lastMonthData.map((e) => e.key));
    
    if (allDates.isEmpty) {
      return Center(
        child: Text(
          'Veri yok',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      );
    }
    
    final sortedDates = allDates.toList()..sort();
    final minDate = sortedDates.first;
    final maxDate = sortedDates.last;
    
    // Find min/max balance values
    final allValues = <double>[];
    allValues.addAll(currentMonthData.map((e) => e.value));
    allValues.addAll(lastMonthData.map((e) => e.value));
    allValues.add(0); // Include zero for reference
    
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    // Use smaller padding (3%) to prevent graph from shifting down too much
    final padding = valueRange > 0 
        ? (valueRange * 0.03).clamp(5.0, valueRange * 0.1)
        : 50.0; // Default padding if all values are same
    
    // Create spot data for current month
    final currentMonthSpots = currentMonthData.map((entry) {
      final x = entry.key.difference(minDate).inDays.toDouble();
      final y = entry.value;
      return FlSpot(x, y);
    }).toList();
    
    // Create spot data for last month (only show if within visible range)
    final lastMonthSpots = lastMonthData
        .where((entry) => entry.key.isAfter(minDate.subtract(const Duration(days: 1))))
        .map((entry) {
      final x = entry.key.difference(minDate).inDays.toDouble();
      final y = entry.value;
      return FlSpot(x, y);
    }).toList();
    
    // Find today's index
    final todayIndex = today.difference(minDate).inDays.toDouble();
    final todayValue = currentMonthData
        .where((e) => e.key.year == today.year && 
                     e.key.month == today.month && 
                     e.key.day == today.day)
        .map((e) => e.value)
        .firstOrNull ?? currentBalance;
    
    // Generate X axis labels (show 4-5 dates)
    final daysDiff = maxDate.difference(minDate).inDays;
    final labelInterval = (daysDiff / 4).ceil();
    final xAxisLabels = <String>[];
    for (int i = 0; i <= daysDiff; i += labelInterval) {
      final date = minDate.add(Duration(days: i));
      xAxisLabels.add(DateFormat('MMM d', 'tr_TR').format(date).toLowerCase());
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxValue - minValue + padding * 2) / 4,
          getDrawingHorizontalLine: (value) {
            // Highlight zero line
            if ((value - 0).abs() < 0.01) {
              return FlLine(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.15) 
                    : Colors.black.withValues(alpha: 0.15),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.03) 
                  : Colors.black.withValues(alpha: 0.03),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < xAxisLabels.length * labelInterval) {
                  final labelIndex = (index / labelInterval).floor();
                  if (labelIndex < xAxisLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        xAxisLabels[labelIndex],
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Last month line (light gray)
          if (lastMonthSpots.isNotEmpty)
            LineChartBarData(
              spots: lastMonthSpots,
              isCurved: true,
              color: isDark ? Colors.white30 : Colors.black26,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          
          // Current month line (modern gradient style)
          LineChartBarData(
            spots: currentMonthSpots,
            isCurved: true,
            curveSmoothness: 0.35, // Smoother curves
            color: isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Show dot only at today with glow effect
                if ((spot.x - todayIndex).abs() < 0.5) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5),
                    strokeWidth: 4,
                    strokeColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  );
                }
                // Show subtle dots on other points
                if (index % 3 == 0) {
                  return FlDotCirclePainter(
                    radius: 2,
                    color: (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5))
                        .withValues(alpha: 0.4),
                  );
                }
                return FlDotCirclePainter(radius: 0);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5))
                      .withValues(alpha: 0.25),
                  (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5))
                      .withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            aboveBarData: BarAreaData(
              show: false,
            ),
          ),
        ],
        minX: 0,
        maxX: daysDiff.toDouble(),
        // Calculate minY more carefully to prevent downward shift
        minY: minValue < 0 
            ? minValue - padding // For negative values, allow padding
            : (minValue - padding * 0.5).clamp(minValue * 0.98, minValue), // For positive values, use half padding to prevent too much downward shift
        maxY: maxValue + padding,
        lineTouchData: LineTouchData(
          enabled: true,
          touchSpotThreshold: 20,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5),
                  strokeWidth: 2,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5),
                      strokeWidth: 3,
                      strokeColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            tooltipMargin: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final date = minDate.add(Duration(days: touchedSpot.x.toInt()));
                final isPositive = touchedSpot.y >= 0;
                return LineTooltipItem(
                  '${DateFormat('d MMM', 'tr_TR').format(date)}\n',
                  GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                        TextSpan(
                          text: CurrencyUtils.formatAmount(touchedSpot.y, currency),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: isPositive 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFFF4C4C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          // Reference line at zero
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
  
  List<MapEntry<DateTime, double>> _calculateDailyBalance(
    List<TransactionWithDetailsV2> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyBalance = <DateTime, double>{};
    double runningBalance = 0.0;
    
    // Sort transactions by date
    final sortedTransactions = List<TransactionWithDetailsV2>.from(transactions)
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    
    // Initialize all days in range with starting balance
    for (var date = startDate; 
         date.isBefore(endDate.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      dailyBalance[DateTime(date.year, date.month, date.day)] = runningBalance;
    }
    
    // Process transactions
    for (final transaction in sortedTransactions) {
      final transactionDate = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      
      if (transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(endDate.add(const Duration(days: 1)))) {
        // Update balance from this date forward
        if (transaction.type == TransactionType.income) {
          runningBalance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          runningBalance -= transaction.amount;
        }
        
        // Update all future days
        for (var date = transactionDate; 
             date.isBefore(endDate.add(const Duration(days: 1))); 
             date = date.add(const Duration(days: 1))) {
          dailyBalance[DateTime(date.year, date.month, date.day)] = runningBalance;
        }
      }
    }
    
    return dailyBalance.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
  
  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  /// Build bar chart when last month data is not available
  Widget _buildBarChart(
    List<MapEntry<DateTime, double>> currentMonthData,
    DateTime monthStart,
    DateTime today,
    bool isDark,
    double currentBalance,
    Currency currency,
  ) {
    if (currentMonthData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Find min/max values
    final allValues = currentMonthData.map((e) => e.value).toList();
    allValues.add(0); // Include zero for reference
    
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    // Use smaller padding (3%) to prevent graph from shifting down too much
    final padding = valueRange > 0 
        ? (valueRange * 0.03).clamp(5.0, valueRange * 0.1)
        : 50.0; // Default padding if all values are same
    
    // Create bar groups
    final barGroups = currentMonthData.asMap().entries.map((entry) {
      final index = entry.key;
      final balance = entry.value.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: balance,
            gradient: balance >= 0
                ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50),
                      isDark 
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.7) 
                          : const Color(0xFF4CAF50).withValues(alpha: 0.7),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark ? const Color(0xFFFF4C4C) : const Color(0xFFFF4C4C),
                      isDark 
                          ? const Color(0xFFFF4C4C).withValues(alpha: 0.7) 
                          : const Color(0xFFFF4C4C).withValues(alpha: 0.7),
                    ],
                  ),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue + padding,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    }).toList();
    
    // Generate X axis labels
    final daysDiff = currentMonthData.length;
    final labelInterval = (daysDiff / 4).ceil().clamp(1, daysDiff);
    final xAxisLabels = <String>[];
    for (int i = 0; i < currentMonthData.length; i += labelInterval) {
      if (i < currentMonthData.length) {
        final date = currentMonthData[i].key;
        xAxisLabels.add(DateFormat('d MMM', 'tr_TR').format(date).toLowerCase());
      }
    }
    
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxValue - minValue + padding * 2) / 4,
          getDrawingHorizontalLine: (value) {
            // Highlight zero line
            if ((value - 0).abs() < 0.01) {
              return FlLine(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.15) 
                    : Colors.black.withValues(alpha: 0.15),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.03) 
                  : Colors.black.withValues(alpha: 0.03),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < currentMonthData.length && index % labelInterval == 0) {
                  final labelIndex = (index / labelInterval).floor();
                  if (labelIndex < xAxisLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        xAxisLabels[labelIndex],
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        // Calculate minY more carefully to prevent downward shift
        minY: minValue < 0 
            ? minValue - padding // For negative values, allow padding
            : (minValue - padding * 0.5).clamp(minValue * 0.98, minValue), // For positive values, use half padding to prevent too much downward shift
        maxY: maxValue + padding,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = currentMonthData[groupIndex].key;
              final balance = rod.toY;
              final isPositive = balance >= 0;
              return BarTooltipItem(
                '${DateFormat('d MMM', 'tr_TR').format(date)}\n',
                GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: CurrencyUtils.formatAmount(balance, currency),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: isPositive 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFFF4C4C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern Sparkline Painter - Creates a smooth, gradient-filled area chart
class _ModernSparklinePainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> currentMonthData;
  final List<MapEntry<DateTime, double>> lastMonthData;
  final double minValue;
  final double maxValue;
  final bool isDark;
  final DateTime today;

  _ModernSparklinePainter({
    required this.currentMonthData,
    required this.lastMonthData,
    required this.minValue,
    required this.maxValue,
    required this.isDark,
    required this.today,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentMonthData.isEmpty) return;

    final valueRange = maxValue - minValue;
    if (valueRange == 0) return;

    // Calculate points for current month
    final currentPoints = <Offset>[];
    final dateRange = currentMonthData.last.key.difference(currentMonthData.first.key).inDays;
    final widthPerDay = dateRange > 0 ? size.width / dateRange : size.width;

    for (int i = 0; i < currentMonthData.length; i++) {
      final entry = currentMonthData[i];
      final daysFromStart = entry.key.difference(currentMonthData.first.key).inDays;
      final x = daysFromStart * widthPerDay;
      final normalizedValue = (entry.value - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);
      currentPoints.add(Offset(x, y));
    }

    // Draw last month line (subtle)
    if (lastMonthData.isNotEmpty) {
      final lastPoints = <Offset>[];
      for (int i = 0; i < lastMonthData.length; i++) {
        final entry = lastMonthData[i];
        final daysFromStart = entry.key.difference(currentMonthData.first.key).inDays;
        if (daysFromStart >= 0 && daysFromStart <= dateRange) {
          final x = daysFromStart * widthPerDay;
          final normalizedValue = (entry.value - minValue) / valueRange;
          final y = size.height - (normalizedValue * size.height);
          lastPoints.add(Offset(x, y));
        }
      }

      if (lastPoints.length > 1) {
        final lastPath = Path();
        lastPath.moveTo(lastPoints[0].dx, lastPoints[0].dy);
        for (int i = 1; i < lastPoints.length; i++) {
          final p0 = lastPoints[i - 1];
          final p1 = lastPoints[i];
          final cpX = (p0.dx + p1.dx) / 2;
          lastPath.quadraticBezierTo(cpX, p0.dy, cpX, (p0.dy + p1.dy) / 2);
          lastPath.quadraticBezierTo(cpX, p1.dy, p1.dx, p1.dy);
        }

        final lastPaint = Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(lastPath, lastPaint);
      }
    }

    // Draw gradient area for current month
    if (currentPoints.length > 1) {
      final path = Path();
      path.moveTo(currentPoints[0].dx, currentPoints[0].dy);
      
      // Create smooth curve
      for (int i = 1; i < currentPoints.length; i++) {
        final p0 = currentPoints[i - 1];
        final p1 = currentPoints[i];
        final cpX = (p0.dx + p1.dx) / 2;
        path.quadraticBezierTo(cpX, p0.dy, cpX, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(cpX, p1.dy, p1.dx, p1.dy);
      }

      // Close path for gradient fill
      path.lineTo(currentPoints.last.dx, size.height);
      path.lineTo(currentPoints.first.dx, size.height);
      path.close();

      // Draw gradient fill
      final gradient = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5)).withValues(alpha: 0.3),
          (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5)).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

      final fillPaint = Paint()..shader = gradient;
      canvas.drawPath(path, fillPaint);

      // Draw main line
      final linePaint = Paint()
        ..color = isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // Draw dots on key points
      final dotPaint = Paint()
        ..color = isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5);
      
      // Draw dot at today
      int? todayIndex;
      for (int i = 0; i < currentMonthData.length; i++) {
        final entry = currentMonthData[i];
        if (entry.key.year == today.year && 
            entry.key.month == today.month && 
            entry.key.day == today.day) {
          todayIndex = i;
          break;
        }
      }
      
      if (todayIndex != null && todayIndex >= 0 && todayIndex < currentPoints.length) {
        final todayPoint = currentPoints[todayIndex];
        canvas.drawCircle(todayPoint, 6, dotPaint);
        canvas.drawCircle(
          todayPoint,
          6,
          Paint()
            ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      // Draw subtle dots on other points (every 3rd point)
      for (int i = 0; i < currentPoints.length; i += 3) {
        if (todayIndex == null || i != todayIndex) {
          canvas.drawCircle(
            currentPoints[i],
            2,
            Paint()
              ..color = (isDark ? const Color(0xFF007AFF) : const Color(0xFF0051D5))
                  .withValues(alpha: 0.4),
          );
        }
      }
    }

    // Draw zero line
    if (minValue < 0 && maxValue > 0) {
      final zeroY = size.height - ((0 - minValue) / valueRange * size.height);
      final zeroPaint = Paint()
        ..color = isDark 
            ? Colors.white.withValues(alpha: 0.2) 
            : Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      final dashPath = Path();
      dashPath.moveTo(0, zeroY);
      dashPath.lineTo(size.width, zeroY);
      
      canvas.drawPath(
        dashPath,
        zeroPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ModernSparklinePainter oldDelegate) {
    return oldDelegate.currentMonthData != currentMonthData ||
           oldDelegate.lastMonthData != lastMonthData ||
           oldDelegate.minValue != minValue ||
           oldDelegate.maxValue != maxValue ||
           oldDelegate.isDark != isDark;
  }
}


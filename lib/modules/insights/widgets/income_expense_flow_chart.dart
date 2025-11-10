import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';

/// Income & Expense Flow Chart
/// Shows income and expense trends over time
class IncomeExpenseFlowChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;

  const IncomeExpenseFlowChart({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<UnifiedProviderV2, ThemeProvider>(
      builder: (context, dataProvider, themeProvider, child) {
        final currency = themeProvider.currency;
        // Get transactions in date range
        final transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();

        // Check if we have any transactions at all
        if (transactions.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Calculate daily income and expense
        final daysDifference = endDate.difference(startDate).inDays;
        final dailyData = _calculateDailyData(transactions, startDate, endDate, daysDifference);

        // Check if we have meaningful data (at least some income or expense)
        final hasIncomeOrExpense = dailyData.any((e) => 
          (e['income'] as double) > 0 || (e['expense'] as double) > 0
        );

        if (!hasIncomeOrExpense || dailyData.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Calculate max value for Y axis
        final maxValue = dailyData.map((e) => [e['income'], e['expense']])
            .expand((e) => e)
            .reduce((a, b) => a > b ? a : b);
        // Ensure yAxisMax is at least 1.0 to prevent horizontalInterval from being 0
        final yAxisMax = ((maxValue * 1.2).ceilToDouble()).clamp(1.0, double.infinity);

        // Prepare line chart spots
        final incomeSpots = dailyData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['income'] as double);
        }).toList();

        final expenseSpots = dailyData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['expense'] as double);
        }).toList();

        // Calculate dynamic interval based on period length
        final maxLabels = 8; // Maximum number of labels to show
        final interval = (daysDifference / maxLabels).ceil().clamp(1, daysDifference);
        
        // Get X axis labels with dynamic interval
        final xAxisLabels = dailyData.map((e) => e['label'] as String).toList();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and subtitle
              Text(
                l10n.incomeExpenseFlow ?? 'Gelir & Gider Akışı',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                periodLabel,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Legend
              Row(
                children: [
                  _buildLegendItem(
                    context,
                    isDark,
                    l10n.income,
                    const Color(0xFF4CAF50), // Green
                  ),
                  SizedBox(width: 16.w),
                  _buildLegendItem(
                    context,
                    isDark,
                    l10n.expense,
                    const Color(0xFFFF4C4C), // Red
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Chart
              SizedBox(
                height: 220.h,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      // Ensure horizontalInterval is never zero (minimum 1.0)
                      horizontalInterval: (yAxisMax / 4).clamp(1.0, double.infinity),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          strokeWidth: 1,
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
                          reservedSize: daysDifference > 30 ? 45 : 35,
                          interval: interval.toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < xAxisLabels.length) {
                              // Always show first and last labels, and labels at intervals
                              final isFirst = index == 0;
                              final isLast = index == xAxisLabels.length - 1;
                              final isAtInterval = (index % interval) == 0;
                              
                              if (!isFirst && !isLast && !isAtInterval) {
                                return const Text('');
                              }
                              
                              final label = xAxisLabels[index];
                              // Rotate labels for longer periods to avoid overlap
                              final shouldRotate = daysDifference > 30;
                              
                              return Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: shouldRotate
                                    ? Transform.rotate(
                                        angle: -0.5,
                                        alignment: Alignment.center,
                                        child: Text(
                                          label,
                                          style: GoogleFonts.inter(
                                            fontSize: daysDifference > 60 ? 9.sp : 10.sp,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          // Ensure interval is never zero (minimum 1.0)
                          interval: (yAxisMax / 4).clamp(1.0, double.infinity),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              CurrencyUtils.formatAmountWithoutSymbol(value, currency),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                        left: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                    minX: 0,
                    maxX: (dailyData.length - 1).toDouble(),
                    minY: 0,
                    maxY: yAxisMax,
                    lineBarsData: [
                      // Income line
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        color: const Color(0xFF4CAF50),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                        ),
                      ),
                      // Expense line
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: const Color(0xFFFF4C4C),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFF4C4C).withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: isDark 
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8.w),
                        tooltipMargin: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            if (index >= 0 && index < dailyData.length) {
                              final data = dailyData[index];
                              final isIncome = touchedSpot.barIndex == 0;
                              return LineTooltipItem(
                                '${isIncome ? l10n.income : l10n.expense}: ${CurrencyUtils.formatAmount(touchedSpot.y, currency)}',
                                GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isIncome 
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF4C4C),
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _calculateDailyData(
    List<TransactionWithDetailsV2> transactions,
    DateTime startDate,
    DateTime endDate,
    int daysDifference,
  ) {
    final Map<DateTime, Map<String, double>> dailyMap = {};
    
    // Initialize all days in range with 0
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      dailyMap[currentDate] = {'income': 0.0, 'expense': 0.0};
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Add transaction amounts
    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      
      if (dailyMap.containsKey(transactionDate)) {
        if (transaction.type == TransactionType.income) {
          dailyMap[transactionDate]!['income'] = 
              (dailyMap[transactionDate]!['income'] ?? 0.0) + transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          dailyMap[transactionDate]!['expense'] = 
              (dailyMap[transactionDate]!['expense'] ?? 0.0) + transaction.amount;
        }
      }
    }
    
    // Convert to list with labels
    return dailyMap.entries.map((entry) {
      return {
        'date': entry.key,
        'income': entry.value['income']!,
        'expense': entry.value['expense']!,
        'label': _getDateLabel(entry.key, daysDifference),
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  String _getDateLabel(DateTime date, int daysDifference) {
    if (daysDifference <= 7) {
      // For 7 days or less: Show day name (Paz, Pzt, etc.)
      final days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return days[date.weekday % 7];
    } else if (daysDifference <= 30) {
      // For up to 30 days: Show day and month (DD/MM)
      return '${date.day}/${date.month}';
    } else if (daysDifference <= 90) {
      // For up to 90 days: Show day and month (DD/MM) but more compact
      return '${date.day}/${date.month}';
    } else if (daysDifference <= 365) {
      // For up to 1 year: Show month abbreviation (Oca, Şub, etc.)
      final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 
                      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return months[date.month - 1];
    } else {
      // For more than 1 year: Show month and year (MM/YYYY)
      return '${date.month}/${date.year}';
    }
  }

  Widget _buildLegendItem(
    BuildContext context,
    bool isDark,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
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
            l10n.incomeExpenseFlow ?? 'Gelir & Gider Akışı',
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
}


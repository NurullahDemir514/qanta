import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';

/// Income & Expense Comparison Chart
/// Compares income and expense between two periods
class IncomeExpenseComparisonChart extends StatelessWidget {
  final DateTime period1Start;
  final DateTime period1End;
  final String period1Label;
  final DateTime period2Start;
  final DateTime period2End;
  final String period2Label;

  const IncomeExpenseComparisonChart({
    super.key,
    required this.period1Start,
    required this.period1End,
    required this.period1Label,
    required this.period2Start,
    required this.period2End,
    required this.period2Label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<UnifiedProviderV2, ThemeProvider>(
      builder: (context, dataProvider, themeProvider, child) {
        final currency = themeProvider.currency;
        
        // Get transactions for period 1
        final period1Transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(period1Start.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(period1End.add(const Duration(days: 1))) &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();
        
        // Get transactions for period 2
        final period2Transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(period2Start.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(period2End.add(const Duration(days: 1))) &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();
        
        // Calculate totals
        final period1Income = period1Transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final period1Expense = period1Transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final period2Income = period2Transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final period2Expense = period2Transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final maxValue = [period1Income, period1Expense, period2Income, period2Expense]
            .reduce((a, b) => a > b ? a : b);
        final yAxisMax = (maxValue * 1.2).ceilToDouble();
        
        if (maxValue == 0) {
          return _buildEmptyState(context, isDark, l10n);
        }
        
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
                l10n.incomeExpenseComparison ?? 'Gelir & Gider Karşılaştırması',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$period1Label vs $period2Label',
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
                    period1Label,
                    const Color(0xFF9C27B0), // Purple
                  ),
                  SizedBox(width: 16.w),
                  _buildLegendItem(
                    context,
                    isDark,
                    period2Label,
                    const Color(0xFF6D6D70), // Gray
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Chart
              SizedBox(
                height: 220.h,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: yAxisMax,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: isDark 
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8.w),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final period = groupIndex == 0 ? period1Label : period2Label;
                          final isIncome = rodIndex == 0;
                          final value = rod.toY;
                          return BarTooltipItem(
                            '${isIncome ? l10n.income : l10n.expense}\n'
                            '$period: ${CurrencyUtils.formatAmount(value, currency)}',
                            GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isIncome 
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF4C4C),
                            ),
                          );
                        },
                      ),
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
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() == 0) {
                              return Text(
                                l10n.income,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              );
                            } else if (value.toInt() == 1) {
                              return Text(
                                l10n.expense,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: isDark ? Colors.white70 : Colors.black54,
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
                          interval: yAxisMax / 4,
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yAxisMax / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
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
                    barGroups: [
                      // Income - Period 1 and Period 2 side by side
                      BarChartGroupData(
                        x: 0,
                        groupVertically: true,
                        barRods: [
                          BarChartRodData(
                            toY: period1Income,
                            color: const Color(0xFF9C27B0), // Purple for period 1
                            width: 20.w,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: period2Income,
                            color: const Color(0xFF6D6D70), // Gray for period 2
                            width: 20.w,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                      // Expense - Period 1 and Period 2 side by side
                      BarChartGroupData(
                        x: 1,
                        groupVertically: true,
                        barRods: [
                          BarChartRodData(
                            toY: period1Expense,
                            color: const Color(0xFF9C27B0), // Purple for period 1
                            width: 20.w,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: period2Expense,
                            color: const Color(0xFF6D6D70), // Gray for period 2
                            width: 20.w,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            l10n.incomeExpenseComparison ?? 'Gelir & Gider Karşılaştırması',
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


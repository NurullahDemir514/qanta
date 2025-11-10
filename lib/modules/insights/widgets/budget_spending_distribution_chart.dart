import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:math' as math;

/// Budget & Spending Distribution Chart
/// Shows scatter plot of budget vs spending by category
class BudgetSpendingDistributionChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const BudgetSpendingDistributionChart({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<UnifiedProviderV2, ThemeProvider>(
      builder: (context, dataProvider, themeProvider, child) {
        final currency = themeProvider.currency;
        // Get budgets for the period
        final budgets = dataProvider.budgets.where((budget) {
          // Check if budget period overlaps with selected period
          return budget.startDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 budget.endDate.isAfter(startDate.subtract(const Duration(days: 1)));
        }).toList();

        if (budgets.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Get expense transactions in date range
        final transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 t.type == TransactionType.expense &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();

        // Calculate spending per category
        final categorySpending = <String, double>{};
        for (final transaction in transactions) {
          final categoryId = transaction.categoryId ?? '';
          if (categoryId.isNotEmpty) {
            categorySpending[categoryId] = 
                (categorySpending[categoryId] ?? 0.0) + transaction.amount;
          }
        }

        // Prepare scatter plot data
        final scatterData = <Map<String, dynamic>>[];
        final categoryColors = <String, Color>{};
        final categoryNames = <String, String>{};
        final colors = [
          const Color(0xFFFF9500), // Orange - Market
          const Color(0xFFFF4C4C), // Red - Faturalar
          const Color(0xFF007AFF), // Blue - Ulaşım
          const Color(0xFF4CAF50), // Green - Eğlence
          const Color(0xFF9C27B0), // Purple
          const Color(0xFFFFC300), // Amber
          const Color(0xFF00C2FF), // Cyan
        ];
        int colorIndex = 0;

        for (final budget in budgets) {
          final spending = categorySpending[budget.categoryId] ?? 0.0;
          
          // Only show categories with budget > 0
          if (budget.limit > 0) {
            final categoryId = budget.categoryId;
            if (!categoryColors.containsKey(categoryId)) {
              categoryColors[categoryId] = colors[colorIndex % colors.length];
              categoryNames[categoryId] = budget.categoryName;
              colorIndex++;
            }
            
            scatterData.add({
              'budget': budget.limit,
              'spending': spending,
              'categoryId': categoryId,
              'categoryName': budget.categoryName,
              'color': categoryColors[categoryId],
            });
          }
        }

        if (scatterData.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Calculate axis ranges
        final maxBudget = scatterData.map((e) => e['budget'] as double)
            .reduce((a, b) => a > b ? a : b);
        final maxSpending = scatterData.map((e) => e['spending'] as double)
            .reduce((a, b) => a > b ? a : b);
        final maxAxis = math.max(maxBudget, maxSpending) * 1.2;

        // Group by category for legend
        final categoryGroups = <String, List<Map<String, dynamic>>>{};
        for (final data in scatterData) {
          final categoryId = data['categoryId'] as String;
          categoryGroups.putIfAbsent(categoryId, () => []).add(data);
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
              // Title
              Text(
                l10n.budgetSpendingDistribution ?? 'Bütçe ve Harcama Dağılımı',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Legend
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                children: categoryGroups.entries.map((entry) {
                  final categoryId = entry.key;
                  final firstData = entry.value.first;
                  final color = firstData['color'] as Color;
                  final categoryName = firstData['categoryName'] as String;
                  
                  return _buildLegendItem(
                    context,
                    isDark,
                    categoryName,
                    color,
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),
              
              // Chart
              SizedBox(
                height: 300.h,
                child: ScatterChart(
                  ScatterChartData(
                    scatterSpots: scatterData.map((data) {
                      return ScatterSpot(
                        data['budget'] as double,
                        data['spending'] as double,
                      );
                    }).toList(),
                    minX: 0,
                    maxX: maxAxis,
                    minY: 0,
                    maxY: maxAxis,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: maxAxis / 5,
                      verticalInterval: maxAxis / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
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
                          reservedSize: 24,
                          interval: maxAxis / 5,
                          getTitlesWidget: (value, meta) {
                            // Format as k (thousands)
                            final formatted = _formatAxisValue(value);
                            return Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Transform.rotate(
                                angle: -0.4, // Rotate labels
                                child: Text(
                                  formatted,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        axisNameWidget: Padding(
                          padding: EdgeInsets.only(top: 0),
                          child: Text(
                            '${l10n.budget ?? 'Bütçe'} (${CurrencyUtils.getSymbolForCurrency(currency)})',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? Colors.white.withOpacity(0.87) 
                                  : Colors.black.withOpacity(0.87),
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: maxAxis / 5,
                          getTitlesWidget: (value, meta) {
                            final formatted = _formatAxisValue(value);
                            return Padding(
                              padding: EdgeInsets.only(right: 4.w),
                              child: Text(
                                formatted,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                        axisNameWidget: Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: Center(
                            child: Text(
                              '${l10n.spending ?? 'Harcama'} (${CurrencyUtils.getSymbolForCurrency(currency)})',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.white.withOpacity(0.87) 
                                    : Colors.black.withOpacity(0.87),
                              ),
                            ),
                          ),
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
                    scatterTouchData: ScatterTouchData(
                      enabled: true,
                      touchTooltipData: ScatterTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8.w),
                        getTooltipItems: (ScatterSpot touchedSpot) {
                          // Find the data point
                          final dataPoint = scatterData.firstWhere(
                            (data) => 
                                ((data['budget'] as double) - touchedSpot.x).abs() < 0.01 &&
                                ((data['spending'] as double) - touchedSpot.y).abs() < 0.01,
                            orElse: () => scatterData.first,
                          );
                          
                          return ScatterTooltipItem(
                            '${dataPoint['categoryName'] as String}\n'
                            '${l10n.budget ?? 'Bütçe'}: ${CurrencyUtils.formatAmount(dataPoint['budget'] as double, currency)}\n'
                            '${l10n.spending ?? 'Harcama'}: ${CurrencyUtils.formatAmount(dataPoint['spending'] as double, currency)}',
                          );
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

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildLegendItem(
    BuildContext context,
    bool isDark,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
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
            l10n.budgetSpendingDistribution ?? 'Bütçe ve Harcama Dağılımı',
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


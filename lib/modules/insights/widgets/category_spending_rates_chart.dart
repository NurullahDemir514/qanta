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

/// Category Spending Rates Chart
/// Shows spending trends by category over time
class CategorySpendingRatesChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CategorySpendingRatesChart({
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
        
        // Get transactions in date range
        final transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 t.type == TransactionType.expense &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();

        // Group by category and date
        final categoryDailySpending = <String, Map<DateTime, double>>{};
        final categoryNames = <String, String>{};
        final categoryColors = <String, Color>{};

        for (final transaction in transactions) {
          final categoryId = transaction.categoryId ?? '';
          if (categoryId.isEmpty) continue;

          final categoryName = transaction.categoryName ?? 'Diğer';
          categoryNames[categoryId] = categoryName;
          
          // Assign color if not already assigned
          if (!categoryColors.containsKey(categoryId)) {
            categoryColors[categoryId] = _getCategoryColor(
              categoryColors.length,
              categoryName,
            );
          }

          final transactionDate = DateTime(
            transaction.transactionDate.year,
            transaction.transactionDate.month,
            transaction.transactionDate.day,
          );

          if (!categoryDailySpending.containsKey(categoryId)) {
            categoryDailySpending[categoryId] = {};
          }

          categoryDailySpending[categoryId]![transactionDate] = 
              (categoryDailySpending[categoryId]![transactionDate] ?? 0.0) + transaction.amount;
        }

        if (categoryDailySpending.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Get top 3 categories by total spending
        final categoryTotals = categoryDailySpending.entries.map((entry) {
          final total = entry.value.values.fold(0.0, (sum, amount) => sum + amount);
          return MapEntry(entry.key, total);
        }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topCategories = categoryTotals.take(3).map((e) => e.key).toList();

        // Calculate daily data
        final daysDifference = endDate.difference(startDate).inDays;
        final dailyData = _calculateDailyData(
          categoryDailySpending,
          topCategories,
          startDate,
          endDate,
          daysDifference,
        );

        if (dailyData.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Calculate max value for Y axis
        final maxValue = dailyData.map((e) {
          return topCategories.map((catId) => e[catId] ?? 0.0).toList();
        }).expand((e) => e).reduce((a, b) => a > b ? a : b);
        
        final yAxisMax = (maxValue * 1.2).ceilToDouble().clamp(50.0, double.infinity);

        // Prepare line chart spots for each category
        final categorySpots = <String, List<FlSpot>>{};
        for (final categoryId in topCategories) {
          final spots = dailyData.asMap().entries.map((entry) {
            final index = entry.key;
            final spending = entry.value[categoryId] ?? 0.0;
            return FlSpot(index.toDouble(), spending);
          }).toList();
          categorySpots[categoryId] = spots;
        }

        // Get X axis labels
        final xAxisLabels = dailyData.map((e) => e['label'] as String).toList();
        final maxLabels = 8;
        final interval = (daysDifference / maxLabels).ceil().clamp(1, daysDifference);

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
                'Kategori Harcama Oranları',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Legend
              Wrap(
                spacing: 16.w,
                runSpacing: 8.h,
                children: topCategories.map((categoryId) {
                  final categoryName = categoryNames[categoryId] ?? 'Diğer';
                  final color = categoryColors[categoryId] ?? Colors.grey;
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
                height: 220.h,
                child: LineChart(
                  LineChartData(
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
                              final isFirst = index == 0;
                              final isLast = index == xAxisLabels.length - 1;
                              final isAtInterval = (index % interval) == 0;
                              
                              if (!isFirst && !isLast && !isAtInterval) {
                                return const Text('');
                              }
                              
                              final label = xAxisLabels[index];
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
                    lineBarsData: topCategories.map((categoryId) {
                      final color = categoryColors[categoryId] ?? Colors.grey;
                      final spots = categorySpots[categoryId] ?? [];
                      return LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      );
                    }).toList(),
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
                              final categoryId = topCategories[touchedSpot.barIndex];
                              final categoryName = categoryNames[categoryId] ?? 'Diğer';
                              final spending = touchedSpot.y;
                              final color = categoryColors[categoryId] ?? Colors.grey;
                              return LineTooltipItem(
                                '$categoryName: ${CurrencyUtils.formatAmount(spending, currency)}',
                                GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
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
    Map<String, Map<DateTime, double>> categoryDailySpending,
    List<String> topCategories,
    DateTime startDate,
    DateTime endDate,
    int daysDifference,
  ) {
    final Map<DateTime, Map<String, double>> dailyMap = {};
    final Map<DateTime, String> dateLabels = {};
    
    // Initialize all days in range with 0
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      dailyMap[currentDate] = {
        for (final catId in topCategories) catId: 0.0,
      };
      dateLabels[currentDate] = _getDateLabel(currentDate, daysDifference);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Add category spending
    for (final categoryEntry in categoryDailySpending.entries) {
      final categoryId = categoryEntry.key;
      if (!topCategories.contains(categoryId)) continue;
      
      for (final dateEntry in categoryEntry.value.entries) {
        final transactionDate = dateEntry.key;
        final amount = dateEntry.value;
        
        if (dailyMap.containsKey(transactionDate)) {
          dailyMap[transactionDate]![categoryId] = 
              (dailyMap[transactionDate]![categoryId] ?? 0.0) + amount;
        }
      }
    }
    
    return dailyMap.entries.map((entry) {
      final label = dateLabels[entry.key] ?? '';
      return {
        'date': entry.key,
        'label': label,
        for (final catId in topCategories) catId: entry.value[catId] ?? 0.0,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  String _getDateLabel(DateTime date, int daysDifference) {
    if (daysDifference <= 7) {
      final days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return days[date.weekday % 7];
    } else if (daysDifference <= 30) {
      return '${date.day}/${date.month}';
    } else if (daysDifference <= 90) {
      return '${date.day}/${date.month}';
    } else if (daysDifference <= 365) {
      final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 
                      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return months[date.month - 1];
    } else {
      return '${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(int index, String categoryName) {
    // Color scheme: Orange, Red, Blue
    final colors = [
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF4C4C), // Red
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFFC300), // Yellow
    ];
    
    return colors[index % colors.length];
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
            'Kategori Harcama Oranları',
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


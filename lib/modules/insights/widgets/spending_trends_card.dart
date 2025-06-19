import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../models/statistics_model.dart';

class SpendingTrendsCard extends StatelessWidget {
  final StatisticsData statistics;
  final TimePeriod period;

  const SpendingTrendsCard({
    super.key,
    required this.statistics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (statistics.monthlyTrends.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              l10n.spendingTrends,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Simple Bar Chart
            _buildSimpleChart(context),
            
            const SizedBox(height: 20),
            
            // Monthly Trend List
            ...statistics.monthlyTrends.take(6).map((trend) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTrendItem(context, trend),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trends = statistics.monthlyTrends.take(6).toList();
    
    if (trends.isEmpty) return const SizedBox.shrink();

    // Find max value for scaling
    final maxExpense = trends.map((t) => t.expenses).reduce((a, b) => a > b ? a : b);
    if (maxExpense == 0) return const SizedBox.shrink();

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trends.map((trend) {
          final height = (trend.expenses / maxExpense) * 80;
          final monthName = _getMonthName(trend.monthYear);
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bar
                  Container(
                    height: height.clamp(4.0, 80.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Month label
                  Text(
                    monthName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, MonthlyTrend trend) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final monthName = _getMonthName(trend.monthYear);
    
    // Calculate trend indicators
    final isPositive = trend.netBalance >= 0;
    final trendColor = isPositive 
      ? const Color(0xFF00FFB3)
      : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF38383A)
            : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Month Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trend.transactionCount} işlem',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Income/Expense
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: const Color(0xFF00FFB3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatter.format(trend.income),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00FFB3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 12,
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatter.format(trend.expenses),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Net Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  formatter.format(trend.netBalance.abs()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.spendingTrends,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.trending_up,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noDataAvailable,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(String monthYear) {
    try {
      final parts = monthYear.split('-');
      if (parts.length != 2) return monthYear;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      final date = DateTime(year, month);
      return DateFormat('MMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      return monthYear;
    }
  }
} 
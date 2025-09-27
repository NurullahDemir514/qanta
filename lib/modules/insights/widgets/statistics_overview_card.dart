import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/statistics_model.dart';

class StatisticsOverviewCard extends StatelessWidget {
  final StatisticsData statistics;
  final TimePeriod period;

  const StatisticsOverviewCard({
    super.key,
    required this.statistics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              l10n.monthlyOverview,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Main Metrics Grid
            Column(
              children: [
                // Income and Expenses Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        l10n.totalIncome,
                        statistics.totalIncome,
                        const Color(0xFF00FFB3),
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        l10n.totalExpenses,
                        statistics.totalExpenses,
                        const Color(0xFFFF6B6B),
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Net Balance Row
                _buildMetricCard(
                  context,
                  l10n.netBalance,
                  statistics.netBalance,
                  statistics.netBalance >= 0 
                    ? const Color(0xFF00FFB3)
                    : const Color(0xFFFF6B6B),
                  statistics.netBalance >= 0 
                    ? Icons.account_balance_wallet
                    : Icons.warning,
                  isFullWidth: true,
                ),
                
                const SizedBox(height: 20),
                
                // Additional Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallMetricCard(
                        context,
                        l10n.averageSpending,
                        statistics.averageSpending,
                        const Color(0xFF4ECDC4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallMetricCard(
                        context,
                        l10n.savingsRate,
                        statistics.savingsRate,
                        const Color(0xFF45B7D1),
                        isPercentage: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Transaction Count
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${statistics.totalTransactions} işlem',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(statistics.startDate),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ' - ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(statistics.endDate),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    final formatter = NumberFormat.currency(locale: currency.locale, symbol: currency.symbol);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount.abs()),
            style: GoogleFonts.inter(
              fontSize: isFullWidth ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(
    BuildContext context,
    String title,
    double value,
    Color color, {
    bool isPercentage = false,
  }) {
    final formatter = isPercentage 
      ? NumberFormat('#0.0')
      : NumberFormat.currency(locale: currency.locale, symbol: currency.symbol);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPercentage 
              ? '${formatter.format(value)}%'
              : formatter.format(value.abs()),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 
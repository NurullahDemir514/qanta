import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/statistics_model.dart';

class CategoryBreakdownCard extends StatelessWidget {
  final StatisticsData statistics;
  final TimePeriod period;

  const CategoryBreakdownCard({
    super.key,
    required this.statistics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (statistics.categoryBreakdown.isEmpty) {
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
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              l10n.categoryBreakdown,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 20),

            // Category List
            ...statistics.categoryBreakdown.take(8).map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCategoryItem(context, category),
              );
            }),

            // Show more indicator if there are more categories
            if (statistics.categoryBreakdown.length > 8)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${statistics.categoryBreakdown.length - 8} daha fazla kategori',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildCategoryItem(BuildContext context, CategoryStatistic category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).currency;
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
    );

    // Generate a color based on category name
    final color = _getCategoryColor(category.categoryId);

    return Row(
      children: [
        // Category Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category.categoryIcon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Category Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.categoryName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${category.transactionCount} işlem',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Amount and Percentage
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(category.amount),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
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
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.categoryBreakdown,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.pie_chart_outline,
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

  Color _getCategoryColor(String categoryId) {
    // Generate consistent colors based on category ID
    final colors = [
      const Color(0xFF00FFB3), // Primary mint
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFF45B7D1), // Blue
      const Color(0xFF96CEB4), // Light green
      const Color(0xFFFECE4A), // Yellow
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFBB6BD9), // Purple
      const Color(0xFFFF8E53), // Orange
      const Color(0xFF6C5CE7), // Indigo
      const Color(0xFFA29BFE), // Light purple
    ];

    final index = categoryId.hashCode.abs() % colors.length;
    return colors[index];
  }
}

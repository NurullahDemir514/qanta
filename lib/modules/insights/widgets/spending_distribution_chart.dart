import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';

/// Spending Distribution Chart (Treemap-like visualization)
/// Shows spending distribution by category as proportional boxes
class SpendingDistributionChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SpendingDistributionChart({
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

        // Calculate spending by category
        final categorySpending = <String, double>{};
        final categoryNames = <String, String>{};
        
        for (final transaction in transactions) {
          final categoryId = transaction.categoryId ?? '';
          if (categoryId.isNotEmpty) {
            categorySpending[categoryId] = (categorySpending[categoryId] ?? 0.0) + transaction.amount;
            categoryNames[categoryId] = transaction.categoryName ?? 'Diğer';
          }
        }

        if (categorySpending.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Sort by spending amount (descending)
        final sortedCategories = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Limit to max categories, combine rest into "Diğer"
        const maxCategories = 6; // Maximum number of categories to show
        final displayCategories = <MapEntry<String, double>>[];
        double otherTotal = 0.0;
        
        if (sortedCategories.length > maxCategories) {
          // Take first maxCategories-1 categories
          displayCategories.addAll(sortedCategories.take(maxCategories - 1));
          // Combine rest into "Diğer"
          otherTotal = sortedCategories.skip(maxCategories - 1)
              .fold(0.0, (sum, entry) => sum + entry.value);
          if (otherTotal > 0) {
            displayCategories.add(MapEntry('other', otherTotal));
            categoryNames['other'] = 'Diğer';
          }
        } else {
          displayCategories.addAll(sortedCategories);
        }

        // Calculate total spending
        final totalSpending = displayCategories.fold(0.0, (sum, entry) => sum + entry.value);

        // Get category colors
        final categoryColors = _getCategoryColors(displayCategories.length, isDark);

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
                'Harcama Dağılımı',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Treemap grid
              _buildTreemap(
                context,
                displayCategories,
                categoryNames,
                categoryColors,
                totalSpending,
                isDark,
                currency,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreemap(
    BuildContext context,
    List<MapEntry<String, double>> categories,
    Map<String, String> categoryNames,
    List<Color> colors,
    double totalSpending,
    bool isDark,
    Currency currency,
  ) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate proportional sizes for treemap
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final categoryName = categoryNames[category.key] ?? 'Diğer';
      final spending = category.value;
      final percentage = (spending / totalSpending) * 100;
      
      // "Diğer" kategorisi için en açık kırmızı tonu kullan
      final color = category.key == 'other' 
          ? const Color(0xFFFEE2E2) // Lightest red for "Diğer"
          : colors[i % colors.length];

      items.add({
        'categoryName': categoryName,
        'spending': spending,
        'percentage': percentage,
        'color': color,
      });
    }

    // Build simple 2-column treemap with proportional heights
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final spacing = 4.0.w;
        final columnWidth = (availableWidth - spacing) / 2;
        
        // Fixed height to prevent overflow
        const fixedHeight = 280.0;
        
        // Group items into two columns (alternating)
        final leftColumn = <Map<String, dynamic>>[];
        final rightColumn = <Map<String, dynamic>>[];
        
        for (int i = 0; i < items.length; i++) {
          if (i % 2 == 0) {
            leftColumn.add(items[i]);
          } else {
            rightColumn.add(items[i]);
          }
        }
        
        // Calculate column heights based on total spending in each column
        final leftTotal = leftColumn.fold(0.0, (sum, item) => sum + (item['spending'] as double));
        final rightTotal = rightColumn.fold(0.0, (sum, item) => sum + (item['spending'] as double));
        final maxColumnTotal = leftTotal > rightTotal ? leftTotal : rightTotal;
        
        // Use fixed height, distribute proportionally
        final leftColumnHeight = maxColumnTotal > 0 && leftTotal > 0 
            ? (leftTotal / maxColumnTotal) * fixedHeight 
            : fixedHeight;
        final rightColumnHeight = maxColumnTotal > 0 && rightTotal > 0 
            ? (rightTotal / maxColumnTotal) * fixedHeight 
            : fixedHeight;
        
        return SizedBox(
          height: fixedHeight.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: SizedBox(
                  height: leftColumnHeight.h,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildColumnItems(
                      leftColumn,
                      columnWidth,
                      leftColumnHeight.h,
                      spacing,
                      currency,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              // Right column
              Expanded(
                child: SizedBox(
                  height: rightColumnHeight.h,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildColumnItems(
                      rightColumn,
                      columnWidth,
                      rightColumnHeight.h,
                      spacing,
                      currency,
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

  List<Widget> _buildColumnItems(
    List<Map<String, dynamic>> items,
    double columnWidth,
    double columnHeight,
    double spacing,
    Currency currency,
  ) {
    if (items.isEmpty) return [];
    
    final totalSpending = items.fold(0.0, (sum, item) => sum + (item['spending'] as double));
    final widgets = <Widget>[];
    
    // Calculate total spacing used
    final totalSpacing = spacing * (items.length - 1);
    final availableHeight = columnHeight - totalSpacing;
    
    // Calculate heights proportionally
    final itemHeights = <double>[];
    double totalCalculatedHeight = 0.0;
    
    for (final item in items) {
      final spending = item['spending'] as double;
      final percentage = totalSpending > 0 ? (spending / totalSpending) : 0.0;
      final calculatedHeight = (percentage * availableHeight).clamp(50.0.h, double.infinity);
      itemHeights.add(calculatedHeight);
      totalCalculatedHeight += calculatedHeight;
    }
    
    // Normalize heights if they exceed available space
    if (totalCalculatedHeight > availableHeight) {
      final scaleFactor = availableHeight / totalCalculatedHeight;
      for (int i = 0; i < itemHeights.length; i++) {
        itemHeights[i] = itemHeights[i] * scaleFactor;
      }
    }
    
    // Build widgets with calculated heights
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final spending = item['spending'] as double;
      final itemHeight = itemHeights[i];
      
      widgets.add(
        Container(
          width: columnWidth,
          height: itemHeight,
          margin: EdgeInsets.only(bottom: i < items.length - 1 ? spacing : 0),
          decoration: BoxDecoration(
            color: item['color'] as Color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['categoryName'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (itemHeight > 60.h) ...[
                SizedBox(height: 4.h),
                Text(
                  CurrencyUtils.formatAmount(spending, currency),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }


  List<Color> _getCategoryColors(int count, bool isDark) {
    // Red shades - professional red palette
    final baseColors = [
      const Color(0xFFB91C1C), // Dark red
      const Color(0xFFDC2626), // Medium-dark red
      const Color(0xFFEF4444), // Medium red
      const Color(0xFFF87171), // Light red
      const Color(0xFFFCA5A5), // Lighter red
      const Color(0xFFFECACA), // Very light red
      const Color(0xFFFEE2E2), // Lightest red
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }

    return colors;
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
            'Harcama Dağılımı',
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


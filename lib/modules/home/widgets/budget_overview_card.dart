import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';

class BudgetOverviewCard extends StatefulWidget {
  const BudgetOverviewCard({super.key});

  @override
  State<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<BudgetOverviewCard> {
  // Uyarı bildirimi cooldown sistemi
  final Map<String, DateTime> _lastAlertTimes = {};
  static const Duration _alertCooldown = Duration(
    minutes: 5,
  ); // 5 dakika cooldown

  @override
  void initState() {
    super.initState();
  }

  /// Get localized period name
  String _getLocalizedPeriodName(BudgetPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    switch (period) {
      case BudgetPeriod.weekly:
        return l10n.weekly;
      case BudgetPeriod.monthly:
        return l10n.monthly;
      case BudgetPeriod.yearly:
        return l10n.yearly;
    }
  }

  /// Format date range for budget duration with clear calculation info
  String _formatDateRange(DateTime startDate, DateTime endDate, BudgetPeriod period) {
    final locale = Localizations.localeOf(context);
    final startFormatter = DateFormat('dd MMM', locale.toString());
    final endFormatter = DateFormat('dd MMM', locale.toString());
    
    // Calculate duration in days
    final durationInDays = endDate.difference(startDate).inDays;
    
    // Format based on period type
    switch (period) {
      case BudgetPeriod.weekly:
        return '${startFormatter.format(startDate)} - ${endFormatter.format(endDate)} ($durationInDays gün)';
      case BudgetPeriod.monthly:
        return '${startFormatter.format(startDate)} - ${endFormatter.format(endDate)} ($durationInDays gün)';
      case BudgetPeriod.yearly:
        return '${startFormatter.format(startDate)} - ${endFormatter.format(endDate)} ($durationInDays gün)';
    }
  }

  /// Calculate budget stats from current budgets
  List<BudgetCategoryStats> _calculateBudgetStats(List<BudgetModel> budgets) {
    return budgets.map((budget) {
      final percentage = budget.limit > 0
          ? (budget.spentAmount / budget.limit) * 100
          : 0.0;
      final isOverBudget = budget.spentAmount > budget.limit;

      // Get localized category name
      final localizedCategoryName = CategoryIconService.getLocalizedCategoryName(budget.categoryName, context);

      return BudgetCategoryStats(
        categoryId: budget.categoryId,
        categoryName: localizedCategoryName, // Use localized name
        limit: budget.limit,
        period: budget.period,
        currentSpent: budget.spentAmount,
        transactionCount: 0, // Will be calculated separately if needed
        percentage: percentage,
        isOverBudget: isOverBudget,
        isRecurring: budget.isRecurring,
        startDate: budget.startDate,
      );
    }).toList();
  }

  Widget _buildEmptyStateWithAddButton(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Balanced Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: const Color(0xFFE74C3C),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Balanced Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.noBudgetDefined,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Balanced CTA Button
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showAddBudgetBottomSheet(context),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.add,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        // Get current month budgets from provider
        final currentBudgets = provider.currentMonthBudgets;

        // Show empty state if no budgets - but still show the header with add button
        if (currentBudgets.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.expenseLimitTracking,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showBudgetManagement(context),
                    child: Text(
                      l10n.manage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6D6D70),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Empty state with add button
              _buildEmptyStateWithAddButton(context, isDark),
            ],
          );
        }

        // Calculate budget stats from current budgets
        final budgetStats = _calculateBudgetStats(currentBudgets);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.expenseLimitTracking,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBudgetManagement(context),
                  child: Text(
                    l10n.manage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6D6D70),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Horizontal scroll cards
            SizedBox(
              height: 90.h, // Increased height
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: budgetStats.length,
                itemBuilder: (context, index) => _buildBudgetCard(
                  budgetStats[index],
                  isDark,
                  index,
                  budgetStats.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BudgetCategoryStats stat,
    bool isDark,
    int index,
    int totalCount,
  ) {
    return Container(
      width: 180.w,
      height: 100.h, // Increased height
      margin: EdgeInsets.only(right: index == (totalCount - 1) ? 0 : 12.w),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1.w,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(stat.categoryName).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.w), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category name and icon with period badge
                Row(
                  children: [
                    Container(
                      width: 24.w, // Reduced size
                      height: 24.w, // Reduced size
                      decoration: BoxDecoration(
                        color: _getCategoryColor(stat.categoryName).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r), // Reduced radius
                      ),
                      child: Icon(
                        _getCategoryIcon(stat.categoryName),
                        size: 12.w, // Reduced icon size
                        color: _getCategoryColor(stat.categoryName),
                      ),
                    ),
                    SizedBox(width: 6.w), // Reduced spacing
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.categoryName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp, // Increased font size
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 4.w), // Responsive margin
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h), // Responsive padding
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(stat.categoryName).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3.r), // Reduced radius
                                ),
                                child: Text(
                                  _getLocalizedPeriodName(stat.period),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp, // Increased font size
                                    fontWeight: FontWeight.w500,
                                    color: _getCategoryColor(stat.categoryName),
                                  ),
                                ),
                              ),
                              if (stat.isRecurring) ...[
                                SizedBox(width: 3.w),
                                Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                  child: Icon(
                                    Icons.repeat,
                                    size: 10.w,
                                    color: const Color(0xFF6D6D70),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Progress bar with percentage
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2.5.h, // Responsive height
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(1.5.r), // Responsive radius
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: stat.progressPercentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: stat.isOverBudget
                                  ? const Color(0xFFFF453A)
                                  : const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(1.5.r), // Responsive radius
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w), // Responsive spacing
                    Text(
                      '${stat.percentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp, // Increased font size
                        fontWeight: FontWeight.w600,
                        color: stat.isOverBudget
                            ? const Color(0xFFFF453A)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),


                // Amount info
                Text(
                  '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.currentSpent)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp, // Increased font size
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    return CategoryIconService.getColorFromMap(categoryName.toLowerCase());
  }

  IconData _getCategoryIcon(String categoryName) {
    return CategoryIconService.getIcon(categoryName.toLowerCase());
  }

  void _showBudgetManagement(BuildContext context) {
    context.push('/budget-management');
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    // Navigate to BudgetManagementPage instead of showing modal
    context.push('/budget-management');
  }
}

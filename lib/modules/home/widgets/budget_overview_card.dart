import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

  /// Calculate budget stats from current budgets
  List<BudgetCategoryStats> _calculateBudgetStats(List<BudgetModel> budgets) {
    return budgets.map((budget) {
      final percentage = budget.monthlyLimit > 0
          ? (budget.spentAmount / budget.monthlyLimit) * 100
          : 0.0;
      final isOverBudget = budget.spentAmount > budget.monthlyLimit;

      return BudgetCategoryStats(
        categoryId: budget.categoryId,
        categoryName: budget.categoryName,
        monthlyLimit: budget.monthlyLimit,
        currentSpent: budget.spentAmount,
        transactionCount: 0, // Will be calculated separately if needed
        percentage: percentage,
        isOverBudget: isOverBudget,
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
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF007AFF),
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
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBudgetManagement(context),
                  child: Text(
                    l10n.manage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Horizontal scroll cards
            SizedBox(
              height: 85.h,
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
      width: 170.w,
      height: 85.h,
      margin: EdgeInsets.only(right: index == (totalCount - 1) ? 0 : 8.w),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1.w,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category name and icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        stat.categoryName,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Icon(
                      _getCategoryIcon(stat.categoryName),
                      size: 12.w,
                      color: _getCategoryColor(stat.categoryName),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      stat.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Progress bar
              Container(
                height: 3.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stat.progressPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: stat.isOverBudget
                          ? const Color(0xFFFF453A)
                          : const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 1.h),

              // Amount info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.currentSpent)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.monthlyLimit)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${stat.percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: stat.isOverBudget
                          ? const Color(0xFFFF453A)
                          : const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ],
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

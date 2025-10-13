import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import 'package:provider/provider.dart';
import 'budget_add_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';

class BudgetManagementPage extends StatefulWidget {
  final VoidCallback? onBudgetSaved;

  const BudgetManagementPage({super.key, this.onBudgetSaved});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  final TextEditingController _limitController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;

  BudgetCategoryStats _calculateBudgetStats(BudgetModel budget) {
    final percentage = budget.limit > 0
        ? (budget.spentAmount / budget.limit) * 100
        : 0.0;
    final isOverBudget = budget.spentAmount > budget.limit;

    return BudgetCategoryStats(
      categoryId: budget.categoryId,
      categoryName: budget.categoryName,
      limit: budget.limit,
      period: budget.period,
      currentSpent: budget.spentAmount,
      transactionCount: 0, // Will be calculated separately if needed
      percentage: percentage,
      isOverBudget: isOverBudget,
      isRecurring: budget.isRecurring,
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool _canSave() {
    return _selectedCategoryName != null &&
        _selectedCategoryName!.isNotEmpty &&
        _limitController.text.isNotEmpty;
  }

  Future<void> _saveBudget() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSave()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterCategoryAndLimit),
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);

      final limit = double.tryParse(_limitController.text.replaceAll(',', ''));
      if (limit == null || limit <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.enterValidLimit)),
        );
        return;
      }

      setState(() => _isSaving = true);

      await provider.createBudget(
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        limit: limit,
        period: BudgetPeriod.monthly,
        isRecurring: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.limitSavedSuccessfully)),
        );
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorOccurred}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getPeriodDisplayName(BudgetPeriod period) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isLoading = providerV2.isLoadingBudgets;
        final currentBudgets = providerV2.budgets;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context)!.expenseLimitTracking,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                  )
                : currentBudgets.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: currentBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = currentBudgets[index];
                      final stat = _calculateBudgetStats(budget);
                      return _buildBudgetCard(
                        stat,
                        isDark,
                        index,
                        currentBudgets.length,
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddBudgetBottomSheet(context),
            backgroundColor: const Color(0xFF6D6D70),
            foregroundColor: Colors.white,
            elevation: 8,
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetAddSheet(
        onBudgetSaved: widget.onBudgetSaved,
        onReload: () async {
          // Budget will be reloaded automatically via provider
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple Icon
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              l10n.noDataYet,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle - Açıklama
            Text(
              l10n.budgetManagementDescription,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Simple Add Budget Button
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A),
                borderRadius: BorderRadius.circular(8),
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
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.addNewLimit,
                          style: GoogleFonts.inter(
                            fontSize: 14,
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
      ),
    );
  }

  Widget _buildBudgetCard(
    BudgetCategoryStats stat,
    bool isDark,
    int index,
    int totalCount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0', 'tr_TR');
    final categoryIcon = CategoryIconService.getIcon(
      stat.categoryName.toLowerCase(),
    );
    final categoryColor = CategoryIconService.getColorFromMap(
      stat.categoryName.toLowerCase(),
    );
    final spent = stat.currentSpent;
    final percent = stat.progressPercentage;
    final percentText = (percent * 100).toStringAsFixed(0);
    final remaining = stat.remainingAmount;
    final isOver = stat.isOverBudget;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() {}),
          onTapUp: (_) => setState(() {}),
          onTapCancel: () => setState(() {}),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: EdgeInsets.only(bottom: index == totalCount - 1 ? 0 : 12),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(isDark ? 0.85 : 0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    stat.categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (stat.isRecurring) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_getPeriodDisplayName(stat.period)} ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isOver)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4C4C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.exceeded,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: () => _showDeleteDialog(stat),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              splashRadius: 16,
                              tooltip: AppLocalizations.of(
                                context,
                              )!.deleteLimitTooltip,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percent),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    width: MediaQuery.of(context).size.width * value.clamp(0.0, 1.0),
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isOver
                                          ? const Color(0xFFFF4C4C)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(spent)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                Text(
                                  '$percentText%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isOver
                                        ? const Color(0xFFFF4C4C)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BudgetCategoryStats stat) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        titlePadding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 20.h,
          bottom: 8.h,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 0,
        ),
        actionsPadding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
          top: 8.h,
        ),
        title: Text(
          l10n.deleteLimit,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          l10n.deleteLimitConfirm(stat.categoryName),
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudget(stat);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4C4C),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.delete,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(BudgetCategoryStats stat) async {
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Find the budget by categoryId
      final budget = provider.budgets.firstWhere(
        (b) => b.categoryId == stat.categoryId,
        orElse: () => throw Exception('Budget not found'),
      );
      
      await provider.deleteBudget(budget.id);

      if (mounted) {
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorOccurred}: Limit silinemedi'),
          ),
        );
      }
    }
  }
}
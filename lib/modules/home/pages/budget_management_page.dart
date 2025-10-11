import 'package:flutter/material.dart';
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
  final _limitController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
  }

  /// Calculate budget stats from budget model
  BudgetCategoryStats _calculateBudgetStats(BudgetModel budget) {
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

      await provider.createBudget(
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        monthlyLimit: limit,
      );

      if (mounted) {
        _limitController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.limitSavedSuccessfully)),
        );
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorOccurred}: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        final currentBudgets = provider.currentMonthBudgets;
        final isLoading = provider.isLoadingBudgets;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF000000)
              : const Color(0xFFF2F2F7),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      splashRadius: 24,
                      tooltip: l10n.back,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.limitManagement,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                )
              : currentBudgets.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: const Color(0xFF8E8E93),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noLimitsSetYet,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.setMonthlySpendingLimits,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
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
              child: Stack(
                children: [
                  // Watermark ikon
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Icon(
                      categoryIcon,
                      size: 36,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark
                                ? Colors.black.withOpacity(0.18)
                                : Colors.white.withOpacity(0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                categoryIcon,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat.categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.monthlyLimit} ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.monthlyLimit)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
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
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4C4C),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l10n.exceeded,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
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
                                    size: 16,
                                  ),
                                  splashRadius: 18,
                                  tooltip: AppLocalizations.of(
                                    context,
                                  )!.deleteLimitTooltip,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        // Progress bar
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: percent),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final barWidth =
                                        constraints.maxWidth *
                                        value.clamp(0.0, 1.0);
                                    return Container(
                                      width: double.infinity,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.13),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 900,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            width: barWidth,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isOver
                                                  ? const Color(0xFFFF4C4C)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isOver
                                          ? l10n.limitExceeded
                                          : '${l10n.remaining} ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(remaining)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '%$percentText ${l10n.spent}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              '${l10n.spentAmount} ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            Text(
                              Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).formatAmount(spent),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BudgetCategoryStats stat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteLimit,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteLimitConfirm(stat.categoryName),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // BudgetModel'i bul
              final now = DateTime.now();
              final provider = Provider.of<UnifiedProviderV2>(
                context,
                listen: false,
              );
              final budget = provider.currentMonthBudgets.firstWhere(
                (b) => b.categoryId == stat.categoryId,
                orElse: () => throw Exception('Limit bulunamadı'),
              );
              await _deleteBudget(budget.id);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findRealCategoryId(String categoryName) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'UnifiedCategoryService.getCategoriesWithCache() - Firebase implementation needed',
      );
      final expenseCategories = <Map<String, dynamic>>[];

      // TODO: Implement with Firebase
      debugPrint(
        'UnifiedCategoryService.getCategoriesWithCache() - Firebase implementation needed',
      );
      UnifiedCategoryModel? matchedCategory;

      // TODO: Implement with Firebase
      debugPrint(
        'UnifiedCategoryService.getCategoriesWithCache() - Firebase implementation needed',
      );

      // TODO: Implement with Firebase
      debugPrint(
        'UnifiedCategoryService.getCategoriesWithCache() - Firebase implementation needed',
      );

      setState(() {
        if (matchedCategory != null) {
          _selectedCategoryId = matchedCategory.id;
        } else {
          _selectedCategoryId = categoryName.toLowerCase().replaceAll(' ', '_');
        }
      });
    } catch (e) {
      setState(() {
        _selectedCategoryId = categoryName.toLowerCase().replaceAll(' ', '_');
      });
    }
  }

  Widget _buildAmountInput(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: _limitController.text.isNotEmpty
            ? Border.all(
                color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            Provider.of<ThemeProvider>(context, listen: false).currency.symbol,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.limitAmountHint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          if (_limitController.text.isNotEmpty)
            Text(
              l10n.perMonth,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E8E93),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(String budgetId) async {
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      await provider.deleteBudget(budgetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.limitDeleted)),
        );
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorOccurred}: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }
}

class BudgetCategorySelector extends StatefulWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const BudgetCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<BudgetCategorySelector> createState() => _BudgetCategorySelectorState();
}

class _BudgetCategorySelectorState extends State<BudgetCategorySelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  List<String> _getActiveExpenseCategories(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    return provider.expenseCategories
        .where(
          (cat) => true,
        ) // UnifiedCategoryModel doesn't have isActive, all are active
        .map((cat) => cat.displayName.trim())
        .toSet()
        .toList();
  }

  List<String> _getFilteredSuggestions(BuildContext context) {
    final tags = _getActiveExpenseCategories(context);
    if (_controller.text.isEmpty) return tags;
    return tags
        .where(
          (tag) => tag.toLowerCase().contains(_controller.text.toLowerCase()),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null) {
      _controller.text = widget.selectedCategory!;
    }
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    _controller.text = category;
    _focusNode.unfocus();
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final suggestions = _getFilteredSuggestions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: false,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: l10n.categoryHint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty) {
              widget.onCategorySelected(value);
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _controller.text = value;
              widget.onCategorySelected(value);
              _focusNode.unfocus();
            }
          },
        ),
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((tag) {
                final isSelected =
                    _controller.text.trim().toLowerCase() == tag.toLowerCase();
                final icon = CategoryIconService.getIcon(tag.toLowerCase());
                final color = const Color(0xFFFF4C4C);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectCategory(tag),
                        splashColor: color.withOpacity(0.18),
                        highlightColor: color.withOpacity(0.08),
                        hoverColor: color.withOpacity(0.08),
                        child: StatefulBuilder(
                          builder: (context, setChipState) {
                            bool isPressed = false;
                            return Listener(
                              onPointerDown: (_) =>
                                  setChipState(() => isPressed = true),
                              onPointerUp: (_) =>
                                  setChipState(() => isPressed = false),
                              onPointerCancel: (_) =>
                                  setChipState(() => isPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOut,
                                color: isPressed
                                    ? color.withOpacity(0.08)
                                    : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, color: color, size: 18),
                                      const SizedBox(width: 7),
                                      Text(
                                        tag,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : color,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

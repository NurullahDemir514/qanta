import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/services/category_icon_service.dart';

/// Basit ve kullanışlı harcama tag'i girişi
/// 
/// Karmaşık AI sistemlerini attık. Sadece:
/// - Hızlı text input
/// - Basit öneriler
/// - Temiz UI
class ExpenseTagSelector extends StatefulWidget {
  final String? selectedTag;
  final Function(String tag) onTagSelected;
  final String? errorText;

  const ExpenseTagSelector({
    super.key,
    this.selectedTag,
    required this.onTagSelected,
    this.errorText,
  });

  @override
  State<ExpenseTagSelector> createState() => _ExpenseTagSelectorState();
}

class _ExpenseTagSelectorState extends State<ExpenseTagSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  List<String> _getActiveExpenseCategories(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    return provider.expenseCategories
      .where((cat) => true) // UnifiedCategoryModel doesn't have isActive, all are active
      .map((cat) => cat.displayName.trim())
      .toSet()
      .toList();
  }

  /// Get budget info for a category
  Map<String, dynamic>? _getBudgetInfo(BuildContext context, String categoryName) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    
    // Find category by name
    try {
      final category = provider.expenseCategories.firstWhere(
        (cat) => cat.displayName.trim() == categoryName,
      );
      
      // Find budget for this category
      try {
        final budget = provider.budgets.firstWhere(
          (budget) => budget.categoryId == category.id,
        );
        
        return {
          'limit': budget.monthlyLimit,
          'spent': budget.spentAmount,
          'remaining': budget.monthlyLimit - budget.spentAmount,
          'percentage': budget.spentAmount / budget.monthlyLimit,
        };
      } catch (e) {
        // No budget found for this category
        return null;
      }
    } catch (e) {
      // Category not found
      return null;
    }
  }

  List<String> _getFilteredSuggestions(BuildContext context) {
    final tags = _getActiveExpenseCategories(context);
    if (_controller.text.isEmpty) return tags;
    return tags
        .where((tag) => tag.toLowerCase().contains(_controller.text.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedTag != null) {
      _controller.text = widget.selectedTag!;
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

  void _selectTag(String tag) {
    _controller.text = tag;
    _focusNode.unfocus();
    widget.onTagSelected(tag);
  }

  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Build budget info widget
  Widget _buildBudgetInfo(Map<String, dynamic> budgetInfo, bool isDark) {
    final remaining = budgetInfo['remaining'] as double;
    final l10n = AppLocalizations.of(context)!;
    
    return Text(
      '₺${NumberFormat('#,##0', 'tr_TR').format(remaining.toInt())} ${l10n.remaining}.',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _getFilteredSuggestions(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
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
            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
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
            errorText: widget.errorText,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty) {
              widget.onTagSelected(_capitalizeText(value));
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final capitalizedValue = _capitalizeText(value);
              _controller.text = capitalizedValue;
              widget.onTagSelected(capitalizedValue);
              _focusNode.unfocus();
            }
          },
        ),
        // Öneriler
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((tag) {
                final isSelected = _controller.text.trim().toLowerCase() == tag.toLowerCase();
                final icon = CategoryIconService.getIcon(tag.toLowerCase());
                final color = const Color(0xFFFF4C4C); // Gider için sabit kırmızı
                final budgetInfo = _getBudgetInfo(context, tag);
                
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
                        onTap: () => _selectTag(tag),
                        splashColor: color.withOpacity(0.18),
                        highlightColor: color.withOpacity(0.08),
                        hoverColor: color.withOpacity(0.08),
                        child: StatefulBuilder(
                          builder: (context, setChipState) {
                            bool isPressed = false;
                            return Listener(
                              onPointerDown: (_) => setChipState(() => isPressed = true),
                              onPointerUp: (_) => setChipState(() => isPressed = false),
                              onPointerCancel: (_) => setChipState(() => isPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOut,
                                color: isPressed ? color.withOpacity(0.08) : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        color: color,
                                        size: 18,
                                      ),
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
                                      // Budget info
                                      if (budgetInfo != null) ...[
                                        const SizedBox(width: 8),
                                        _buildBudgetInfo(budgetInfo, isDark),
                                      ],
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

/// Legacy compat
class ExpenseCategorySelectorV2 extends ExpenseTagSelector {
  const ExpenseCategorySelectorV2({
    super.key,
    String? selectedCategory,
    required Function(String) onCategorySelected,
    String? errorText,
  }) : super(
    selectedTag: selectedCategory,
    onTagSelected: onCategorySelected,
    errorText: errorText,
  );
} 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../core/theme/theme_provider.dart';
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
  final VoidCallback? onNext;

  const ExpenseTagSelector({
    super.key,
    this.selectedTag,
    required this.onTagSelected,
    this.errorText,
    this.onNext,
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
        .where(
          (cat) => true,
        ) // UnifiedCategoryModel doesn't have isActive, all are active
        .map((cat) => cat.displayName.trim())
        .toSet()
        .toList();
  }

  /// Get budget info for a category
  Map<String, dynamic>? _getBudgetInfo(
    BuildContext context,
    String categoryName,
  ) {
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
        .where(
          (tag) => tag.toLowerCase().contains(_controller.text.toLowerCase()),
        )
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
  Widget _buildBudgetInfo(
    Map<String, dynamic> budgetInfo,
    bool isDark,
    double fontSize,
  ) {
    final remaining = budgetInfo['remaining'] as double;
    final l10n = AppLocalizations.of(context)!;

    return Text(
      '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(remaining)} ${l10n.remaining}.',
      style: GoogleFonts.inter(
        fontSize: fontSize,
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop

    // Responsive değerler - Mobil odaklı
    final inputFontSize = isSmallMobile
        ? 14.0
        : isMobile
        ? 15.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 17.0
        : isTablet
        ? 18.0
        : 20.0;

    final hintFontSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 13.0
        : isLargeMobile
        ? 14.0
        : isSmallTablet
        ? 15.0
        : isTablet
        ? 16.0
        : 18.0;

    final borderRadius = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 18.0;

    final borderWidth = isSmallMobile
        ? 1.5
        : isMobile
        ? 1.8
        : isLargeMobile
        ? 2.0
        : isSmallTablet
        ? 2.2
        : isTablet
        ? 2.5
        : 3.0;

    final chipSpacing = isSmallMobile
        ? 8.0
        : isMobile
        ? 9.0
        : isLargeMobile
        ? 10.0
        : isSmallTablet
        ? 11.0
        : isTablet
        ? 12.0
        : 14.0;

    final chipPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 18.0
        : isTablet
        ? 20.0
        : 24.0;

    final chipVerticalPadding = isSmallMobile
        ? 6.0
        : isMobile
        ? 7.0
        : isLargeMobile
        ? 8.0
        : isSmallTablet
        ? 9.0
        : isTablet
        ? 10.0
        : 12.0;

    final iconSize = isSmallMobile
        ? 16.0
        : isMobile
        ? 17.0
        : isLargeMobile
        ? 18.0
        : isSmallTablet
        ? 19.0
        : isTablet
        ? 20.0
        : 22.0;

    final chipFontSize = isSmallMobile
        ? 13.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 15.0
        : isSmallTablet
        ? 16.0
        : isTablet
        ? 17.0
        : 18.0;

    final chipSpacingBetween = isSmallMobile
        ? 5.0
        : isMobile
        ? 6.0
        : isLargeMobile
        ? 7.0
        : isSmallTablet
        ? 8.0
        : isTablet
        ? 9.0
        : 10.0;

    final budgetFontSize = isSmallMobile
        ? 9.0
        : isMobile
        ? 10.0
        : isLargeMobile
        ? 11.0
        : isSmallTablet
        ? 12.0
        : isTablet
        ? 13.0
        : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.inter(
            fontSize: inputFontSize,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: l10n.categoryHint,
            hintStyle: GoogleFonts.inter(
              fontSize: hintFontSize,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
            ),
            errorText: widget.errorText,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20.0 : 16.0,
              vertical: isTablet ? 18.0 : 14.0,
            ),
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
              // Call onNext callback to move to next step
              widget.onNext?.call();
            }
          },
        ),
        // Öneriler
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          SizedBox(height: isTablet ? 12.0 : 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((tag) {
                final isSelected =
                    _controller.text.trim().toLowerCase() == tag.toLowerCase();
                final icon = CategoryIconService.getIcon(tag.toLowerCase());
                final color = const Color(
                  0xFFFF4C4C,
                ); // Gider için sabit kırmızı
                final budgetInfo = _getBudgetInfo(context, tag);

                return Padding(
                  padding: EdgeInsets.only(right: chipSpacing),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: color,
                        width: isSelected ? borderWidth : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(borderRadius),
                        onTap: () => _selectTag(tag),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: chipPadding,
                                    vertical: chipVerticalPadding,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, color: color, size: iconSize),
                                      SizedBox(width: chipSpacingBetween),
                                      Text(
                                        tag,
                                        style: GoogleFonts.inter(
                                          fontSize: chipFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : color,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      // Budget info
                                      if (budgetInfo != null) ...[
                                        SizedBox(width: isTablet ? 10.0 : 8.0),
                                        _buildBudgetInfo(
                                          budgetInfo,
                                          isDark,
                                          budgetFontSize,
                                        ),
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
    super.errorText,
    super.onNext,
  }) : super(selectedTag: selectedCategory, onTagSelected: onCategorySelected);
}

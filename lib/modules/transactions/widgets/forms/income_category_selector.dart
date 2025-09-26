import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/services/category_icon_service.dart';

/// Basit gelir tag'i girişi
class IncomeTagSelector extends StatefulWidget {
  final String? selectedTag;
  final Function(String tag) onTagSelected;
  final String? errorText;

  const IncomeTagSelector({
    super.key,
    this.selectedTag,
    required this.onTagSelected,
    this.errorText,
  });

  @override
  State<IncomeTagSelector> createState() => _IncomeTagSelectorState();
}

class _IncomeTagSelectorState extends State<IncomeTagSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  List<String> _getActiveIncomeCategories(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    return provider.incomeCategories
      .where((cat) => true) // UnifiedCategoryModel doesn't have isActive, all are active
      .map((cat) => cat.displayName.trim())
      .toSet()
      .toList();
  }

  List<String> _getFilteredSuggestions(BuildContext context) {
    final tags = _getActiveIncomeCategories(context);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _getFilteredSuggestions(context);
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
            hintText: 'maaş, freelance, yatırım...',
            hintStyle: GoogleFonts.inter(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
                final color = const Color(0xFF4CAF50); // Gelir için sabit yeşil
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
class IncomeCategorySelector extends IncomeTagSelector {
  const IncomeCategorySelector({
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
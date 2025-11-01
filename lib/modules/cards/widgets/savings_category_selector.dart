import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Tasarruf kategorisi seçici widget'ı
/// Transaction formdaki kategori seçimine benzer şekilde çalışır
class SavingsCategorySelector extends StatefulWidget {
  final String? selectedCategory;
  final Function(String category) onCategorySelected;
  final String? errorText;

  const SavingsCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.errorText,
  });

  @override
  State<SavingsCategorySelector> createState() => _SavingsCategorySelectorState();
}

class _SavingsCategorySelectorState extends State<SavingsCategorySelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null) {
      _controller.text = widget.selectedCategory!;
    }
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
    
    // Kategorileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SavingsProvider>(context, listen: false);
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _getFilteredCategories(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context, listen: false);
    final categoryNames = provider.activeCategories.map((c) => c.name).toList();
    
    if (_controller.text.isEmpty) return categoryNames;
    return categoryNames
        .where((name) => name.toLowerCase().contains(_controller.text.toLowerCase()))
        .toList();
  }

  void _selectCategory(String category) {
    _controller.text = category;
    _focusNode.unfocus();
    widget.onCategorySelected(category);
  }

  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SavingsProvider>(
      builder: (context, provider, child) {
        final suggestions = _getFilteredCategories(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: l10n.categoryHint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF8E8E93),
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                errorText: widget.errorText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  widget.onCategorySelected(_capitalizeText(value));
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _selectCategory(_capitalizeText(value));
                }
              },
            ),

            // Suggestions Chips
            if (_showSuggestions && suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((category) {
                  final isSelected = _controller.text.toLowerCase() == category.toLowerCase();
                  final color = const Color(0xFF34D399); // Mint Green

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectCategory(category),
                      borderRadius: BorderRadius.circular(10),
                      splashColor: color.withValues(alpha: 0.1),
                      highlightColor: color.withValues(alpha: 0.05),
                      hoverColor: color.withValues(alpha: 0.08),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : (isDark 
                                  ? Colors.white.withOpacity(0.05) 
                                  : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected 
                              ? Border.all(color: color, width: 2)
                              : null,
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}


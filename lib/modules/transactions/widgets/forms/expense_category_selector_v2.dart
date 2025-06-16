import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

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

  // Basit popüler tag'ler
  final List<String> _popularTags = [
    'Kahve', 'Yemek', 'Market', 'Benzin', 'Taksi', 
    'Restoran', 'Alışveriş', 'Eczane', 'Kırtasiye'
  ];

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

  List<String> _getFilteredSuggestions() {
    if (_controller.text.isEmpty) return _popularTags.take(5).toList();
    
    return _popularTags
        .where((tag) => tag.toLowerCase().contains(_controller.text.toLowerCase()))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
            hintText: 'kahve, market, benzin...',
            hintStyle: GoogleFonts.inter(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
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
        if (_showSuggestions && _getFilteredSuggestions().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      ),
                    ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
                          child: Row(
                children: _getFilteredSuggestions().map((tag) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _selectTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                                ),
                        child: Text(
                          tag,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).toList(),
                  ),
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/smart_category_service.dart';
import '../services/category_icon_service.dart';

/// Smart category creator widget
/// 
/// Allows users to create custom categories with automatic icon and color
/// assignment. Features intelligent suggestions, real-time preview, and
/// a professional UX without overwhelming complexity.
/// 
/// **Key Features:**
/// - Auto-complete suggestions for common categories
/// - Real-time icon and color preview
/// - Intelligent pattern matching for icons/colors
/// - Professional, clean UI
/// - Confidence indicators for suggestions
/// 
/// **Usage:**
/// ```dart
/// SmartCategoryCreator(
///   isIncomeCategory: false,
///   onCategoryCreated: (name, icon, color) {
///     // Create category
///   },
/// )
/// ```
class SmartCategoryCreator extends StatefulWidget {
  final bool isIncomeCategory;
  final Function(String name, String iconName, String colorHex) onCategoryCreated;
  final VoidCallback? onCancel;

  const SmartCategoryCreator({
    super.key,
    required this.isIncomeCategory,
    required this.onCategoryCreated,
    this.onCancel,
  });

  @override
  State<SmartCategoryCreator> createState() => _SmartCategoryCreatorState();
}

class _SmartCategoryCreatorState extends State<SmartCategoryCreator> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  
  CategoryStyleSuggestion? _currentSuggestion;
  List<CategoryNameSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _loadInitialSuggestions() {
    _suggestions = SmartCategoryService.getPopularCategories(
      isIncomeCategory: widget.isIncomeCategory,
    );
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    
    setState(() {
      _nameError = null;
      
      if (name.isNotEmpty) {
        // Get style suggestion for the entered name
        _currentSuggestion = SmartCategoryService.suggestCategoryStyle(
          name: name,
          isIncomeCategory: widget.isIncomeCategory,
        );
        
        // Update autocomplete suggestions
        _suggestions = SmartCategoryService.getPopularCategories(
          isIncomeCategory: widget.isIncomeCategory,
          searchQuery: name,
        );
        
        _showSuggestions = _suggestions.isNotEmpty;
      } else {
        _currentSuggestion = null;
        _loadInitialSuggestions();
        _showSuggestions = false;
      }
    });
  }

  void _selectSuggestion(CategoryNameSuggestion suggestion) {
    _nameController.text = suggestion.name;
    setState(() {
      _showSuggestions = false;
      _currentSuggestion = CategoryStyleSuggestion(
        iconName: suggestion.icon,
        colorHex: suggestion.color,
        confidence: 1.0,
      );
    });
    _nameFocus.unfocus();
  }

  void _createCategory() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Kategori adı gerekli';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _nameError = 'Kategori adı en az 2 karakter olmalı';
      });
      return;
    }

    if (name.length > 30) {
      setState(() {
        _nameError = 'Kategori adı en fazla 30 karakter olabilir';
      });
      return;
    }

    // Get final suggestion if not already available
    final suggestion = _currentSuggestion ?? SmartCategoryService.suggestCategoryStyle(
      name: name,
      isIncomeCategory: widget.isIncomeCategory,
    );

    HapticFeedback.lightImpact();
    widget.onCategoryCreated(name, suggestion.iconName, suggestion.colorHex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isIncomeCategory ? 'Yeni Gelir Kategorisi' : 'Yeni Gider Kategorisi',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(
                    Icons.close,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Preview Section
          if (_currentSuggestion != null) ...[
            _buildPreviewSection(isDark),
            const SizedBox(height: 24),
          ],
          
          // Name Input
          _buildNameInput(isDark),
          
          // Suggestions
          if (_showSuggestions && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSuggestionsList(isDark),
          ],
          
          const SizedBox(height: 24),
          
          // Actions
          _buildActions(isDark),
          
          // Bottom padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    if (_currentSuggestion == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentSuggestion!.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentSuggestion!.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Preview
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _currentSuggestion!.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _currentSuggestion!.icon,
              color: _currentSuggestion!.color,
              size: 22,
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Preview Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty ? 'Kategori Önizlemesi' : _nameController.text.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _currentSuggestion!.isConfident ? Icons.check_circle : Icons.help_outline,
                      size: 14,
                      color: _currentSuggestion!.isConfident ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentSuggestion!.isConfident ? 'Otomatik eşleşme' : 'Genel kategori',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Adı',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          decoration: InputDecoration(
            hintText: widget.isIncomeCategory ? 'Ör: Yan Gelir, Danışmanlık' : 'Ör: Kahve, Abonelik',
            errorText: _nameError,
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isIncomeCategory ? const Color(0xFF34C759) : const Color(0xFF00FFB3),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 2,
              ),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          textCapitalization: TextCapitalization.words,
          onTap: () {
            setState(() {
              _showSuggestions = _suggestions.isNotEmpty;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Önerilen Kategoriler',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return _buildSuggestionTile(suggestion, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(CategoryNameSuggestion suggestion, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSuggestion(suggestion),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: suggestion.colorData.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    suggestion.iconData,
                    color: suggestion.colorData,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    final canCreate = _nameController.text.trim().isNotEmpty && _nameError == null;
    
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'İptal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
            ),
          ),
        
        if (widget.onCancel != null) const SizedBox(width: 16),
        
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canCreate ? _createCategory : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isIncomeCategory ? const Color(0xFF34C759) : const Color(0xFF00FFB3),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
            ),
            child: Text(
              'Kategori Oluştur',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 
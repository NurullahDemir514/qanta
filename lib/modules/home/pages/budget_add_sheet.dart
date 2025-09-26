import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/budget_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/unified_category_service.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/unified_category_model.dart';

class BudgetAddSheet extends StatefulWidget {
  final VoidCallback? onBudgetSaved;
  final Future<void> Function()? onReload;
  const BudgetAddSheet({super.key, this.onBudgetSaved, this.onReload});

  @override
  State<BudgetAddSheet> createState() => _BudgetAddSheetState();
}

class _BudgetAddSheetState extends State<BudgetAddSheet> {
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _limitFocusNode = FocusNode();
  bool _showSuggestions = false;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;

  List<String> _getActiveExpenseCategories(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    return provider.expenseCategories
        .where((cat) => true) // UnifiedCategoryModel doesn't have isActive, all are active
        .map((cat) => cat.displayName.trim())
        .toSet()
        .toList();
  }

  List<String> _getFilteredSuggestions(BuildContext context) {
    final tags = _getActiveExpenseCategories(context);
    if (_categoryController.text.isEmpty) return tags;
    return tags
        .where((tag) => tag.toLowerCase().contains(_categoryController.text.toLowerCase()))
        .toList();
  }

  bool _canSave() {
    return _selectedCategoryName != null &&
        _selectedCategoryName!.isNotEmpty &&
        _limitController.text.isNotEmpty &&
        !_isSaving;
  }

  Future<void> _findRealCategoryId(String categoryName) async {
    try {
      // Find the actual category ID from the provider
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      
      final matchedCategory = provider.expenseCategories.firstWhere(
        (cat) => cat.displayName.trim() == categoryName,
        orElse: () => provider.expenseCategories.first,
      );
      
      setState(() {
        _selectedCategoryId = matchedCategory.id;
      });
      
    } catch (e) {
      setState(() {
        _selectedCategoryId = categoryName.toLowerCase().replaceAll(' ', '_');
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_canSave()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      final limit = double.tryParse(_limitController.text.replaceAll(',', ''));
      if (limit == null || limit <= 0) {
        setState(() => _isSaving = false);
        return;
      }
      
      await provider.createBudget(
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        monthlyLimit: limit,
      );
      
      _limitController.clear();
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
        _isSaving = false;
      });
      
      if (widget.onReload != null) await widget.onReload!();
      if (context.mounted) {
        Navigator.pop(context);
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryFocusNode.addListener(() {
      setState(() => _showSuggestions = _categoryFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    _categoryController.dispose();
    _categoryFocusNode.dispose();
    _limitFocusNode.dispose();
    super.dispose();
  }

  void _selectCategory(String category) async {
    _categoryController.text = category;
    _selectedCategoryName = category;
    await _findRealCategoryId(category);
    FocusScope.of(context).requestFocus(_limitFocusNode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _getFilteredSuggestions(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E8E93),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isDark ? Colors.white : const Color(0xFF6D6D70),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Yeni Limit Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Kategori Seçin',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              focusNode: _categoryFocusNode,
              autofocus: false,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'market, yemek, ulaşım...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF6D6D70),
                    width: 2,
                  ),
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {});
                _selectedCategoryName = value;
              },
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  await _findRealCategoryId(value);
                  FocusScope.of(context).requestFocus(_limitFocusNode);
                }
              },
            ),
            if (_showSuggestions && suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((tag) {
                    final isSelected = _categoryController.text.trim().toLowerCase() == tag.toLowerCase();
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
                            onTap: () async {
                              _selectCategory(tag);
                              await Future.delayed(const Duration(milliseconds: 50));
                              FocusScope.of(context).requestFocus(_limitFocusNode);
                            },
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
            const SizedBox(height: 20),
            Text(
              'Aylık Limit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _limitController,
              focusNode: _limitFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: '0,00',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _selectedCategoryId = null;
                      _selectedCategoryName = null;
                      _limitController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: const Color(0xFF8E8E93),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSave() ? _saveBudget : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSave()
                          ? (isDark ? const Color(0xFF38383A) : const Color(0xFF6D6D70))
                          : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Limiti Kaydet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 
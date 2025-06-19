import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/budget_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/unified_category_service.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';

class BudgetManagementPage extends StatefulWidget {
  final VoidCallback? onBudgetSaved;
  
  const BudgetManagementPage({
    super.key,
    this.onBudgetSaved,
  });

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  List<BudgetModel> _existingBudgets = [];
  bool _isLoading = true;
  final _limitController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        debugPrint('User null - giriş yapılmamış');
        return;
      }

      final now = DateTime.now();
      
      final budgets = await BudgetService.getUserBudgets(user.id, now.month, now.year);

      if (mounted) {
        setState(() {
          _existingBudgets = budgets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Veri yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _canSave() {
    return _selectedCategoryName != null && 
           _selectedCategoryName!.isNotEmpty && 
           _limitController.text.isNotEmpty;
  }

  Future<void> _saveBudget() async {
    if (!_canSave()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kategori adı girin ve limit belirleyin')),
      );
      return;
    }

    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      final limit = double.tryParse(_limitController.text.replaceAll(',', ''));
      if (limit == null || limit <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir limit girin')),
        );
        return;
      }

      final now = DateTime.now();

      await BudgetService.upsertBudget(
        userId: user.id,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        monthlyLimit: limit,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        _limitController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
        
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe başarıyla kaydedildi')),
        );
        
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF000000) 
        : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: const Color(0xFF007AFF),
            size: 20,
          ),
        ),
        title: Text(
          'Bütçe Yönetimi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave() ? _saveBudget : null,
            child: Text(
              'Kaydet',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _canSave() 
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFF007AFF),
                ),
                const SizedBox(height: 16),
                Text(
                  'Yükleniyor...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_existingBudgets.isNotEmpty) ...[
                  _buildSection(
                    title: 'Mevcut Bütçeler',
                    child: Column(
                      children: _existingBudgets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final budget = entry.value;
                        return _buildExistingBudgetItem(
                          budget, 
                          isDark, 
                          index == _existingBudgets.length - 1
                        );
                      }).toList(),
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                ],
                
                _buildSection(
                  title: 'Yeni Bütçe Ekle',
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'Kategori',
                        child: BudgetCategorySelector(
                          selectedCategory: _selectedCategoryName,
                          onCategorySelected: (categoryName) async {
                            setState(() {
                              _selectedCategoryName = categoryName;
                            });
                            await _findRealCategoryId(categoryName);
                          },
                        ),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFormField(
                        label: 'Aylık Limit',
                        child: _buildAmountInput(isDark),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  isDark: isDark,
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildExistingBudgetItem(BudgetModel budget, bool isDark, bool isLast) {
    final numberFormat = NumberFormat('#,##0', 'tr_TR');
    final categoryIcon = CategoryIconService.getIcon(budget.categoryName.toLowerCase());
    final categoryColor = CategoryIconService.getColorFromMap(budget.categoryName.toLowerCase());
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2C2C2E) 
          : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              size: 22,
              color: categoryColor,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${numberFormat.format(budget.monthlyLimit)} / ay',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () => _deleteBudget(budget.id),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFFF3B30),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findRealCategoryId(String categoryName) async {
    try {
      final expenseCategories = await UnifiedCategoryService.getCategoriesWithCache(
        categoryType: CategoryType.expense,
        language: 'tr',
      );
      
      UnifiedCategoryModel? matchedCategory = expenseCategories
          .where((cat) => cat.displayName.toLowerCase() == categoryName.toLowerCase())
          .firstOrNull;
      
      matchedCategory ??= expenseCategories
          .where((cat) => cat.name.toLowerCase() == categoryName.toLowerCase())
          .firstOrNull;
      
      matchedCategory ??= expenseCategories
          .where((cat) => 
            cat.displayName.toLowerCase().contains(categoryName.toLowerCase()) ||
            cat.name.toLowerCase().contains(categoryName.toLowerCase()))
          .firstOrNull;
      
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2C2C2E) 
          : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _limitController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '2000',
          hintStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
          prefixText: '₺ ',
          prefixStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteBudget(String budgetId) async {
    try {
      await BudgetService.deleteBudget(budgetId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe silindi')),
        );
        widget.onBudgetSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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

  final List<String> _popularCategories = [
    'Market', 'Yemek', 'Ulaşım', 'Faturalar', 'Eğlence', 
    'Giyim', 'Sağlık', 'Eğitim', 'Kişisel Bakım', 'Ev'
  ];

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

  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  List<String> _getFilteredSuggestions() {
    if (_controller.text.isEmpty) return _popularCategories.take(6).toList();
    
    return _popularCategories
        .where((category) => category.toLowerCase().contains(_controller.text.toLowerCase()))
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF2C2C2E) 
              : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'market, yemek, ulaşım...',
              hintStyle: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E93),
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
                final capitalizedValue = _capitalizeText(value);
                _controller.text = capitalizedValue;
                widget.onCategorySelected(capitalizedValue);
                _focusNode.unfocus();
              }
            },
          ),
        ),
        
        if (_showSuggestions && _getFilteredSuggestions().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF2C2C2E) 
                : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önerilen Kategoriler',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getFilteredSuggestions().map((category) {
                    final categoryIcon = CategoryIconService.getIcon(category.toLowerCase());
                    final categoryColor = CategoryIconService.getColorFromMap(category.toLowerCase());
                    
                    return GestureDetector(
                      onTap: () => _selectCategory(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF1C1C1E) 
                            : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoryIcon,
                              size: 16,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
} 
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
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF007AFF),
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
        actions: [],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF007AFF),
            ),
          )
        : _existingBudgets.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _existingBudgets.length,
                itemBuilder: (context, index) {
                  final budget = _existingBudgets[index];
                  return _buildBudgetCard(budget, isDark, index);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetBottomSheet(context),
        backgroundColor: const Color(0xFF6D6D70),
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(context),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF1C1C1E) 
                : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF007AFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yeni Bütçe Ekle',
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
                
                BudgetCategorySelector(
                  selectedCategory: _selectedCategoryName,
                  onCategorySelected: (categoryName) async {
                    setModalState(() {
                      _selectedCategoryName = categoryName;
                    });
                    await _findRealCategoryId(categoryName);
                  },
                ),
                
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
                
                _buildAmountInput(isDark),
                
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
                        onPressed: _canSave() ? () async {
                          await _saveBudget();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSave() 
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF8E8E93),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Bütçe Ekle',
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
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
            'Henüz bütçe belirlenmemiş',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kategoriler için aylık harcama limiti\nbelirleyerek bütçenizi kontrol edin',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBudgetCard(BudgetModel budget, bool isDark, int index) {
    
    final numberFormat = NumberFormat('#,##0', 'tr_TR');
    final categoryIcon = CategoryIconService.getIcon(budget.categoryName.toLowerCase());
    final categoryColor = CategoryIconService.getColorFromMap(budget.categoryName.toLowerCase());
    
    return Container(
      margin: EdgeInsets.only(bottom: index == _existingBudgets.length - 1 ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              size: 24,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${numberFormat.format(budget.monthlyLimit)} / ay',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _showDeleteDialog(budget),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: const Color(0xFFFF3B30),
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bütçe Sil',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${budget.categoryName} kategorisi için belirlenen bütçeyi silmek istediğinizden emin misiniz?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudget(budget.id);
            },
            child: Text(
              'Sil',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2C2C2E) 
          : const Color(0xFFF2F2F7),
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
            '₺',
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
                hintText: '2.000',
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
              '/ ay',
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
    if (_controller.text.isEmpty) return _popularCategories.take(4).toList();
    
    return _popularCategories
        .where((category) => category.toLowerCase().contains(_controller.text.toLowerCase()))
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF2C2C2E) 
              : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: _controller.text.isNotEmpty
              ? Border.all(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: _controller.text.isNotEmpty 
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF8E8E93),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,

                    hintText: 'Market, Yemek, Ulaşım...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
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
                      _selectCategory(_capitalizeText(value));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        if (_showSuggestions && _getFilteredSuggestions().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF2C2C2E) 
                : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önerilen Kategoriler',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getFilteredSuggestions().map((category) {
                    return GestureDetector(
                      onTap: () => _selectCategory(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF007AFF),
                          ),
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
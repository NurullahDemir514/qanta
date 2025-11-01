import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import '../../../core/theme/theme_provider.dart';

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
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;
  // Sadece aylık bütçe destekleniyor
  final BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _isRecurring = false;
  DateTime _selectedStartDate = DateTime.now();

  List<String> _getActiveExpenseCategories(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    return provider.expenseCategories
        .where(
          (cat) => true,
        ) // UnifiedCategoryModel doesn't have isActive, all are active
        .map((cat) {
          // For system categories, use localized names
          // For user-created categories, use displayName directly
          if (!cat.isUserCategory) {
            return CategoryIconService.getCategoryName(cat.name, context);
          } else {
            return cat.displayName;
          }
        })
        .toSet()
        .toList();
  }

  List<String> _getFilteredSuggestions(BuildContext context) {
    final tags = _getActiveExpenseCategories(context);
    if (_categoryController.text.isEmpty) return tags;
    return tags
        .where(
          (tag) => tag.toLowerCase().contains(
            _categoryController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  bool _canSave() {
    return _categoryController.text.isNotEmpty &&
        _limitController.text.isNotEmpty &&
        !_isSaving;
  }

  Future<void> _findRealCategoryId(String categoryName) async {
    try {
      // Find the actual category ID from the provider by matching names
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);

      final matchedCategory = provider.expenseCategories.firstWhere(
        (cat) {
          // For system categories, match with localized names
          // For user-created categories, match with displayName
          if (!cat.isUserCategory) {
            return CategoryIconService.getCategoryName(cat.name, context) == categoryName;
          } else {
            return cat.displayName == categoryName;
          }
        },
        orElse: () => provider.expenseCategories.first,
      );

      setState(() {
        _selectedCategoryId = matchedCategory.id;
        _selectedCategoryName = matchedCategory.displayName; // Use original displayName for backend
      });
    } catch (e) {
      setState(() {
        _selectedCategoryId = categoryName.toLowerCase().replaceAll(' ', '_');
        _selectedCategoryName = categoryName;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_canSave()) {
      return;
    }
    
    // Duplicate budget kontrolü
    if (_hasDuplicateBudget()) {
      _showDuplicateWarning();
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      final limit = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _limitController.text,
        locale,
      );
      if (limit == null || limit <= 0) {
        setState(() => _isSaving = false);
        return;
      }

      // Ensure category is selected
      if (_selectedCategoryId == null || _selectedCategoryName == null) {
        await _findRealCategoryId(_categoryController.text);
      }

      await provider.createBudget(
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        limit: limit,
        period: _selectedPeriod,
        isRecurring: _isRecurring,
        startDate: _selectedStartDate,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorOccurred}: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Add listener to category controller for debugging
    _categoryController.addListener(() {
      print('DEBUG: Controller listener - Text: "${_categoryController.text}"');
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

  String _getPeriodDisplayName() {
    final l10n = AppLocalizations.of(context)!;
    return l10n.monthly; // Sadece aylık destekleniyor
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _getFilteredSuggestions(context);
    return Container(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    color: (isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA)),
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
                  AppLocalizations.of(context)!.addNewLimit,
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
              AppLocalizations.of(context)!.selectCategory,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
                hintText: AppLocalizations.of(context)!.categoryHint,
                hintStyle: GoogleFonts.inter(
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.errorColor,
                    width: 1,
                  ),
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                print('DEBUG: TextField onChanged - Old: "${_categoryController.text}", New: "$value"');
                // Update state without setState to avoid interrupting text input
                if (value.isEmpty) {
                  _selectedCategoryId = null;
                  _selectedCategoryName = null;
                } else {
                  _selectedCategoryName = value;
                }
                // Call setState after a microtask to avoid interrupting text input
                Future.microtask(() => setState(() {}));
              },
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  await _findRealCategoryId(value);
                  FocusScope.of(context).requestFocus(_limitFocusNode);
                }
              },
            ),
            // Always show category suggestions
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((tag) {
                    final isSelected =
                        _categoryController.text.trim().toLowerCase() ==
                        tag.toLowerCase();
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
                              await Future.delayed(
                                const Duration(milliseconds: 50),
                              );
                              FocusScope.of(
                                context,
                              ).requestFocus(_limitFocusNode);
                            },
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
                                              color: isDark
                                                  ? Colors.white
                                                  : color,
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
            // Period seçimi kaldırıldı - sadece aylık destekleniyor
            Text(
              '${_getPeriodDisplayName()} Limit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitController,
                    focusNode: _limitFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.limitAmountPlaceholder,
                      hintStyle: GoogleFonts.inter(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Recurring toggle - segmented control design like balance card
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFF2F2F7),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // OFF Button
                      GestureDetector(
                        onTap: () {
                          if (_isRecurring) {
                            setState(() {
                              _isRecurring = false;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: !_isRecurring
                                ? const Color(0xFF6D6D70) // Gri
                                : Colors.transparent,
                            boxShadow: !_isRecurring
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6D6D70).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: !_isRecurring
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : const Color(0xFF6D6D70),
                              letterSpacing: 0.2,
                            ),
                            child: Text(AppLocalizations.of(context)!.oneTime),
                          ),
                        ),
                      ),
                      // ON Button
                      GestureDetector(
                        onTap: () {
                          if (!_isRecurring) {
                            setState(() {
                              _isRecurring = true;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _isRecurring
                                ? const Color(0xFF007AFF) // Mavi
                                : Colors.transparent,
                            boxShadow: _isRecurring
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF007AFF).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isRecurring
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : const Color(0xFF6D6D70),
                              letterSpacing: 0.2,
                            ),
                            child: Text(AppLocalizations.of(context)!.recurring),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Always show info box with dynamic content
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _isRecurring ? Icons.info : Icons.info_outline,
                    color: _isRecurring 
                        ? const Color(0xFF007AFF)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isRecurring 
                          ? AppLocalizations.of(context)!.limitWillRenew(_getPeriodDisplayName().toLowerCase())
                          : AppLocalizations.of(context)!.limitOneTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _isRecurring 
                            ? const Color(0xFF007AFF)
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Start Date Selection
            Text(
              AppLocalizations.of(context)!.startDate,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedStartDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF007AFF),
                          onPrimary: Colors.white,
                          surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          onSurface: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null && pickedDate != _selectedStartDate) {
                  setState(() {
                    _selectedStartDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isDark ? Colors.white : const Color(0xFF6D6D70),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedStartDate.day.toString().padLeft(2, '0')}/${_selectedStartDate.month.toString().padLeft(2, '0')}/${_selectedStartDate.year}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isDark ? Colors.white : const Color(0xFF6D6D70),
                      size: 20,
                    ),
                  ],
                ),
              ),
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
                      AppLocalizations.of(context)?.cancel ?? 'Cancel',
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
                          ? const Color(0xFFFF453A) // Red - consistent with FAB
                          : (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA)),
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
                            AppLocalizations.of(context)!.saveLimit,
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
      ),
    );
  }

  bool _hasDuplicateBudget() {
    if (_selectedCategoryId == null) return false;
    
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    final existingBudgets = provider.budgets;
    
    // Aynı kategori ve periyot kontrolü
    return existingBudgets.any((budget) => 
      budget.categoryId == _selectedCategoryId && 
      budget.period == _selectedPeriod
    );
  }

  void _showDuplicateWarning() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                l10n.duplicateBudgetWarning,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                l10n.duplicateBudgetMessage,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark 
                      ? Colors.white.withOpacity(0.7) 
                      : const Color(0xFF1C1C1E).withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.white,
                    backgroundColor: isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.ok,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

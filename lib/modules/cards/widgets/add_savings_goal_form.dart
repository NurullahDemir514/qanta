import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import 'savings_category_selector.dart';

/// Yeni tasarruf hedefi ekleme formu
class AddSavingsGoalForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddSavingsGoalForm({super.key, this.onSuccess});

  @override
  State<AddSavingsGoalForm> createState() => _AddSavingsGoalFormState();
}

class _AddSavingsGoalFormState extends State<AddSavingsGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedEmoji;
  DateTime? _targetDate;
  bool _isLoading = false;
  
  // Renkler - Daha fazla güzel renk
  final List<String> _availableColors = [
    'FF007AFF', // iOS Blue
    'FF34D399', // Mint Green
    'FFFF9500', // Orange
    'FFFF453A', // Red
    'FFBF5AF2', // Purple
    'FF00C7BE', // Teal
    'FFFFD60A', // Yellow
    'FFFF375F', // Pink
    'FF5E5CE6', // Indigo
    'FFAF52DE', // Magenta
    'FF30D158', // Green
    'FF64D2FF', // Cyan
    'FFFF375F', // Rose
    'FFFF9F0A', // Amber
    'FFAC8E68', // Brown
    'FF8E8E93', // Gray
  ];
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = _availableColors[0];
    _selectedEmoji = '💰';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final locale = themeProvider.currency.locale;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar - Daha belirgin
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title - Modern ve minimal
                  Text(
                    l10n.createSavingsGoal,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Kategori seçimi (İsteğe Bağlı)
                  Row(
                    children: [
                      Text(
                        l10n.category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.optionalField,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark 
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.4),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SavingsCategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // İsim
                  Text(
                    l10n.goalName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: l10n.enterGoalName,
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterGoalName;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hedef miktar
                  Text(
                    l10n.targetAmount,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [ThousandsSeparatorInputFormatter(locale: locale)],
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                      prefixText: '₺ ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterAmount;
                      }
                      final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
                        value,
                        locale,
                      );
                      if (amount <= 0) {
                        return l10n.pleaseEnterValidAmount;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Başlangıç miktarı
                  Text(
                    l10n.currentAmount,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _currentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [ThousandsSeparatorInputFormatter(locale: locale)],
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                      prefixText: '₺ ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hedef tarihi
                  Text(
                    l10n.targetDate,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectTargetDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _targetDate != null
                                ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                : l10n.selectDate,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _targetDate != null
                                  ? (isDark ? Colors.white : Colors.black)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: isDark 
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Renk seçimi
                  Text(
                    l10n.selectColor,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _availableColors.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final color = _availableColors[index];
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color, radix: 16)),
                              shape: BoxShape.circle,
                              border: isSelected 
                                  ? Border.all(
                                      color: isDark ? Colors.white : Colors.black,
                                      width: 2.5,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(int.parse(color, radix: 16))
                                      .withOpacity(isSelected ? 0.4 : 0.2),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Butonlar - Modern ve kompakt
                  Row(
                    children: [
                      // İptal
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.cancel,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8E8E93),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Kaydet
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _saveGoal,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: _isLoading 
                                    ? const Color(0xFF007AFF).withOpacity(0.5)
                                    : const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isLoading 
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF007AFF).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        l10n.save,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tarih seçici
  Future<void> _selectTargetDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 yıl
    );

    if (pickedDate != null) {
      setState(() {
        _targetDate = pickedDate;
      });
    }
  }

  /// Hedefi kaydet
  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;

      final targetAmount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _targetAmountController.text,
        locale,
      );
      final currentAmount = _currentAmountController.text.isNotEmpty
          ? ThousandsSeparatorInputFormatter.parseLocaleDouble(
              _currentAmountController.text,
              locale,
            )
          : 0.0;

      final goal = SavingsGoal(
        id: '', // Will be generated by Firebase
        userId: userId,
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: _selectedColor,
        category: _selectedCategory,
      );

      final savingsProvider = context.read<SavingsProvider>();
      final goalId = await savingsProvider.createGoal(goal);

      if (goalId != null && mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        
        // Success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.goalCreatedSuccessfully,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF34D399),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFFF453A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}


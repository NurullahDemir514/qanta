import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import 'savings_category_selector.dart';

/// Tasarruf hedefi düzenleme formu
class EditSavingsGoalForm extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback? onSuccess;

  const EditSavingsGoalForm({
    super.key,
    required this.goal,
    this.onSuccess,
  });

  @override
  State<EditSavingsGoalForm> createState() => _EditSavingsGoalFormState();
}

class _EditSavingsGoalFormState extends State<EditSavingsGoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  
  String? _selectedCategory;
  late String? _selectedEmoji;
  DateTime? _targetDate;
  bool _isLoading = false;
  
  // Renkler
  final List<String> _availableColors = [
    'FF007AFF', // Blue
    'FF34D399', // Green
    'FFFF9500', // Orange
    'FFFF453A', // Red
    'FFBF5AF2', // Purple
    'FF00C7BE', // Teal
    'FFFFD60A', // Yellow
    'FFFF375F', // Pink
  ];
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    
    // Mevcut değerleri doldur
    _nameController = TextEditingController(text: widget.goal.name);
    _targetAmountController = TextEditingController(
      text: widget.goal.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _selectedCategory = widget.goal.category;
    _selectedEmoji = widget.goal.emoji;
    _targetDate = widget.goal.targetDate;
    _selectedColor = widget.goal.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      
      final targetAmount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _targetAmountController.text,
        locale,
      );

      final savingsProvider = context.read<SavingsProvider>();
      
      // Updated goal with new values
      final updatedGoal = widget.goal.copyWith(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        category: _selectedCategory,
        emoji: _selectedEmoji,
        color: _selectedColor,
        targetDate: _targetDate,
      );
      
      final success = await savingsProvider.updateGoal(
        widget.goal.id,
        updatedGoal,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Birikim hedefi güncellendi!'),
              backgroundColor: Color(0xFF34D399),
            ),
          );
          Navigator.of(context).pop();
          widget.onSuccess?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savingsProvider.error ?? 'Güncelleme başarısız!'),
              backgroundColor: const Color(0xFFFF4C4C),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4C4C),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
                  const SizedBox(height: 16),
                  
                  // Başlık
                  Text(
                    l10n.editSavingsGoal,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // İsim
                  Text(
                    l10n.savingsName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterGoalNameHint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterGoalNameError;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Hedef tutar
                  Text(
                    l10n.targetAmount,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      ThousandsSeparatorInputFormatter(
                        locale: Provider.of<ThemeProvider>(context, listen: false).currency.locale,
                      ),
                    ],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterAmount,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterAmount;
                      }
                      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                      final locale = themeProvider.currency.locale;
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
                  
                  const SizedBox(height: 20),
                  
                  // Kategori (İsteğe Bağlı)
                  Row(
                    children: [
                      Text(
                        l10n.category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.optionalField,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SavingsCategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Hedef tarih
                  Text(
                    l10n.targetDate,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _targetDate = selectedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _targetDate != null
                                ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                : l10n.selectDateHint,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (_targetDate != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _targetDate = null;
                                });
                              },
                              child: Icon(
                                Icons.clear,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Renk seçimi
                  Text(
                    l10n.color,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableColors.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final colorHex = _availableColors[index];
                        final isSelected = _selectedColor == colorHex;
                        final color = Color(int.parse('0x$colorHex'));
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = colorHex;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Kaydet butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              l10n.update,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


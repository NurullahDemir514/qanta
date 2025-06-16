import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/constants/app_constants.dart';

class AddCreditCardForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddCreditCardForm({
    super.key,
    this.onSuccess,
  });

  @override
  State<AddCreditCardForm> createState() => _AddCreditCardFormState();
}

class _AddCreditCardFormState extends State<AddCreditCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _totalDebtController = TextEditingController();

  String? _selectedBankCode;
  int _statementDate = 1;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNameController.dispose();
    _creditLimitController.dispose();
    _totalDebtController.dispose();
    super.dispose();
  }

  void _onBankSelected(String bankCode) {
    setState(() {
      _selectedBankCode = bankCode;
      // Auto-generate card name when bank is selected
      final bankName = AppConstants.getBankName(bankCode);
      _cardNameController.text = '$bankName Kredi Kartı';
    });
  }

  int _calculateDueDate(int statementDate) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Ekstre tarihini bul
    DateTime statementDateTime = DateTime(currentYear, currentMonth, statementDate);
    
    // Eğer bu ayın ekstre tarihi geçmişse, gelecek aya al
    if (statementDateTime.isBefore(now)) {
      if (currentMonth == 12) {
        statementDateTime = DateTime(currentYear + 1, 1, statementDate);
      } else {
        statementDateTime = DateTime(currentYear, currentMonth + 1, statementDate);
      }
    }
    
    // Ekstre tarihinden 10 gün sonra
    DateTime tentativeDueDate = statementDateTime.add(const Duration(days: 10));
    
    // İlk hafta içi günü bul (Pazartesi=1, Salı=2, ..., Cuma=5)
    DateTime dueDate = tentativeDueDate;
    while (dueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      dueDate = dueDate.add(const Duration(days: 1));
    }
    
    return dueDate.day;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedBankCode == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final unifiedProvider = context.read<UnifiedProviderV2>();
      
      final creditLimit = double.tryParse(_creditLimitController.text.replaceAll(',', '')) ?? 0.0;
      final totalDebt = _totalDebtController.text.trim().isEmpty 
          ? 0.0 
          : double.tryParse(_totalDebtController.text.replaceAll(',', '')) ?? 0.0;

      final success = await unifiedProvider.createAccount(
        type: AccountType.credit,
        name: _cardNameController.text.trim(),
        bankName: _selectedBankCode,
        balance: -totalDebt,
        creditLimit: creditLimit,
        statementDay: _statementDate,
        dueDay: _calculateDueDate(_statementDate),
      );

      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kredi kartı başarıyla eklendi',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error creating credit card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Kredi Kartı Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banka seçimi
                    Text(
                      'Banka',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBankGrid(),
                    
                    const SizedBox(height: 24),

                    // Kart adı
                    Text(
                      'Kart Adı',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cardNameController,
                      hintText: 'Örn: VakıfBank Kredi Kartı',
                      prefixIcon: Icons.credit_card,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kart adı gerekli';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Kredi limiti
                    Text(
                      'Kredi Limiti',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _creditLimitController,
                      hintText: '15.000',
                      prefixIcon: Icons.account_balance_wallet,
                      suffixText: context.watch<ThemeProvider>().currency.symbol,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kredi limiti gerekli';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Mevcut borç
                    Text(
                      'Mevcut Borç (Opsiyonel)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _totalDebtController,
                      hintText: '0',
                      prefixIcon: Icons.receipt_long,
                      suffixText: '₺',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                    ),

                    const SizedBox(height: 24),

                    // Ekstre günü
                    Text(
                      'Ekstre Günü',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatementDateDropdown(isDark),

                    // Son ödeme tarihi preview
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF007AFF),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Son Ödeme: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            _formatDueDate(_calculateDueDate(_statementDate)),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF1C1C1E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _submitForm,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Kredi Kartı Ekle',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankGrid() {
    final banks = AppConstants.getAvailableBanks();
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: banks.length,
        itemBuilder: (context, index) {
          final bankCode = banks[index];
          final bankName = AppConstants.getBankName(bankCode);
          final accentColor = AppConstants.getBankAccentColor(bankCode);
          final isSelected = _selectedBankCode == bankCode;
          
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index == banks.length - 1 ? 0 : 12),
            child: GestureDetector(
              onTap: () => _onBankSelected(bankCode),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? accentColor.withValues(alpha: 0.1)
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2C2C2E) 
                          : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? accentColor
                        : (Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF38383A) 
                            : const Color(0xFFE5E5EA)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bankName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? accentColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        suffixText: suffixText,
        suffixStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6D6D70),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildStatementDateDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _statementDate,
          isExpanded: true,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          items: List.generate(28, (index) => index + 1).map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('${value}. gün'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              _statementDate = newValue ?? 1;
            });
          },
        ),
      ),
    );
  }

  String _formatDueDate(int dueDay) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Ekstre tarihini bul
    DateTime statementDateTime = DateTime(currentYear, currentMonth, _statementDate);
    
    // Eğer bu ayın ekstre tarihi geçmişse, gelecek aya al
    if (statementDateTime.isBefore(now)) {
      if (currentMonth == 12) {
        statementDateTime = DateTime(currentYear + 1, 1, _statementDate);
      } else {
        statementDateTime = DateTime(currentYear, currentMonth + 1, _statementDate);
      }
    }
    
    // Ekstre tarihinden 10 gün sonra
    DateTime tentativeDueDate = statementDateTime.add(const Duration(days: 10));
    
    // İlk hafta içi günü bul (Pazartesi=1, Salı=2, ..., Cuma=5)
    DateTime dueDate = tentativeDueDate;
    while (dueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      dueDate = dueDate.add(const Duration(days: 1));
    }
    
    // Türkçe ay isimleri
    const monthNames = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return '${dueDate.day} ${monthNames[dueDate.month]}';
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/bank_service.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';

class EditCreditCardForm extends StatefulWidget {
  final dynamic creditCard; // Can be CreditCardModel or Map
  final VoidCallback? onSuccess;

  const EditCreditCardForm({
    super.key,
    required this.creditCard,
    this.onSuccess,
  });

  @override
  State<EditCreditCardForm> createState() => _EditCreditCardFormState();
}

class _EditCreditCardFormState extends State<EditCreditCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _totalDebtController = TextEditingController();

  String? _selectedBankCode;
  int _statementDate = 1;
  int _dueDate = 1;
  bool _isLoading = false;
  bool _isDebtMode = true; // true = borç, false = kullanılabilir limit
  List<BankModel> _availableBanks = [];
  bool _isLoadingBanks = false;

  // Helper methods to extract data from either CreditCardModel or Map
  String get cardId {
    if (widget.creditCard is Map) {
      return widget.creditCard['id'] as String;
    } else {
      return widget.creditCard.id;
    }
  }

  String get bankCode {
    if (widget.creditCard is Map) {
      return widget.creditCard['bankCode'] ?? 'qanta';
    } else {
      return widget.creditCard.bankCode;
    }
  }

  String? get cardName {
    if (widget.creditCard is Map) {
      return widget.creditCard['cardName'] as String?;
    } else {
      return widget.creditCard.cardName;
    }
  }

  double get creditLimit {
    if (widget.creditCard is Map) {
      return (widget.creditCard['creditLimit'] as num?)?.toDouble() ?? 0.0;
    } else {
      return widget.creditCard.creditLimit;
    }
  }

  double get totalDebt {
    if (widget.creditCard is Map) {
      return (widget.creditCard['totalDebt'] as num?)?.toDouble() ?? 0.0;
    } else {
      return widget.creditCard.totalDebt;
    }
  }

  int get statementDate {
    if (widget.creditCard is Map) {
      return widget.creditCard['statementDate'] as int? ?? 1;
    } else {
      return widget.creditCard.statementDate;
    }
  }

  int get dueDate {
    if (widget.creditCard is Map) {
      return widget.creditCard['dueDate'] as int? ?? 1;
    } else {
      return widget.creditCard.dueDate;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadBanks();
  }

  void _initializeForm() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedBankCode = bankCode;
    _cardNameController.text = cardName ?? '';
    _creditLimitController.text = CurrencyUtils.formatAmountWithoutSymbol(creditLimit, themeProvider.currency);
    
    // Initialize debt mode and set appropriate initial value
    _isDebtMode = true; // Default to debt mode
    _totalDebtController.text = CurrencyUtils.formatAmountWithoutSymbol(totalDebt, themeProvider.currency);
    
    _statementDate = statementDate;
    _dueDate = dueDate;
  }

  /// Bankaları yükle (dinamik)
  Future<void> _loadBanks() async {
    setState(() {
      _isLoadingBanks = true;
    });

    try {
      final bankService = BankService();
      await bankService.loadBanks();
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _availableBanks = bankService.getAvailableBanks(currency: themeProvider.currency);
      
      // Fallback: Eğer hiç banka yoksa static listeyi kullan
      if (_availableBanks.isEmpty) {
        final staticBanks = AppConstants.getAvailableBanks();
        _availableBanks = staticBanks.map((code) {
          return BankModel(
            code: code,
            name: AppConstants.getBankName(code),
            gradientColors: AppConstants.getBankGradientColors(code)
                .map((c) => c.value)
                .toList(),
            accentColor: AppConstants.getBankAccentColor(code).value,
            isActive: true,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading banks: $e');
      // Fallback: Static banks
      final staticBanks = AppConstants.getAvailableBanks();
      _availableBanks = staticBanks.map((code) {
        return BankModel(
          code: code,
          name: AppConstants.getBankName(code),
          gradientColors: AppConstants.getBankGradientColors(code)
              .map((c) => c.value)
              .toList(),
          accentColor: AppConstants.getBankAccentColor(code).value,
          isActive: true,
        );
      }).toList();
    } finally {
      setState(() {
        _isLoadingBanks = false;
      });
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _creditLimitController.dispose();
    _totalDebtController.dispose();
    super.dispose();
  }

  // Ekstre tarihinden otomatik son ödeme günü hesapla
  int _calculateDueDate(int statementDate) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Bu ayın ekstre tarihini hesapla
    DateTime currentStatementDate = DateTime(
      currentYear,
      currentMonth,
      statementDate,
    );

    // Bu ayın son ödeme tarihini hesapla
    DateTime currentDueDate = currentStatementDate.add(
      const Duration(days: 10),
    );
    // İlk hafta içi günü bul
    while (currentDueDate.weekday > 5) {
      // 6=Cumartesi, 7=Pazar
      currentDueDate = currentDueDate.add(const Duration(days: 1));
    }

    // Eğer bu ayın son ödeme tarihi henüz geçmemişse, bu ayın son ödeme gününü döndür
    if (currentDueDate.isAfter(now) || currentDueDate.isAtSameMomentAs(now)) {
      return currentDueDate.day;
    }

    // Eğer bu ayın son ödeme tarihi geçmişse, gelecek ayın hesaplamasını yap
    DateTime nextStatementDate;
    if (currentMonth == 12) {
      nextStatementDate = DateTime(currentYear + 1, 1, statementDate);
    } else {
      nextStatementDate = DateTime(
        currentYear,
        currentMonth + 1,
        statementDate,
      );
    }

    // Gelecek ayın son ödeme tarihini hesapla
    DateTime nextDueDate = nextStatementDate.add(const Duration(days: 10));
    while (nextDueDate.weekday > 5) {
      // 6=Cumartesi, 7=Pazar
      nextDueDate = nextDueDate.add(const Duration(days: 1));
    }

    return nextDueDate.day;
  }

  void _validateForm() {
    _formKey.currentState?.validate();
  }

  void _onToggleChanged(bool isDebtMode) {
    setState(() {
      _isDebtMode = isDebtMode;
      
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      
      // Convert the current value based on the new mode
      final currentValue = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _totalDebtController.text,
        locale,
      );
      final creditLimitValue = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _creditLimitController.text,
        locale,
      );
      
      if (isDebtMode) {
        // Switching to debt mode: current value is debt
        _totalDebtController.text = CurrencyUtils.formatAmountWithoutSymbol(currentValue, themeProvider.currency);
      } else {
        // Switching to limit mode: current value becomes available limit
        final availableLimit = creditLimitValue - currentValue;
        _totalDebtController.text = CurrencyUtils.formatAmountWithoutSymbol(availableLimit, themeProvider.currency);
      }
    });
  }

  Future<void> _submitForm() async {
    _validateForm();

    if (_selectedBankCode == null ||
        _creditLimitController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final unifiedProvider = context.read<UnifiedProviderV2>();
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;

      final creditLimit = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _creditLimitController.text,
        locale,
      );
      
      // Toggle'a göre hesaplama
      double totalDebt;
      if (_isDebtMode) {
        // Borç modu: Girilen değer borç
        totalDebt = _totalDebtController.text.trim().isEmpty
            ? 0.0
            : ThousandsSeparatorInputFormatter.parseLocaleDouble(
                _totalDebtController.text,
                locale,
              );
      } else {
        // Limit modu: Girilen değer kullanılabilir limit, borç = kredi limiti - kullanılabilir limit
        final availableLimit = _totalDebtController.text.trim().isEmpty
            ? 0.0
            : ThousandsSeparatorInputFormatter.parseLocaleDouble(
                _totalDebtController.text,
                locale,
              );
        totalDebt = creditLimit - availableLimit;
      }

      final success = await unifiedProvider.updateAccount(
        accountId: cardId,
        name: _cardNameController.text.trim().isEmpty
            ? null
            : _cardNameController.text.trim(),
        bankName: _selectedBankCode,
        balance: totalDebt, // Mevcut borç pozitif olarak kaydedilir
        creditLimit: creditLimit,
        statementDay: _statementDate,
        dueDay: _calculateDueDate(_statementDate),
      );

      if (success != null && mounted) {
        // Provider'ı refresh et
        await unifiedProvider.refresh();
        
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.creditCardUpdatedSuccessfully ?? 'Credit card updated successfully',
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

        // Callback çağır
        widget.onSuccess?.call();

        // Modal'ı kapat
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.updateErrorOccurred(e.toString()) ?? 'An error occurred during update: $e',
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

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return AppLocalizations.of(context)?.january ?? 'January';
      case 2:
        return AppLocalizations.of(context)?.february ?? 'February';
      case 3:
        return AppLocalizations.of(context)?.march ?? 'March';
      case 4:
        return AppLocalizations.of(context)?.april ?? 'April';
      case 5:
        return AppLocalizations.of(context)?.may ?? 'May';
      case 6:
        return AppLocalizations.of(context)?.june ?? 'June';
      case 7:
        return AppLocalizations.of(context)?.july ?? 'July';
      case 8:
        return AppLocalizations.of(context)?.august ?? 'August';
      case 9:
        return AppLocalizations.of(context)?.september ?? 'September';
      case 10:
        return AppLocalizations.of(context)?.october ?? 'October';
      case 11:
        return AppLocalizations.of(context)?.november ?? 'November';
      case 12:
        return AppLocalizations.of(context)?.december ?? 'December';
      default:
        throw Exception(AppLocalizations.of(context)?.invalidMonth ?? 'Invalid month');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  AppLocalizations.of(context)?.editCreditCard ?? 'Kredi Kartını Düzenle',
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    // Banka Seçimi
                    Text(
                      AppLocalizations.of(context)!.bank,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBankCode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: AppLocalizations.of(context)?.selectBank ?? 'Select bank',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        dropdownColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        items: _isLoadingBanks
                            ? [DropdownMenuItem(value: _selectedBankCode, child: const Text('Yükleniyor...'))]
                            : _availableBanks.map((bank) {
                                return DropdownMenuItem(
                                  value: bank.code,
                                  child: Text(
                                    bank.name,
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBankCode = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)?.pleaseSelectBank ?? 'Please select a bank';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Kart Adı
                    Text(
                      AppLocalizations.of(context)?.cardNameOptional ?? 'Card Name (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cardNameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)?.cardNameExample ?? 'E.g: My Work Card, Shopping Card',
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
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6D6D70),
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ekstre Günü
                    Text(
                      AppLocalizations.of(context)?.statementDayLabel ?? 'Statement Day',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _statementDate,
                          isExpanded: true,
                          hint: Text(
                            AppLocalizations.of(context)?.selectStatementDay ?? 'Select statement day',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          items: List.generate(28, (index) => index + 1).map((
                            int item,
                          ) {
                            return DropdownMenuItem<int>(
                              value: item,
                              child: Text('$item'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _statementDate = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Kredi Limiti
                    Text(
                      AppLocalizations.of(context)?.creditLimit ?? 'Credit Limit',
                      style: CurrencyUtils.getCurrencyTextStyle(
                        baseStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        currency: Currency.TRY,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final locale = themeProvider.currency.locale;
                        return TextFormField(
                          controller: _creditLimitController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(locale: locale)
                          ],
                          decoration: InputDecoration(
                            hintText: '50000',
                            suffixText: themeProvider.currency.symbol,
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
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : const Color(0xFFE5E5EA),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6D6D70),
                                width: 2,
                              ),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)?.creditLimitRequired ?? 'Credit limit is required';
                            }
                            final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
                              value,
                              locale,
                            );
                            if (amount <= 0) {
                              return AppLocalizations.of(context)?.pleaseEnterValidAmount ?? 'Please enter a valid amount';
                            }
                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Mevcut borç / Kullanılabilir limit toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isDebtMode 
                            ? (AppLocalizations.of(context)?.currentDebt ?? 'Current Debt')
                            : (AppLocalizations.of(context)?.availableLimit ?? 'Available Limit'),
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
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
                              // Borç Button
                              GestureDetector(
                                onTap: () => _onToggleChanged(true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: _isDebtMode
                                        ? const Color(0xFF007AFF)
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.debt ?? 'Debt',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isDebtMode
                                          ? Colors.white
                                          : isDark
                                              ? Colors.white.withValues(alpha: 0.6)
                                              : const Color(0xFF6D6D70),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              // Limit Button
                              GestureDetector(
                                onTap: () => _onToggleChanged(false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: !_isDebtMode
                                        ? const Color(0xFF007AFF)
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.limit ?? 'Limit',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: !_isDebtMode
                                          ? Colors.white
                                          : isDark
                                              ? Colors.white.withValues(alpha: 0.6)
                                              : const Color(0xFF6D6D70),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final locale = themeProvider.currency.locale;
                        return TextFormField(
                          controller: _totalDebtController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(locale: locale)
                          ],
                          decoration: InputDecoration(
                            hintText: _isDebtMode ? '0' : '0',
                            suffixText: themeProvider.currency.symbol,
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
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : const Color(0xFFE5E5EA),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6D6D70),
                                width: 2,
                              ),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF), // iOS Blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)?.update ?? 'Update',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

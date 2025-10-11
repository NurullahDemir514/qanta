import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_utils.dart';

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
  }

  void _initializeForm() {
    _selectedBankCode = bankCode;
    _cardNameController.text = cardName ?? '';
    _creditLimitController.text = creditLimit.toStringAsFixed(0);
    _totalDebtController.text = totalDebt.toStringAsFixed(0);
    _statementDate = statementDate;
    _dueDate = dueDate;
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

      final creditLimit =
          double.tryParse(_creditLimitController.text.replaceAll(',', '')) ??
          0.0;
      final totalDebt = _totalDebtController.text.trim().isEmpty
          ? 0.0
          : double.tryParse(_totalDebtController.text.replaceAll(',', '')) ??
                0.0;

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
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kredi kartı başarıyla güncellendi',
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
              'Güncelleme sırasında hata oluştu: $e',
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
        return 'Ocak';
      case 2:
        return 'Şubat';
      case 3:
        return 'Mart';
      case 4:
        return 'Nisan';
      case 5:
        return 'Mayıs';
      case 6:
        return 'Haziran';
      case 7:
        return 'Temmuz';
      case 8:
        return 'Ağustos';
      case 9:
        return 'Eylül';
      case 10:
        return 'Ekim';
      case 11:
        return 'Kasım';
      case 12:
        return 'Aralık';
      default:
        throw Exception('Geçersiz ay');
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
                  'Kredi Kartını Düzenle',
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
                          hintText: 'Banka seçin',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        dropdownColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        items: AppConstants.getAvailableBanks().map((bankCode) {
                          return DropdownMenuItem(
                            value: bankCode,
                            child: Text(
                              AppConstants.getBankName(bankCode),
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
                            return 'Lütfen bir banka seçin';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Kart Adı
                    Text(
                      'Kart Adı (Opsiyonel)',
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
                        hintText: 'Örn: İş Kartım, Alışveriş Kartı',
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
                      'Ekstre Günü',
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
                            'Ekstre günü seçin',
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
                      'Kredi Limiti (${Provider.of<ThemeProvider>(context, listen: false).currency.symbol})',
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
                    TextFormField(
                      controller: _creditLimitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '50000',
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
                          return 'Kredi limiti gerekli';
                        }
                        final amount = double.tryParse(
                          value.replaceAll(',', ''),
                        );
                        if (amount == null || amount <= 0) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Toplam Borç
                    Text(
                      'Toplam Borç (${Provider.of<ThemeProvider>(context, listen: false).currency.symbol})',
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
                    TextFormField(
                      controller: _totalDebtController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
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
                                'Güncelle',
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

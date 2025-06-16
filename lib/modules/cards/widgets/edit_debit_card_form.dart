import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/debit_card_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/debit_card_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';

class EditDebitCardForm extends StatefulWidget {
  final DebitCardModel debitCard;
  final VoidCallback? onSuccess;

  const EditDebitCardForm({
    super.key,
    required this.debitCard,
    this.onSuccess,
  });

  @override
  State<EditDebitCardForm> createState() => _EditDebitCardFormState();
}

class _EditDebitCardFormState extends State<EditDebitCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();

  String? _selectedBankCode;
  bool _isLoading = false;
  String? _lastFourDigitsError;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _selectedBankCode = widget.debitCard.bankCode;
    _cardNameController.text = widget.debitCard.cardName ?? '';
    _balanceController.text = widget.debitCard.balance.toStringAsFixed(0);
    _lastFourDigitsController.text = widget.debitCard.lastFourDigits ?? '';
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _balanceController.dispose();
    _lastFourDigitsController.dispose();
    super.dispose();
  }

  void _validateLastFourDigits(String value) {
    setState(() {
      if (value.isEmpty) {
        _lastFourDigitsError = null;
      } else if (value.length != 4) {
        _lastFourDigitsError = 'Son 4 hane tam olarak 4 rakam olmalıdır';
      } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
        _lastFourDigitsError = 'Sadece rakam girebilirsiniz';
      } else {
        _lastFourDigitsError = null;
      }
    });
  }

  void _validateForm() {
    _formKey.currentState?.validate();
    _validateLastFourDigits(_lastFourDigitsController.text);
  }

  Future<void> _submitForm() async {
    _validateForm();

    if (_selectedBankCode == null || 
        _balanceController.text.trim().isEmpty ||
        _lastFourDigitsError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debitCardProvider = context.read<DebitCardProvider>();
      
      final balance = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;

      final success = await debitCardProvider.updateDebitCard(
        cardId: widget.debitCard.id,
        cardName: _cardNameController.text.trim().isEmpty 
            ? null 
            : _cardNameController.text.trim(),
        lastFourDigits: _lastFourDigitsController.text.trim().isEmpty 
            ? null 
            : _lastFourDigitsController.text.trim(),
        balance: balance,
      );

      if (success && mounted) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Banka kartı başarıyla güncellendi',
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
                  'Banka Kartını Düzenle',
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
                    // Banka Seçimi
                    Text(
                      'Banka',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBankCode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'Banka seçin',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
                        hintText: 'Örn: Vadesiz Hesap, Ana Kart',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
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
                            color: Color(0xFF00FFB3),
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Son 4 Hane
                    Text(
                      'Son 4 Hane (Opsiyonel)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastFourDigitsController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '1234',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _lastFourDigitsError != null 
                                ? const Color(0xFFFF3B30)
                                : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _lastFourDigitsError != null 
                                ? const Color(0xFFFF3B30)
                                : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6D6D70),
                            width: 2,
                          ),
                        ),
                        counterText: '',
                        errorText: _lastFourDigitsError,
                      ),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onChanged: _validateLastFourDigits,
                    ),

                    const SizedBox(height: 20),

                    // Bakiye
                    Text(
                      'Bakiye (₺)',
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
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        hintText: '0,00',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
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
                            color: Color(0xFF00FFB3),
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bakiye gerekli';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount < 0) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
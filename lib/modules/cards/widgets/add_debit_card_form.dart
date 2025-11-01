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
import '../../../core/services/premium_service.dart';
import '../../../core/services/bank_service.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';

class AddDebitCardForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddDebitCardForm({super.key, this.onSuccess});

  @override
  State<AddDebitCardForm> createState() => _AddDebitCardFormState();
}

class _AddDebitCardFormState extends State<AddDebitCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedBankCode;
  List<String> _filteredBanks = [];
  List<BankModel> _availableBanks = [];
  bool _isLoading = false;
  bool _isLoadingBanks = false;
  
  late GoogleAdsRealBannerService _debitFormBannerService;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    
    // Initialize banner service
    _debitFormBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.addCardFormBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Load ad after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _debitFormBannerService.loadAd();
      }
    });
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _balanceController.dispose();
    _searchController.dispose();
    _debitFormBannerService.dispose();
    super.dispose();
  }

  /// Bankaları yükle (dinamik)
  Future<void> _loadBanks() async {
    setState(() {
      _isLoadingBanks = true;
    });

    try {
      final bankService = BankService();
      await bankService.loadBanks();

      // Kullanıcının para birimine göre bankaları önceliklendir
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

      _filteredBanks = _availableBanks.map((b) => b.code).toList();
    } catch (e) {
      debugPrint('❌ Error loading banks: $e');
      // Fallback: Static banks
      _filteredBanks = AppConstants.getAvailableBanks();
      _availableBanks = _filteredBanks.map((code) {
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

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = _availableBanks.map((b) => b.code).toList();
      } else {
        _filteredBanks = _availableBanks
            .where((bank) {
              return bank.name.toLowerCase().contains(query.toLowerCase()) ||
                  bank.code.toLowerCase().contains(query.toLowerCase());
            })
            .map((b) => b.code)
            .toList();
      }
    });
  }

  void _onBankSelected(String bankCode) {
    setState(() {
      _selectedBankCode = bankCode;
      // Auto-generate card name when bank is selected
      final bank = _availableBanks.firstWhere(
        (b) => b.code == bankCode,
        orElse: () => BankModel(
          code: bankCode,
          name: AppConstants.getBankName(bankCode),
          gradientColors: [],
          accentColor: 0xFF1976D2,
        ),
      );
      _cardNameController.text =
          '${bank.name} ${AppLocalizations.of(context)?.debitCard ?? 'Banka Kartı'}';
    });
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
      final themeProvider = context.read<ThemeProvider>();
      final locale = themeProvider.currency.locale;

      final balance = _balanceController.text.trim().isEmpty
          ? 0.0
          : ThousandsSeparatorInputFormatter.parseLocaleDouble(
              _balanceController.text,
              locale,
            );

      final success = await unifiedProvider.createAccount(
        type: AccountType.debit,
        name: _cardNameController.text.trim(),
        bankName: _selectedBankCode,
        balance: balance,
      );

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error creating debit card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.error ?? 'Error'}: $e',
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
                  AppLocalizations.of(context)?.addDebitCard ??
                      'Banka Kartı Ekle',
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
                    // Banka seçimi
                    Text(
                      AppLocalizations.of(context)?.bank ?? 'Bank',
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
                      AppLocalizations.of(context)?.cardName ?? 'Card Name',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cardNameController,
                      hintText:
                          AppLocalizations.of(context)?.cardNameExampleDebit ??
                          'E.g: VakıfBank Checking',
                      prefixIcon: Icons.credit_card,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                                context,
                              )?.cardNameRequired ??
                              'Card name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Başlangıç bakiyesi
                    Text(
                      AppLocalizations.of(context)?.initialBalance ??
                          'Initial Balance',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final locale = themeProvider.currency.locale;
                        return _buildTextField(
                          controller: _balanceController,
                          hintText: '0',
                          prefixIcon: Icons.account_balance_wallet,
                          suffixText: themeProvider.currency.symbol,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(locale: locale)
                          ],
                        );
                      },
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
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
                                              AppLocalizations.of(
                                                context,
                                              )?.addDebitCard ??
                                              'Banka Kartı Ekle',
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

                    const SizedBox(height: 24),
                    
                    // Banner ad
                    Consumer<PremiumService>(
                      builder: (context, premiumService, child) {
                        if (!premiumService.isPremium && 
                            _debitFormBannerService.isLoaded && 
                            _debitFormBannerService.bannerWidget != null) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: _debitFormBannerService.bannerWidget!,
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
    final l10n = AppLocalizations.of(context)!;
    // Filtrelenmiş bankaları al
    final filteredBankModels = _availableBanks.where((bank) {
      return _filteredBanks.contains(bank.code);
    }).toList();

    if (_isLoadingBanks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Arama kutusu
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _filterBanks,
            decoration: InputDecoration(
              hintText: l10n.searchBanks,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _filterBanks('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Banka listesi
        SizedBox(
          height: 80,
          child: filteredBankModels.isEmpty
              ? Center(
                  child: Text(
                    l10n.noBanksFound,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredBankModels.length,
                  itemBuilder: (context, index) {
                    final bank = filteredBankModels[index];
                    final bankCode = bank.code;
                    final bankName = bank.name;
                    final accentColor = bank.accentColorValue;
                    final isSelected = _selectedBankCode == bankCode;

                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(
                        right: index == filteredBankModels.length - 1 ? 0 : 12,
                      ),
                      child: GestureDetector(
                        onTap: () => _onBankSelected(bankCode),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.1)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF2F2F7)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
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
        ),
      ],
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
          borderSide: const BorderSide(color: Color(0xFF6D6D70), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

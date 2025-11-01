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

class AddCreditCardForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddCreditCardForm({super.key, this.onSuccess});

  @override
  State<AddCreditCardForm> createState() => _AddCreditCardFormState();
}

class _AddCreditCardFormState extends State<AddCreditCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _totalDebtController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedBankCode;
  int _statementDate = 1;
  List<String> _filteredBanks = [];
  List<BankModel> _availableBanks = [];
  bool _isDebtMode = true; // true = borç, false = kullanılabilir limit

  bool _isLoading = false;
  bool _isLoadingBanks = false;
  
  late GoogleAdsRealBannerService _creditFormBannerService;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    
    // Initialize banner service
    _creditFormBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.addCardFormBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Load ad after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _creditFormBannerService.loadAd();
      }
    });
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _creditLimitController.dispose();
    _totalDebtController.dispose();
    _searchController.dispose();
    _creditFormBannerService.dispose();
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
          '${bank.name} ${AppLocalizations.of(context)?.creditCard ?? 'Kredi Kartı'}';
    });
  }

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

      final success = await unifiedProvider.createAccount(
        type: AccountType.credit,
        name: _cardNameController.text.trim(),
        bankName: _selectedBankCode,
        balance: totalDebt, // Mevcut borç pozitif olarak kaydedilir
        creditLimit: creditLimit,
        statementDay: _statementDate,
        dueDay: _calculateDueDate(_statementDate),
      );

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error creating credit card: $e');
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)?.addCreditCard ??
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    const SizedBox(height: 8),
                    _buildBankGrid(),

                    const SizedBox(height: 16),

                    // Kart adı
                    Text(
                      AppLocalizations.of(context)?.cardName ?? 'Card Name',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _cardNameController,
                      hintText:
                          AppLocalizations.of(context)?.cardNameExample ??
                          'E.g: VakıfBank Credit Card',
                      prefixIcon: Icons.credit_card,
                      textInputAction: TextInputAction.next,
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

                    const SizedBox(height: 16),

                    // Kredi limiti
                    Text(
                      AppLocalizations.of(context)?.creditLimit ??
                          'Credit Limit',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final locale = themeProvider.currency.locale;
                        return _buildTextField(
                          controller: _creditLimitController,
                          hintText: '15.000',
                          prefixIcon: Icons.account_balance_wallet,
                          suffixText: themeProvider.currency.symbol,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(locale: locale)
                          ],
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(
                                    context,
                                  )?.creditLimitRequired ??
                                  'Credit limit is required';
                            }
                            final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
                              value,
                              locale,
                            );
                            if (amount <= 0) {
                              return AppLocalizations.of(
                                    context,
                                  )?.pleaseEnterValidAmount ??
                                  'Please enter a valid amount';
                            }
                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

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
                                onTap: () {
                                  setState(() {
                                    _isDebtMode = true;
                                  });
                                },
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
                                onTap: () {
                                  setState(() {
                                    _isDebtMode = false;
                                  });
                                },
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
                        return _buildTextField(
                          controller: _totalDebtController,
                          hintText: '0',
                          prefixIcon: _isDebtMode ? Icons.receipt_long : Icons.account_balance_wallet,
                          suffixText: themeProvider.currency.symbol,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(locale: locale)
                          ],
                          textInputAction: TextInputAction.done,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Ekstre günü
                    Text(
                      AppLocalizations.of(context)?.statementDay ??
                          'Statement Day',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHorizontalStatementDateSelector(isDark),

                    // Son ödeme tarihi preview
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF007AFF),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${AppLocalizations.of(context)?.lastPayment ?? 'Last Payment'}: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
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

                    const SizedBox(height: 20),

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
                                              )?.addCreditCard ??
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

                    const SizedBox(height: 24),
                    
                    // Banner ad
                    Consumer<PremiumService>(
                      builder: (context, premiumService, child) {
                        if (!premiumService.isPremium && 
                            _creditFormBannerService.isLoaded && 
                            _creditFormBannerService.bannerWidget != null) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: _creditFormBannerService.bannerWidget!,
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
    TextInputAction? textInputAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
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

  Widget _buildHorizontalStatementDateSelector(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 28,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = _statementDate == day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _statementDate = day;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: index < 27 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : isDark 
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF007AFF)
                      : isDark 
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _getDayText(day),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
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
              child: Text(_getDayText(value)),
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

  String _getDayText(int day) {
    final l10n = AppLocalizations.of(context)!;

    switch (day) {
      case 1:
        return l10n.firstDay.replaceAll('.', '');
      case 2:
        return l10n.secondDay.replaceAll('.', '');
      case 3:
        return l10n.thirdDay.replaceAll('.', '');
      case 4:
        return l10n.fourthDay.replaceAll('.', '');
      case 5:
        return l10n.fifthDay.replaceAll('.', '');
      case 6:
        return l10n.sixthDay.replaceAll('.', '');
      case 7:
        return l10n.seventhDay.replaceAll('.', '');
      case 8:
        return l10n.eighthDay.replaceAll('.', '');
      case 9:
        return l10n.ninthDay.replaceAll('.', '');
      case 10:
        return l10n.tenthDay.replaceAll('.', '');
      case 11:
        return l10n.eleventhDay.replaceAll('.', '');
      case 12:
        return l10n.twelfthDay.replaceAll('.', '');
      case 13:
        return l10n.thirteenthDay.replaceAll('.', '');
      case 14:
        return l10n.fourteenthDay.replaceAll('.', '');
      case 15:
        return l10n.fifteenthDay.replaceAll('.', '');
      case 16:
        return l10n.sixteenthDay.replaceAll('.', '');
      case 17:
        return l10n.seventeenthDay.replaceAll('.', '');
      case 18:
        return l10n.eighteenthDay.replaceAll('.', '');
      case 19:
        return l10n.nineteenthDay.replaceAll('.', '');
      case 20:
        return l10n.twentiethDay.replaceAll('.', '');
      case 21:
        return l10n.twentyFirstDay.replaceAll('.', '');
      case 22:
        return l10n.twentySecondDay.replaceAll('.', '');
      case 23:
        return l10n.twentyThirdDay.replaceAll('.', '');
      case 24:
        return l10n.twentyFourthDay.replaceAll('.', '');
      case 25:
        return l10n.twentyFifthDay.replaceAll('.', '');
      case 26:
        return l10n.twentySixthDay.replaceAll('.', '');
      case 27:
        return l10n.twentySeventhDay.replaceAll('.', '');
      case 28:
        return l10n.twentyEighthDay.replaceAll('.', '');
      default:
        return '$day ${l10n.day}';
    }
  }

  String _formatDueDate(int dueDay) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Bu ayın ekstre tarihini hesapla
    DateTime currentStatementDate = DateTime(
      currentYear,
      currentMonth,
      _statementDate,
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

    // Localized ay isimleri
    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      '',
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];

    // Eğer bu ayın son ödeme tarihi henüz geçmemişse, bu ayın son ödeme tarihini göster
    if (currentDueDate.isAfter(now) || currentDueDate.isAtSameMomentAs(now)) {
      return '${currentDueDate.day} ${monthNames[currentDueDate.month]}';
    }

    // Eğer bu ayın son ödeme tarihi geçmişse, gelecek ayın hesaplamasını yap
    DateTime nextStatementDate;
    if (currentMonth == 12) {
      nextStatementDate = DateTime(currentYear + 1, 1, _statementDate);
    } else {
      nextStatementDate = DateTime(
        currentYear,
        currentMonth + 1,
        _statementDate,
      );
    }

    // Gelecek ayın son ödeme tarihini hesapla
    DateTime nextDueDate = nextStatementDate.add(const Duration(days: 10));
    while (nextDueDate.weekday > 5) {
      // 6=Cumartesi, 7=Pazar
      nextDueDate = nextDueDate.add(const Duration(days: 1));
    }

    return '${nextDueDate.day} ${monthNames[nextDueDate.month]}';
  }
}

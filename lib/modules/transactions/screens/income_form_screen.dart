import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import '../models/payment_method.dart';
import '../models/card.dart';
import '../../../shared/models/cash_account.dart';
import '../../../shared/models/account_model.dart';
import '../widgets/forms/base_transaction_form.dart';
import '../widgets/forms/calculator_input_field.dart';
import '../widgets/forms/income_category_selector.dart';
import '../widgets/forms/income_payment_method_selector.dart';
import '../widgets/forms/transaction_summary.dart';
import '../widgets/forms/description_field.dart';
import '../widgets/forms/date_selector.dart';
import '../../advertisement/providers/advertisement_provider.dart';
import '../../advertisement/services/google_ads_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as ad_config;
import '../../advertisement/models/advertisement_models.dart';

class IncomeFormScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialDescription;
  final String? initialCategoryId;
  final String? initialPaymentMethodId;
  final DateTime? initialDate;
  final int initialStep;

  const IncomeFormScreen({
    super.key,
    this.initialAmount,
    this.initialDescription,
    this.initialCategoryId,
    this.initialPaymentMethodId,
    this.initialDate,
    this.initialStep = 0,
  });

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  String? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();

  String? _amountError;
  String? _categoryError;
  String? _paymentMethodError;
  bool _isLoading = false;
  int _currentStep = 0;

  // Banner servisleri
  GoogleAdsBannerService? _step1BannerService; // Step 1 için (Calculator altı)
  GoogleAdsBannerService? _step4BannerService; // Step 4 için

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _initializeWithQuickNoteData();
  }

  void _initializeWithQuickNoteData() {
    // Initialize amount if provided
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }

    // Initialize description if provided
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }

    // Initialize date if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    // Initialize category if provided
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      // URL'den gelen kategori decode et - hata durumunda raw değeri kullan
      try {
        final decodedCategory = Uri.decodeComponent(widget.initialCategoryId!);
        _selectedCategory = decodedCategory;
      } catch (e) {
        // Decode hatası varsa raw değeri kullan
        _selectedCategory = widget.initialCategoryId!;
      }
    }

    // Initialize payment method if provided
    if (widget.initialPaymentMethodId != null) {
      _initializePaymentMethod();
    }

    _initializeStep1Banner();
    _initializeStep4Banner();
  }

  // Step 1 için banner servisi başlat (Calculator altı)
  void _initializeStep1Banner() async {
    _step1BannerService = GoogleAdsBannerService(
      adUnitId: ad_config.AdvertisementConfig.transactionFormStep1Banner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: ad_config.AdvertisementConfig.transactionFormStep1Banner.isTestMode,
    );
    
    await _step1BannerService!.loadAd();
    
    if (mounted) {
      setState(() {});
    }
  }

  // Step 4 için ikinci banner servisi başlat
  void _initializeStep4Banner() async {
    _step4BannerService = GoogleAdsBannerService(
      adUnitId: ad_config.AdvertisementConfig.incomeTransferFormBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: ad_config.AdvertisementConfig.incomeTransferFormBanner.isTestMode,
    );
    
    await _step4BannerService!.loadAd();
    
    if (mounted) {
      setState(() {});
    }
  }

  void _initializePaymentMethod() async {
    if (widget.initialPaymentMethodId == null) return;

    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      await provider.loadAccounts();

      final account = provider.getAccountById(widget.initialPaymentMethodId!);
      if (account != null) {
        setState(() {
          if (account.type == AccountType.cash) {
            _selectedPaymentMethod = PaymentMethod(
              type: PaymentMethodType.cash,
              cashAccount: CashAccount(
                id: account.id,
                name: account.name,
                balance: account.balance,
                userId: account.userId,
                currency: 'TRY',
                createdAt: account.createdAt,
                updatedAt: account.updatedAt,
              ),
            );
          } else {
            _selectedPaymentMethod = PaymentMethod(
              type: PaymentMethodType.card,
              card: PaymentCard(
                id: account.id,
                name: account.name,
                number: '**** **** **** ****',
                expiryDate: '',
                type: account.type == AccountType.debit
                    ? CardType.debit
                    : CardType.credit,
                bankName: account.bankName ?? '',
                color: account.type == AccountType.debit
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFFF3B30),
                isActive: account.isActive,
              ),
            );
          }
        });
      }
    } catch (e) {}
  }

  List<String> _getStepTitles(AppLocalizations l10n) => [
    l10n.howMuchEarned,
    l10n.whichCategoryEarned,
    l10n.howDidYouReceive,
    l10n.details,
  ];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).currency.locale,
      symbol: Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).currency.symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Banner reklam ile content wrapper
  Widget _buildStepWithBanner(Widget content, {bool showBanner = false, bool useStep1Banner = false, bool useStep4Banner = false}) {
    final adProvider = context.watch<AdvertisementProvider>();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        
        // Banner Reklam (Step 1, Step 3, Step 4 için) - Premium kullanıcılara gösterilmez
        Consumer<PremiumService>(
          builder: (context, premiumService, child) {
            if (premiumService.isPremium) return const SizedBox.shrink();
            
            if (showBanner) {
              if (useStep1Banner && _step1BannerService != null && _step1BannerService!.isLoaded) {
                // Step 1 Banner (Calculator altı)
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 60,
                  alignment: Alignment.center,
                  child: _step1BannerService!.bannerWidget,
                );
              } else if (useStep4Banner && _step4BannerService != null && _step4BannerService!.isLoaded) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 60,
                  alignment: Alignment.center,
                  child: _step4BannerService!.bannerWidget,
                );
              } else if (!useStep1Banner && !useStep4Banner && adProvider.isInitialized && adProvider.adManager.bannerService.isLoaded) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 60,
                  alignment: Alignment.center,
                  child: adProvider.getBannerWidget(),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _step1BannerService?.dispose();
    _step4BannerService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseTransactionForm(
      title: l10n.incomeType,
      stepTitles: _getStepTitles(l10n),
      currentStep: _currentStep,
      pageController: _pageController,
      isLastStep: _currentStep == 3,
      isLoading: _isLoading,
      onNext: () => _validateAndNextStep(_currentStep),
      onBack: _goBackStep,
      onSave: _saveIncome,
      saveButtonText: l10n.saveIncome,
      steps: [
        // Step 1: Amount with Calculator
        BaseFormStep(
          title: l10n.howMuchEarned,
          content: _buildStepWithBanner(
            CalculatorInputField(
              controller: _amountController,
              errorText: _amountError,
              onChanged: () {
                setState(() {
                  _amountError = null;
                });
              },
            ),
            showBanner: true, // Step 1 banner'ı göster
            useStep1Banner: true, // Calculator altı banner
          ),
        ),

        // Step 2: Category
        BaseFormStep(
          title: l10n.whichCategoryEarned,
          content: IncomeCategorySelector(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
                _categoryError = null;
              });
            },
            errorText: _categoryError,
          ),
        ),

        // Step 3: Payment Method
        BaseFormStep(
          title: l10n.howDidYouReceive,
          content: _buildStepWithBanner(
            IncomePaymentMethodSelector(
              selectedPaymentMethod: _selectedPaymentMethod,
              onPaymentMethodSelected: (paymentMethod) {
                setState(() {
                  _selectedPaymentMethod = paymentMethod;
                  _paymentMethodError = null;
                });
              },
              errorText: _paymentMethodError,
            ),
            showBanner: true, // Banner Step 3'te göster
          ),
        ),

        // Step 4: Summary and Details
        BaseFormStep(
          title: l10n.details,
          content: _buildStepWithBanner(
            Column(
              children: [
                // Transaction Summary
                if (_selectedCategory != null && _selectedPaymentMethod != null)
                  TransactionSummary(
                    amount:
                        double.tryParse(
                          _amountController.text.replaceAll(',', '.'),
                        ) ??
                        0,
                    category: _selectedCategory!,
                    paymentMethod: _selectedPaymentMethod!.displayName,
                    date: _selectedDate,
                    isIncome: true,
                  ),

                const SizedBox(height: 24),

                // Description Field
                DescriptionField(
                  controller: _descriptionController,
                  hintText: l10n.exampleSalary,
                ),

                const SizedBox(height: 16),

                // Date Selector
                DateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ],
            ),
            showBanner: true, // Banner Step 4'te göster
            useStep4Banner: true, // Step 4'ün kendi banner'ını kullan
          ),
        ),
      ],
    );
  }

  void _goBackStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _validateAndNextStep(int currentStep) {
    bool isValid = true;

    switch (currentStep) {
      case 0: // Amount
        if (_amountController.text.isEmpty) {
          setState(() {
            _amountError =
                AppLocalizations.of(context)?.pleaseEnterAmount ??
                'Please enter an amount';
          });
          isValid = false;
        } else {
          final amount = double.tryParse(
            _amountController.text.replaceAll(',', '.'),
          );
          if (amount == null || amount <= 0) {
            setState(() {
              _amountError =
                  AppLocalizations.of(context)?.pleaseEnterValidAmount ??
                  'Please enter a valid amount';
            });
            isValid = false;
          }
        }
        break;
      case 1: // Category
        if (_selectedCategory == null) {
          setState(() {
            _categoryError =
                AppLocalizations.of(context)?.pleaseSelectCategory ??
                'Please select a category';
          });
          isValid = false;
        }
        break;
      case 2: // Payment Method
        if (_selectedPaymentMethod == null) {
          setState(() {
            _paymentMethodError =
                AppLocalizations.of(context)?.pleaseSelectPaymentMethod ??
                'Please select a payment method';
          });
          isValid = false;
        }
        break;
    }

    if (isValid) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveIncome() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

      // Tag'i category'ye çevir (otomatik oluştur)
      String? categoryId;
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        try {
          // Önce varolan kategoriyi ara - display name ile eşleştir
          final existingCategories = providerV2.categories
              .where(
                (cat) =>
                    cat.displayName.toLowerCase() == _selectedCategory!.toLowerCase() &&
                    cat.categoryType == CategoryType.income,
              )
              .toList();

          if (existingCategories.isNotEmpty) {
            categoryId = existingCategories.first.id;
          } else {
            // Yeni kategori oluştur
            // TODO: Implement with Firebase
            // Create new category using UnifiedProviderV2
            final newCategory = await providerV2.createCategory(
              type: CategoryType.income,
              name: _selectedCategory!,
              iconName: 'category',
              colorHex: '#6B7280',
            );
            categoryId = newCategory.id;
          }
        } catch (e) {
          // Kategori oluşturulamadıysa null olarak devam et
          categoryId = null;
        }
      }

      // Get account ID from payment method
      String? accountId;

      if (_selectedPaymentMethod!.isCash) {
        // Get cash account ID
        final cashAccounts = providerV2.cashAccounts;
        if (cashAccounts.isNotEmpty) {
          accountId = cashAccounts.first.id;
        }
      } else if (_selectedPaymentMethod!.card != null) {
        accountId = _selectedPaymentMethod!.card!.id;
      }

      if (accountId == null) {
        throw Exception(
          AppLocalizations.of(context)?.accountInfoNotFoundSingle ??
              'Account information could not be retrieved',
        );
      }

      // Create income transaction using v2 system
      final transactionId = await providerV2.createTransaction(
        type: v2.TransactionType.income,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? (AppLocalizations.of(context)?.income ?? 'Income')
            : _descriptionController.text.trim(),
        sourceAccountId: accountId,
        categoryId: categoryId,
        transactionDate: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context, transactionId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFFF3B30),
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

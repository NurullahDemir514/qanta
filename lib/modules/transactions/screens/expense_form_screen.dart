import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import '../models/payment_method.dart';
import '../models/card.dart';
import '../../../shared/models/cash_account.dart';
import '../../../shared/models/account_model.dart';
import '../widgets/forms/base_transaction_form.dart';
import '../widgets/forms/calculator_input_field.dart';
import '../widgets/forms/expense_category_selector_v2.dart';
import '../widgets/forms/expense_payment_method_selector.dart';
import '../widgets/forms/transaction_summary.dart';
import '../widgets/forms/description_field.dart';
import '../widgets/forms/date_selector.dart';
import '../../advertisement/providers/advertisement_provider.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as ad_config;
import '../../advertisement/models/advertisement_models.dart';
import '../../advertisement/services/google_ads_interstitial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../modules/transactions/models/recurring_frequency.dart';
import '../../../shared/models/recurring_transaction_model.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/providers/recurring_transaction_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/unified_transaction_service.dart';
import 'package:flutter/services.dart';

/// Expense transaction form using v2 provider system
///
/// Multi-step form for creating expense transactions with support for:
/// - Regular single payments
/// - Credit card installment payments
/// - All account types (cash, debit, credit)
///
/// **Form Steps:**
/// 1. **Amount Entry**: Calculator-style input with validation
/// 2. **Category Selection**: Expense categories from database
/// 3. **Payment Method**: Account selection with installment options
/// 4. **Details**: Summary, description, and date selection
///
/// **Key Features:**
/// - Step-by-step validation with error handling
/// - Installment support for credit cards (1-12 months)
/// - Real-time transaction summary
/// - Haptic feedback and smooth animations
/// - Comprehensive error handling
///
/// **Payment Method Support:**
/// - **Cash Accounts**: Direct balance deduction
/// - **Debit Cards**: Balance validation and deduction
/// - **Credit Cards**: Single payment or installments (1-12 months)
///
/// **Installment Logic:**
/// - Only available for credit cards
/// - Creates InstallmentTransaction for count > 1
/// - Creates regular Transaction for single payments
/// - Automatic monthly payment scheduling
///
/// **Dependencies:**
/// - [UnifiedProviderV2] for data management and transaction creation
/// - [CategoryModel] for expense categories
/// - [PaymentMethod] for account selection
/// - [BaseTransactionForm] for consistent form UI
///
/// **CHANGELOG:**
///
/// v2.1.0 (2024-01-XX):
/// - BREAKING: Migrated to v2 provider system
/// - Updated to use CategoryModel instead of ExpenseCategory enum
/// - Fixed transaction creation parameters
/// - Added proper installment transaction support
/// - Improved error handling and validation
///
/// v2.0.0 (2024-01-XX):
/// - Initial implementation with legacy provider
/// - Basic expense form with category and payment selection
///
/// **Breaking Changes:**
/// - Provider changed from UnifiedCardProvider to UnifiedProviderV2
/// - Category selector uses CategoryModel instead of ExpenseCategory
/// - Transaction creation API changed significantly
/// - Payment method selection updated to new PaymentMethod model
///
/// **Migration Notes:**
/// - Form UI remains the same for users
/// - Backend data structure completely changed
/// - All transactions now go through v2 system
/// - Better error handling and validation
///
/// **Performance:**
/// - Lazy loading of categories and accounts
/// - Efficient form validation
/// - Minimal rebuilds with proper state management
/// - Memory usage: ~5KB for form state
///
/// **See also:**
/// - [IncomeFormScreen] for income transactions
/// - [TransferFormScreen] for transfer transactions
/// - [UnifiedProviderV2] for data management
class ExpenseFormScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialDescription;
  final String? initialCategoryId;
  final String? initialPaymentMethodId;
  final DateTime? initialDate;
  final int initialStep;

  const ExpenseFormScreen({
    super.key,
    this.initialAmount,
    this.initialDescription,
    this.initialCategoryId,
    this.initialPaymentMethodId,
    this.initialDate,
    this.initialStep = 0,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  String? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();
  
  // Subscription state
  bool _isSubscription = false;
  RecurringCategory _subscriptionCategory = RecurringCategory.subscription;
  RecurringFrequency _subscriptionFrequency = RecurringFrequency.monthly;
  DateTime? _subscriptionEndDate;
  bool _hasSubscriptionEndDate = false;
  
  // Get subscription start date (use transaction date as start date)
  DateTime get _subscriptionStartDate => _selectedDate;

  String? _amountError;
  String? _categoryError;
  String? _paymentMethodError;
  bool _isLoading = false;
  int _currentStep = 0;

  // Banner servisleri
  GoogleAdsRealBannerService? _step1BannerService; // Step 1 için (Calculator altı)
  GoogleAdsRealBannerService? _step4BannerService; // Step 4 için
  
  // Success Interstitial servisi
  late GoogleAdsInterstitialService _successInterstitialService;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;

    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }

    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    
    // Initialize success interstitial service
    _successInterstitialService = GoogleAdsInterstitialService(
      adUnitId: ad_config.AdvertisementConfig.successInterstitial.interstitialAdUnitId,
      isTestMode: false,
    );
    _successInterstitialService.loadAd();

    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    if (widget.initialCategoryId != null) {
      try {
        _selectedCategory = Uri.decodeComponent(widget.initialCategoryId!);
      } catch (e) {
        _selectedCategory = widget.initialCategoryId!;
      }
    }

    _initializePaymentMethod();
    _initializeStep1Banner();
    _initializeStep4Banner();
  }

  // Step 1 için banner servisi başlat (Calculator altı)
  void _initializeStep1Banner() async {
    _step1BannerService = GoogleAdsRealBannerService(
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
    _step4BannerService = GoogleAdsRealBannerService(
      adUnitId: ad_config.AdvertisementConfig.expenseFormBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50, // Standart banner boyutu (320x50)
      isTestMode: ad_config.AdvertisementConfig.expenseFormBanner.isTestMode,
    );
    
    await _step4BannerService!.loadAd();
    
    // Banner yüklendiğinde widget'ı güncelle
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
    l10n.howMuchSpent,
    l10n.whichCategorySpent,
    l10n.howDidYouPay,
    l10n.details,
  ];

  void _nextStep() {
    if (_currentStep < 3) { // 4 step var: 0, 1, 2, 3 (son step 3)
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
                // Step 4 Banner (yerel)
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 60,
                  alignment: Alignment.center,
                  child: _step4BannerService!.bannerWidget,
                );
              } else if (!useStep1Banner && !useStep4Banner && adProvider.isInitialized && adProvider.adManager.bannerService.isLoaded) {
                // Step 3 Banner (ana provider)
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
    _step1BannerService?.dispose(); // Step 1 banner'ı temizle
    _step4BannerService?.dispose(); // Step 4 banner'ı temizle
    _successInterstitialService.dispose(); // Success interstitial temizle
    super.dispose();
  }
  
  /// Show success interstitial ad every 3 transactions
  Future<void> _showSuccessInterstitialIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionCount = prefs.getInt('expense_transaction_count') ?? 0;
      final newCount = transactionCount + 1;
      
      // Save new count
      await prefs.setInt('expense_transaction_count', newCount);
      
      // Show interstitial every 3 transactions
      if (newCount % 3 == 0 && _successInterstitialService.isLoaded) {
        await _successInterstitialService.showAd();
        // Reload for next time
        _successInterstitialService.loadAd();
      }
    } catch (e) {
      debugPrint('Error showing success interstitial: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseTransactionForm(
      title: l10n.expenseType,
      stepTitles: _getStepTitles(l10n),
      currentStep: _currentStep,
      pageController: _pageController,
      isLastStep: _currentStep == 3,
      isLoading: _isLoading,
      onNext: () => _validateAndNextStep(_currentStep),
      onBack: _goBackStep,
      onSave: _saveExpense,
      saveButtonText: l10n.saveExpense,
      steps: [
        // Step 1: Amount with Calculator
        BaseFormStep(
          title: l10n.howMuchSpent,
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
          title: l10n.whichCategorySpent,
          content: _buildStepWithBanner(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpenseCategorySelectorV2(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                      _categoryError = null;
                    });
                  },
                  errorText: _categoryError,
                  onNext: () {
                    // Move to next step when user presses next on keyboard
                    _nextStep();
                  },
                ),
                const SizedBox(height: 20),
                // Subscription checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isSubscription,
                        onChanged: (value) {
                          setState(() {
                            _isSubscription = value ?? false;
                            if (!_isSubscription) {
                              // Reset subscription fields when unchecked
                              _subscriptionCategory = RecurringCategory.subscription;
                              _subscriptionFrequency = RecurringFrequency.monthly;
                              _subscriptionEndDate = null;
                              _hasSubscriptionEndDate = false;
                            }
                          });
                        },
                        activeColor: const Color(0xFFFF4C4C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.thisIsSubscription,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  ],
                ),
                // Subscription fields (shown when checkbox is checked)
                if (_isSubscription) ...[
                  const SizedBox(height: 24),
                  _buildSubscriptionFields(context),
                ],
              ],
            ),
          ),
        ),

        // Step 3: Payment Method
        BaseFormStep(
          title: l10n.howDidYouPay,
          content: _buildStepWithBanner(
            ExpensePaymentMethodSelector(
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
                if (_amountController.text.isNotEmpty &&
                    _selectedCategory != null &&
                    _selectedPaymentMethod != null)
                  TransactionSummary(
                    amount: double.tryParse(_amountController.text) ?? 0,
                    categoryName: _selectedCategory!,
                    paymentMethodName: _getPaymentMethodDisplayName(),
                    date: _selectedDate,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    transactionType: l10n.expenseType,
                  ),

                const SizedBox(height: 24),

                // Additional Details
                DescriptionField(controller: _descriptionController),
                const SizedBox(height: 16),
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

  String _getPaymentMethodDisplayName() {
    if (_selectedPaymentMethod == null) return '';

    if (_selectedPaymentMethod!.isCash) {
      final accountName = _selectedPaymentMethod!.cashAccount?.name ?? '';
      // Localize CASH_WALLET identifier
      if (accountName == 'CASH_WALLET') {
        return AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap';
      }
      return accountName.isNotEmpty 
          ? accountName 
          : (AppLocalizations.of(context)?.cash ?? 'NAKİT');
    } else if (_selectedPaymentMethod!.card != null) {
      final cardName = _selectedPaymentMethod!.card!.name;
      final installments = _selectedPaymentMethod!.installments ?? 1;

      if (installments > 1) {
        return '$cardName ($installments ${AppLocalizations.of(context)?.installment_summary ?? 'Taksit'})';
      } else {
        return '$cardName (${AppLocalizations.of(context)?.cash ?? 'Peşin'})';
      }
    }

    return '';
  }

  void _validateAndNextStep(int currentStep) {
    bool isValid = true;
    final l10n = AppLocalizations.of(context)!;

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
        } else {
          final locale = Provider.of<ThemeProvider>(context, listen: false).currency.locale;
          final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
            _amountController.text,
            locale,
          );
          if (amount > 0) {
            String? error;
            if (_selectedPaymentMethod!.isCash) {
              final balance = _selectedPaymentMethod!.cashAccount?.balance ?? 0;
              if (balance < amount) {
                error = l10n.cashBalanceInsufficientWithAmount(_formatCurrency(balance));
              }
            } else if (_selectedPaymentMethod!.card != null) {
              final provider = Provider.of<UnifiedProviderV2>(
                context,
                listen: false,
              );
              final account = provider.getAccountById(
                _selectedPaymentMethod!.card!.id,
              );
              if (account != null) {
                if (account.type == AccountType.debit) {
                  if (account.balance < amount) {
                    error = l10n.debitCardBalanceInsufficientWithAmount(_formatCurrency(account.balance));
                  }
                } else if (account.type == AccountType.credit) {
                  final available = account.availableAmount;
                  if (available < amount) {
                    error = l10n.creditCardLimitInsufficientWithAmount(_formatCurrency(available));
                  }
                }
              }
            }
            if (error != null) {
              setState(() {
                _paymentMethodError = error;
              });
              isValid = false;
            }
          }
        }
        break;
      case 3: // Summary step - no validation needed
        // Summary step doesn't need validation, just proceed
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

  /// Saves expense transaction with installment support
  ///
  /// **Transaction Creation Logic:**
  ///
  /// **For Installment Payments (installments > 1):**
  /// - Uses `createInstallmentTransaction()` method
  /// - Creates parent InstallmentTransaction record
  /// - Generates monthly InstallmentDetail records
  /// - Only available for credit cards
  /// - Automatic payment scheduling
  ///
  /// **For Single Payments (installments = 1):**
  /// - Uses `createTransaction()` method
  /// - Creates single Transaction record
  /// - Immediate balance/limit update
  /// - Available for all account types
  ///
  /// **Account ID Resolution:**
  /// - Cash accounts: `paymentMethod.cashAccount.id`
  /// - Card accounts: `paymentMethod.card.id`
  /// - Validates account exists before proceeding
  ///
  /// **Data Validation:**
  /// - Amount: Must be > 0
  /// - Category: Must be selected
  /// - Payment method: Must be selected
  /// - Description: Optional, defaults to "Expense"
  ///
  /// **Error Handling:**
  /// - Form validation errors: Prevents save
  /// - Network errors: Shows error snackbar
  /// - Account resolution errors: Shows specific message
  /// - Provider errors: Logged and displayed to user
  ///
  /// **Success Flow:**
  /// - Shows success snackbar with amount
  /// - Navigates back to previous screen
  /// - Provider automatically refreshes data
  ///
  /// **State Management:**
  /// - Sets loading state during operation
  /// - Prevents double-submission
  /// - Clears loading state in finally block
  /// Build subscription fields widget
  Widget _buildSubscriptionFields(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category selection
        Text(
          l10n.category ?? 'Kategori',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RecurringCategory.values.map((category) {
              final isSelected = _subscriptionCategory == category;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _subscriptionCategory = category);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)),
                      width: isSelected ? 2 : 1.2,
                    ),
                  ),
                  child: Text(
                    category.getName(l10n),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        
        // Frequency selection
        Text(
          l10n.frequency,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1.2,
            ),
          ),
          child: Row(
            children: RecurringFrequency.values.map((frequency) {
              final isSelected = _subscriptionFrequency == frequency;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _subscriptionFrequency = frequency);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        frequency.getDisplayName(l10n),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        
        // Start date
        Text(
          l10n.startDate,
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
              initialDate: _subscriptionStartDate,
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
            if (pickedDate != null && pickedDate != _selectedDate) {
              setState(() {
                _selectedDate = pickedDate; // Update transaction date (used as subscription start date)
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
                    '${_subscriptionStartDate.day.toString().padLeft(2, '0')}/${_subscriptionStartDate.month.toString().padLeft(2, '0')}/${_subscriptionStartDate.year}',
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
        
        // End date (optional)
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _hasSubscriptionEndDate,
              onChanged: (value) {
                setState(() {
                  _hasSubscriptionEndDate = value ?? false;
                  if (!_hasSubscriptionEndDate) {
                    _subscriptionEndDate = null;
                  } else if (_subscriptionEndDate == null) {
                    _subscriptionEndDate = _subscriptionStartDate.add(const Duration(days: 365));
                  }
                });
              },
            ),
            Text(
              l10n.endDateOptional,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        if (_hasSubscriptionEndDate) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _subscriptionEndDate ?? _subscriptionStartDate.add(const Duration(days: 365)),
                firstDate: _subscriptionStartDate,
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
              if (pickedDate != null && pickedDate != _subscriptionEndDate) {
                setState(() {
                  _subscriptionEndDate = pickedDate;
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
                      _subscriptionEndDate != null
                          ? '${_subscriptionEndDate!.day.toString().padLeft(2, '0')}/${_subscriptionEndDate!.month.toString().padLeft(2, '0')}/${_subscriptionEndDate!.year}'
                          : l10n.selectDate ?? 'Tarih Seç',
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
        ],
      ],
    );
  }

  ///
  /// **CHANGELOG:**
  /// v2.1.0: Fixed parameter names and transaction creation
  /// v2.0.0: Migrated to UnifiedProviderV2 system
  void _saveExpense() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _amountController.text,
        locale,
      );
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
                    cat.categoryType == CategoryType.expense,
              )
              .toList();

          if (existingCategories.isNotEmpty) {
            categoryId = existingCategories.first.id;
          } else {
            // Yeni kategori oluştur
            // TODO: Implement with Firebase
            // Create new category using UnifiedProviderV2
            final newCategory = await providerV2.createCategory(
              type: CategoryType.expense,
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

      // Hesap ID'sini al
      final sourceAccountId = _selectedPaymentMethod!.isCash
          ? _selectedPaymentMethod!.cashAccount!.id
          : _selectedPaymentMethod!.card!.id;

      final description = _descriptionController.text.trim().isEmpty
          ? (AppLocalizations.of(context)?.expense ?? 'Expense')
          : _descriptionController.text.trim();

      String? transactionId;

      // If subscription is selected, create subscription first, then first transaction
      if (_isSubscription) {
        final userId = FirebaseAuthService.currentUserId;
        if (userId == null) {
          throw Exception('Kullanıcı oturumu bulunamadı');
        }

        // Create subscription name from category name (Step 2 selection)
        final subscriptionName = _selectedCategory ?? description;
        final now = DateTime.now();
        final subscription = RecurringTransaction(
          id: '', // Will be generated by service
          userId: userId,
          name: subscriptionName,
          category: _subscriptionCategory,
          amount: amount,
          categoryId: categoryId ?? _subscriptionCategory.name,
          accountId: sourceAccountId,
          frequency: _subscriptionFrequency,
          startDate: _subscriptionStartDate,
          endDate: _hasSubscriptionEndDate ? _subscriptionEndDate : null,
          isActive: true,
          lastExecutedDate: null,
          nextExecutionDate: null, // Will be calculated by provider
          description: null,
          notes: null,
          createdAt: now,
          updatedAt: now,
        );

        // Create subscription
        final subscriptionProvider = Provider.of<RecurringTransactionProvider>(
          context,
          listen: false,
        );
        final subscriptionId = await subscriptionProvider.createSubscription(subscription);
        
        if (subscriptionId == null) {
          throw Exception('Abonelik oluşturulamadı');
        }

        // Create first transaction on start date
        // Only create if start date is today or earlier
        final today = DateTime.now();
        final startDateOnly = DateTime(
          _subscriptionStartDate.year,
          _subscriptionStartDate.month,
          _subscriptionStartDate.day,
        );
        final todayOnly = DateTime(today.year, today.month, today.day);

        if (!todayOnly.isBefore(startDateOnly)) {
          // Start date has arrived, create transaction
          final l10n = AppLocalizations.of(context)!;
          final transactionDescription = '$description (${l10n.automatic})';
          
          // Get account for display name
          final account = providerV2.getAccountById(sourceAccountId);
          String? accountDisplayName;
          String? accountTypeDisplayName;
          if (account != null) {
            accountDisplayName = account.type == AccountType.cash 
                ? 'CASH_WALLET' 
                : account.name;
            accountTypeDisplayName = account.typeDisplayName;
          }
          
          // Create transaction directly with isRecurring flag
          final firstTransaction = v2.TransactionWithDetailsV2(
            id: '', // Will be generated by Firebase
            userId: '', // Will be set by service
            type: v2.TransactionType.expense,
            amount: amount,
            description: transactionDescription,
            transactionDate: _subscriptionStartDate,
            categoryId: categoryId,
            sourceAccountId: sourceAccountId,
            isRecurring: true, // Mark as recurring transaction
            notes: l10n.createdAutomatically,
            isPaid: true,
            createdAt: _subscriptionStartDate,
            updatedAt: _subscriptionStartDate,
            sourceAccountName: accountDisplayName,
            sourceAccountType: accountTypeDisplayName,
            // Add category name (from Step 2 category selection)
            categoryName: subscriptionName,
          );
          
          transactionId = await UnifiedTransactionService.addTransaction(firstTransaction);
          
          // Manually trigger UI refresh by reloading transactions
          await providerV2.loadTransactions();
          
          // Update subscription last executed date and next execution date
          final nextExecutionDate = RecurringTransaction(
            id: subscriptionId,
            userId: userId,
            name: subscriptionName,
            category: _subscriptionCategory,
            amount: amount,
            accountId: sourceAccountId,
            frequency: _subscriptionFrequency,
            startDate: _subscriptionStartDate,
            endDate: _hasSubscriptionEndDate ? _subscriptionEndDate : null,
            categoryId: categoryId ?? _subscriptionCategory.name,
            isActive: true,
            lastExecutedDate: _subscriptionStartDate,
            nextExecutionDate: null, // Will be calculated
            createdAt: now,
            updatedAt: DateTime.now(),
          ).calculateNextExecutionDate();
          
          final updatedSubscription = subscription.copyWith(
            id: subscriptionId,
            lastExecutedDate: _subscriptionStartDate,
            nextExecutionDate: nextExecutionDate,
            updatedAt: DateTime.now(),
          );
          await subscriptionProvider.updateSubscription(subscriptionId, updatedSubscription);
        }
        
        debugPrint('✅ Created subscription $subscriptionId with first transaction');
      } else {
        // Normal transaction (not subscription)
        // Taksit sayısını al
        final installments = _selectedPaymentMethod!.installments ?? 1;

        // Kredi kartı işlemleri için her zaman taksitli sistem kullan (peşin dahil)
        if (_selectedPaymentMethod!.card?.type == CardType.credit) {
          // Kredi kartı - her zaman taksitli sistem kullan (peşin = 1 taksit)
          final result = await providerV2.createInstallmentTransaction(
            sourceAccountId: sourceAccountId,
            totalAmount: amount,
            count: installments,
            description: description,
            categoryId: categoryId,
            startDate: _selectedDate,
          );
          
          transactionId = result['installmentId'];
          
          // Budget warnings are now shown in TransactionSummary widget
          // No need for snackbar here
        } else {
          // Banka kartı/nakit - normal işlem
          final result = await providerV2.createTransaction(
            type: v2.TransactionType.expense,
            amount: amount,
            description: description,
            sourceAccountId: sourceAccountId,
            categoryId: categoryId,
            transactionDate: _selectedDate,
          );
          
          transactionId = result['transactionId'];
          
          // Budget warnings are now shown in TransactionSummary widget
          // No need for snackbar here
        }
      }

      if (mounted) {
        // Show success interstitial every 3 transactions (only for non-premium users)
        final premiumService = context.read<PremiumService>();
        if (!premiumService.isPremium) {
          _showSuccessInterstitialIfNeeded();
        }
        
        Navigator.pop(context, transactionId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem eklenirken hata: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            duration: const Duration(seconds: 4),
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
}

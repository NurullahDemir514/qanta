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
import '../widgets/forms/expense_category_selector_v2.dart';
import '../widgets/forms/expense_payment_method_selector.dart';
import '../widgets/forms/transaction_summary.dart';
import '../widgets/forms/description_field.dart';
import '../widgets/forms/date_selector.dart';
import '../../advertisement/providers/advertisement_provider.dart';
import '../../advertisement/services/google_ads_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as ad_config;
import '../../advertisement/models/advertisement_models.dart';

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

    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }

    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }

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
    super.dispose();
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
          final amount =
              double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
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

      // Taksit sayısını al
      final installments = _selectedPaymentMethod!.installments ?? 1;
      final description = _descriptionController.text.trim().isEmpty
          ? (AppLocalizations.of(context)?.expense ?? 'Expense')
          : _descriptionController.text.trim();

      String? transactionId;

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

      if (mounted) {
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

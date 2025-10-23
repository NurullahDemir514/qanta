import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/models/account_model.dart';
import '../providers/stock_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../premium/premium_offer_screen.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../transactions/widgets/forms/base_transaction_form.dart';
import '../widgets/forms/stock_selection_step.dart';
import '../widgets/forms/stock_account_step.dart';
import '../widgets/forms/stock_calculator_step.dart';
import '../widgets/forms/stock_summary_step.dart';

/// Hisse işlem formu - Step by step
class StockTransactionFormScreen extends StatefulWidget {
  final StockTransactionType transactionType;
  final Stock? stock;

  const StockTransactionFormScreen({
    super.key,
    required this.transactionType,
    this.stock,
  });

  @override
  State<StockTransactionFormScreen> createState() =>
      _StockTransactionFormScreenState();
}

class _StockTransactionFormScreenState
    extends State<StockTransactionFormScreen> {
  final _pageController = PageController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  Stock? _selectedStock;
  AccountModel? _selectedAccount;
  double _quantity = 0.0;
  double _price = 0.0;
  double _commissionRate = 0.0; // %0 varsayılan komisyon
  List<double>? _historicalData;
  DateTime _selectedDate = DateTime.now(); // Tarih seçimi için

  String? _quantityError;
  String? _priceError;
  bool _isLoading = false;
  int _currentStep = 0;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    // Eğer hisse seçiliyse, onu ayarla
    if (widget.stock != null) {
      _selectedStock = widget.stock;
    }
    // Async işlemi build tamamlandıktan sonra çalıştır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWatchedStocks();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchedStocks() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) return;

      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.loadWatchedStocks(userId);
    } catch (e) {
      // Hata yönetimi
    }
  }

  Future<void> _loadHistoricalData() async {
    if (_selectedStock == null) return;

    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.loadHistoricalData(
        _selectedStock!.symbol,
        days: 30,
        forceReload: true,
      );

      // Geçmiş veriyi al
      final historicalData = stockProvider.getHistoricalData(
        _selectedStock!.symbol,
      );

      if (mounted) {
        setState(() {
          _historicalData = historicalData;
        });
      }

      // Not: loadHistoricalData zaten notifyListeners() çağırıyor
      // Bu sayede stocks screen'deki hisse kartları otomatik güncellenir
    } catch (e) {}
  }

  List<String> _getStepTitles() => [
    l10n.selectStock,
    l10n.selectAccount,
    l10n.quantityAndPrice,
    l10n.summary,
  ];

  void _goToNextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToPreviousStep() {
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

  /// Validates current step and advances to next step if valid
  ///
  /// **Validation Logic by Step:**
  ///
  /// **Step 0 (Stock Selection):**
  /// - Checks if stock is selected
  ///
  /// **Step 1 (Account Selection):**
  /// - Ensures account is selected
  ///
  /// **Step 2 (Quantity & Price):**
  /// - Validates quantity > 0
  /// - Validates price > 0
  /// - **Balance Validation for Purchase:**
  ///   - Cash accounts: balance ≥ total amount (including commission)
  ///   - Debit cards: balance ≥ total amount (including commission)
  ///   - Credit cards: available limit ≥ total amount (including commission)
  /// - **Quantity Validation for Sale:**
  ///   - Checks if user has enough stock quantity to sell
  ///
  /// **Step 3 (Summary):**
  /// - Final validation before execution
  ///
  /// **Error Handling:**
  /// - Sets appropriate error messages in state
  /// - Prevents navigation if validation fails
  /// - Shows detailed error messages for insufficient balance/quantity
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Hisse seçimi
        if (_selectedStock == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pleaseSelectStock),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 1: // Hesap seçimi
        if (_selectedAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pleaseSelectAccount),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 2: // Miktar ve Fiyat
        final quantity = double.tryParse(_quantityController.text);
        final price = double.tryParse(_priceController.text);

        bool isValid = true;

        // Validate quantity
        if (quantity == null || quantity <= 0) {
          setState(() {
            _quantityError = l10n.enterValidQuantity;
          });
          isValid = false;
        } else {
          setState(() {
            _quantity = quantity;
            _quantityError = null;
          });
        }

        // Validate price
        if (price == null || price <= 0) {
          setState(() {
            _priceError = l10n.enterValidPrice;
          });
          isValid = false;
        } else {
          setState(() {
            _price = price;
            _priceError = null;
          });
        }

        // If basic validation passed, check balance/quantity
        if (isValid && _selectedAccount != null) {
          final baseAmount = quantity! * price!;
          final commission = baseAmount * _commissionRate;
          final totalAmount = baseAmount + commission;

          if (widget.transactionType == StockTransactionType.buy) {
            // Balance validation for purchase
            String? balanceError = _validatePurchaseBalance(totalAmount);
            if (balanceError != null) {
              setState(() {
                _quantityError = balanceError;
              });
              isValid = false;
            }
          } else {
            // Quantity validation for sale
            String? quantityError = _validateSaleQuantity(quantity);
            if (quantityError != null) {
              setState(() {
                _quantityError = quantityError;
              });
              isValid = false;
            }
          }
        }

        return isValid;

      case 3: // Özet - Final validation
        if (_selectedStock == null || _selectedAccount == null) {
          return false;
        }

        // Final balance/quantity check before execution
        final baseAmount = _quantity * _price;
        final commission = baseAmount * _commissionRate;
        final totalAmount = baseAmount + commission;

        if (widget.transactionType == StockTransactionType.buy) {
          final balanceError = _validatePurchaseBalance(totalAmount);
          if (balanceError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(balanceError),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        } else {
          final quantityError = _validateSaleQuantity(_quantity);
          if (quantityError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(quantityError),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }

        return true;

      default:
        return true;
    }
  }

  /// Validates if account has sufficient balance for stock purchase
  /// 
  /// **Balance Validation Logic:**
  /// - Cash accounts: balance ≥ total amount (including commission)
  /// - Debit cards: balance ≥ total amount (including commission)  
  /// - Credit cards: available limit ≥ total amount (including commission)
  /// 
  /// Returns error message if insufficient balance, null if sufficient
  String? _validatePurchaseBalance(double totalAmount) {
    if (_selectedAccount == null) return null;

    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    final account = provider.getAccountById(_selectedAccount!.id);
    
    if (account == null) return null;

    switch (account.type) {
      case AccountType.cash:
        if (account.balance < totalAmount) {
          return l10n.stockPurchaseInsufficientBalance(_formatCurrency(account.balance));
        }
        break;
      case AccountType.debit:
        if (account.balance < totalAmount) {
          return l10n.stockPurchaseInsufficientBalance(_formatCurrency(account.balance));
        }
        break;
      case AccountType.credit:
        final availableLimit = account.availableAmount;
        if (availableLimit < totalAmount) {
          return l10n.stockPurchaseInsufficientBalance(_formatCurrency(availableLimit));
        }
        break;
    }

    return null; // Sufficient balance
  }

  /// Validates if user has sufficient stock quantity for sale
  /// 
  /// **Quantity Validation Logic:**
  /// - Checks user's current stock holdings
  /// - Ensures sale quantity ≤ available quantity
  /// 
  /// Returns error message if insufficient quantity, null if sufficient
  String? _validateSaleQuantity(double saleQuantity) {
    if (_selectedStock == null) return null;

    final provider = Provider.of<StockProvider>(context, listen: false);
    final stockPositions = provider.stockPositions;
    
    // Find user's current holding for this stock
    try {
      final userPosition = stockPositions.firstWhere(
        (position) => position.stockSymbol == _selectedStock!.symbol,
      );

      if (userPosition.totalQuantity < saleQuantity) {
        return l10n.stockSaleInsufficientQuantity(_formatQuantity(userPosition.totalQuantity));
      }
    } catch (e) {
      // Stock not found in positions
      return l10n.stockSaleInsufficientQuantity(_formatQuantity(0.0));
    }

    return null; // Sufficient quantity
  }

  /// Formats currency amount for display
  String _formatCurrency(double amount) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return CurrencyUtils.formatAmount(amount, themeProvider.currency);
  }

  /// Formats quantity for display
  String _formatQuantity(double quantity) {
    return quantity.toStringAsFixed(0);
  }

  Future<void> _executeTransaction() async {
    if (!_validateCurrentStep()) return;

    if (_selectedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectStock),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception(l10n.userSessionNotFound);
      }

      final baseAmount = _quantity * _price;
      final commission = baseAmount * _commissionRate;
      final totalAmount = baseAmount + commission; // Komisyon dahil toplam tutar

      final transaction = StockTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        stockSymbol: _selectedStock!.symbol,
        stockName: _selectedStock!.name,
        type: widget.transactionType,
        quantity: _quantity,
        price: _price,
        totalAmount: totalAmount,
        commission: commission,
        transactionDate: _selectedDate,
        notes: null,
        userId: userId,
        accountId: _selectedAccount?.id ?? '',
      );

      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.executeStockTransaction(transaction);

      // İşlem başarılı olduktan sonra grafik verilerini yükle
      if (_selectedStock != null) {
        await _loadHistoricalData();
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
    final l10n = AppLocalizations.of(context)!;

    return BaseTransactionForm(
      title: widget.transactionType == StockTransactionType.buy
          ? l10n.stockPurchase
          : l10n.stockSale,
      stepTitles: _getStepTitles(),
      currentStep: _currentStep,
      pageController: _pageController,
      isLastStep: _currentStep == 3,
      isLoading: _isLoading,
      onNext: _goToNextStep,
      onBack: _goToPreviousStep,
      onSave: _executeTransaction,
      saveButtonText: widget.transactionType == StockTransactionType.buy
          ? l10n.executePurchase
          : l10n.executeSale,
      steps: [
        // Step 1: Hisse seçimi
        BaseFormStep(
          title: _getStepTitles()[0],
          content: StockSelectionStep(
            selectedStock: _selectedStock,
            transactionType: widget.transactionType,
            onStockSelected: (Stock stock) async {
              // Yeni hisse AL işlemi için premium kontrolü (STEP 1'de)
              if (widget.transactionType == StockTransactionType.buy) {
                final stockProvider = Provider.of<StockProvider>(context, listen: false);
                final premiumService = Provider.of<PremiumService>(context, listen: false);
                
                // Hisse zaten portfolyoda mı kontrol et
                final existingPosition = stockProvider.stockPositions
                    .where((p) => p.stockSymbol == stock.symbol && p.totalQuantity > 0)
                    .firstOrNull;
                
                // Yeni hisse alınıyor (portfolyoda hiç yok veya 0 adet)
                if (existingPosition == null) {
                  // Takip listesindeki hisse sayısını kontrol et
                  final currentStockCount = stockProvider.watchedStocks.length;
                  
                  if (!premiumService.canAddStock(currentStockCount)) {
                    // Premium teklif ekranını göster
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumOfferScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                    return; // Hisse seçilmez, geri dön
                  }
                }
              }
              
              setState(() {
                _selectedStock = stock;
              });
              // Hisse seçildiğinde geçmiş veri çek
              _loadHistoricalData();
            },
          ),
        ),

        // Step 2: Hesap seçimi
        BaseFormStep(
          title: _getStepTitles()[1],
          content: StockAccountStep(
            selectedAccount: _selectedAccount,
            transactionType: widget.transactionType,
            onAccountSelected: (AccountModel account) {
              setState(() {
                _selectedAccount = account;
              });
            },
          ),
        ),

        // Step 3: Miktar ve Fiyat (Hesap Makinesi)
        BaseFormStep(
          title: _getStepTitles()[2],
          content: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return StockCalculatorStep(
                quantityController: _quantityController,
                priceController: _priceController,
                quantityError: _quantityError,
                priceError: _priceError,
                currencySymbol: themeProvider.currency.symbol,
                onChanged: () {
                  setState(() {
                    _quantityError = null;
                    _priceError = null;
                  });
                },
              );
            },
          ),
        ),

        // Step 4: Özet
        BaseFormStep(
          title: _getStepTitles()[3],
          content: _selectedStock != null
              ? StockSummaryStep(
                  stock: _selectedStock!,
                  account: _selectedAccount,
                  quantity: _quantity,
                  price: _price,
                  transactionType: widget.transactionType,
                  historicalData: _historicalData,
                  selectedDate: _selectedDate,
                  onCommissionRateChanged: (rate) {
                    setState(() {
                      _commissionRate = rate;
                    });
                  },
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                )
              : Center(child: Text(l10n.noStockSelected)),
        ),
      ],
    );
  }
}

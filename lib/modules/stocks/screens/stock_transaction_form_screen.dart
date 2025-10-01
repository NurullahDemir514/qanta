import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/models/account_model.dart';
import '../providers/stock_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/theme/theme_provider.dart';
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
  State<StockTransactionFormScreen> createState() => _StockTransactionFormScreenState();
}

class _StockTransactionFormScreenState extends State<StockTransactionFormScreen> {
  final _pageController = PageController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  Stock? _selectedStock;
  AccountModel? _selectedAccount;
  double _quantity = 0.0;
  double _price = 0.0;
  List<double>? _historicalData;
  
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
      await stockProvider.loadHistoricalData(_selectedStock!.symbol, days: 30, forceReload: true);
      
      // Geçmiş veriyi al
      final historicalData = stockProvider.getHistoricalData(_selectedStock!.symbol);
      
      if (mounted) {
        setState(() {
          _historicalData = historicalData;
        });
      }
      
      // Not: loadHistoricalData zaten notifyListeners() çağırıyor
      // Bu sayede stocks screen'deki hisse kartları otomatik güncellenir
    } catch (e) {
    }
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
        
        return isValid;
        
      default:
        return true;
    }
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

      final totalAmount = _quantity * _price;
      final commission = totalAmount * 0.001; // %0.1 komisyon

      final transaction = StockTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        stockSymbol: _selectedStock!.symbol,
        stockName: _selectedStock!.name,
        type: widget.transactionType,
        quantity: _quantity,
        price: _price,
        totalAmount: totalAmount,
        commission: commission,
        transactionDate: DateTime.now(),
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
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
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
    final l10n = AppLocalizations.of(context)!;
    
    return BaseTransactionForm(
      title: widget.transactionType == StockTransactionType.buy ? l10n.stockPurchase : l10n.stockSale,
      stepTitles: _getStepTitles(),
      currentStep: _currentStep,
      pageController: _pageController,
      isLastStep: _currentStep == 3,
      isLoading: _isLoading,
      onNext: _goToNextStep,
      onBack: _goToPreviousStep,
      onSave: _executeTransaction,
      saveButtonText: widget.transactionType == StockTransactionType.buy ? l10n.executePurchase : l10n.executeSale,
      steps: [
        // Step 1: Hisse seçimi
        BaseFormStep(
          title: _getStepTitles()[0],
          content: StockSelectionStep(
            selectedStock: _selectedStock,
            onStockSelected: (Stock stock) {
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
                )
              : Center(
                  child: Text(l10n.noStockSelected),
                ),
        ),
      ],
    );
  }
}

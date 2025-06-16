import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/models/category_model.dart';
import '../../../core/services/category_service_v2.dart';
import '../../../shared/widgets/insufficient_funds_dialog.dart';
import '../models/payment_method.dart';
import '../widgets/forms/base_transaction_form.dart';
import '../widgets/forms/calculator_input_field.dart';
import '../widgets/forms/income_category_selector.dart';
import '../widgets/forms/income_payment_method_selector.dart';
import '../widgets/forms/transaction_summary.dart';
import '../widgets/forms/description_field.dart';
import '../widgets/forms/date_selector.dart';

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({super.key});

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

  List<String> _getStepTitles(AppLocalizations l10n) => [
    l10n.howMuchEarned,
    l10n.whichCategoryEarned,
    l10n.howDidYouReceive,
    l10n.details,
  ];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
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
          content: CalculatorInputField(
            controller: _amountController,
            errorText: _amountError,
            onChanged: () {
              setState(() {
                _amountError = null;
              });
            },
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
          content: IncomePaymentMethodSelector(
            selectedPaymentMethod: _selectedPaymentMethod,
            onPaymentMethodSelected: (paymentMethod) {
              setState(() {
                _selectedPaymentMethod = paymentMethod;
                _paymentMethodError = null;
              });
            },
            errorText: _paymentMethodError,
          ),
        ),
        
        // Step 4: Summary and Details
        BaseFormStep(
          title: l10n.lastCheckAndDetails,
          content: Column(
            children: [
              // Transaction Summary
              if (_selectedCategory != null && _selectedPaymentMethod != null)
                TransactionSummary(
                  amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0,
                  category: _selectedCategory!,
                  paymentMethod: _selectedPaymentMethod!.displayName,
                  date: _selectedDate,
                  isIncome: true,
                ),
              
              const SizedBox(height: 24),
              
              // Description Field
              DescriptionField(
                controller: _descriptionController,
                hintText: 'Gelir açıklaması (opsiyonel)',
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
            _amountError = 'Lütfen bir tutar girin';
          });
          isValid = false;
        } else {
          final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
          if (amount == null || amount <= 0) {
            setState(() {
              _amountError = 'Geçerli bir tutar girin';
            });
            isValid = false;
          }
        }
        break;
      case 1: // Category
        if (_selectedCategory == null) {
          setState(() {
            _categoryError = 'Lütfen bir kategori seçin';
          });
          isValid = false;
        }
        break;
      case 2: // Payment Method
        if (_selectedPaymentMethod == null) {
          setState(() {
            _paymentMethodError = 'Lütfen bir ödeme yöntemi seçin';
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
          // Önce varolan kategoriyi ara
          final existingCategories = providerV2.categories
              .where((cat) => cat.name.toLowerCase() == _selectedCategory!.toLowerCase() && cat.type == CategoryType.income)
              .toList();
          
          if (existingCategories.isNotEmpty) {
            categoryId = existingCategories.first.id;
          } else {
            // Yeni kategori oluştur
            final newCategory = await CategoryServiceV2.createCategory(
              type: CategoryType.income,
              name: _selectedCategory!,
              icon: 'category',
              color: '#30B0C7',
            );
            categoryId = newCategory.id;
          }
        } catch (e) {
          // Kategori oluşturulamadıysa null olarak devam et
          print('Category creation failed: $e');
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
        throw Exception('Hesap bilgisi alınamadı');
      }
      
      // Create income transaction using v2 system
      await providerV2.createTransaction(
        type: v2.TransactionType.income,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty 
            ? 'Gelir' 
            : _descriptionController.text.trim(),
        sourceAccountId: accountId,
        categoryId: categoryId,
        transactionDate: _selectedDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir kaydedildi: ${_formatCurrency(amount)}'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
        Navigator.pop(context);
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
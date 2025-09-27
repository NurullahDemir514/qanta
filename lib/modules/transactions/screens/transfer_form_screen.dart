import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/widgets/insufficient_funds_dialog.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/payment_method.dart';
import '../models/transfer_model.dart';
import '../widgets/forms/base_transaction_form.dart';
import '../widgets/forms/calculator_input_field.dart';
import '../widgets/forms/transfer_account_selector.dart';
import '../widgets/forms/transaction_summary.dart';
import '../widgets/forms/description_field.dart';
import '../widgets/forms/date_selector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();
  
  PaymentMethod? _fromAccount;
  PaymentMethod? _toAccount;
  DateTime _selectedDate = DateTime.now();
  
  String? _amountError;
  String? _fromAccountError;
  String? _toAccountError;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Hesapları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
      if (cardProvider.creditCards.isEmpty && cardProvider.debitCards.isEmpty && cardProvider.cashAccount == null) {
        cardProvider.loadAllData();
      }
    });
  }

  List<String> _getStepTitles(AppLocalizations l10n) => [
    l10n.howMuchTransfer,
    l10n.fromWhichAccount,
    l10n.toWhichAccount,
    l10n.details,
  ];

  String _formatCurrency(double amount) {
    return Provider.of<ThemeProvider>(context, listen: false).formatAmount(amount);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BaseTransactionForm(
      title: l10n.transferType,
      stepTitles: _getStepTitles(l10n),
      currentStep: _currentStep,
      pageController: _pageController,
      isLastStep: _currentStep == 3,
      isLoading: _isLoading,
      onNext: () => _validateAndNextStep(_currentStep),
      onBack: _goBackStep,
      onSave: _saveTransfer,
      saveButtonText: l10n.saveTransfer,
      steps: [
        // Step 1: Amount with Calculator
        BaseFormStep(
          title: l10n.howMuchTransfer,
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
        
        // Step 2: From Account
        BaseFormStep(
          title: l10n.fromWhichAccount,
          content: TransferAccountSelector(
            selectedAccount: _fromAccount,
            onAccountSelected: (account) {
              setState(() {
                _fromAccount = account;
                _fromAccountError = null;
                // If same account selected for both, clear the other
                if (_toAccount == account) {
                  _toAccount = null;
                }
              });
            },
            errorText: _fromAccountError,
            excludeAccount: _toAccount,
            isSourceSelection: true,
          ),
        ),
        
        // Step 3: To Account
        BaseFormStep(
          title: l10n.toWhichAccount,
          content: TransferAccountSelector(
            selectedAccount: _toAccount,
            onAccountSelected: (account) {
              setState(() {
                _toAccount = account;
                _toAccountError = null;
                // If same account selected for both, clear the other
                if (_fromAccount == account) {
                  _fromAccount = null;
                }
              });
            },
            errorText: _toAccountError,
            excludeAccount: _fromAccount,
            isSourceSelection: false,
          ),
        ),
        
        // Step 4: Summary and Details
        BaseFormStep(
          title: l10n.details,
          content: Column(
            children: [
              // Transfer Preview Card
              if (_amountController.text.isNotEmpty && 
                  _fromAccount != null && 
                  _toAccount != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Transfer Amount
                      CurrencyUtils.buildAmountText(
                        double.tryParse(_amountController.text) ?? 0,
                        currency: Currency.TRY,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.transferType,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transfer Flow
                      Row(
                        children: [
                          // From Account
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _fromAccount!.isCash 
                                    ? const Color(0xFF34C759).withValues(alpha: 0.1)
                                    : (_fromAccount!.card?.color ?? const Color(0xFF8E8E93)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _fromAccount!.type.icon,
                                    color: _fromAccount!.isCash 
                                        ? const Color(0xFF34C759)
                                        : _fromAccount!.card?.color ?? const Color(0xFF8E8E93),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _fromAccount!.getDisplayName(l10n),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Arrow
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                              size: 24,
                            ),
                          ),
                          
                          // To Account
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _toAccount!.isCash 
                                    ? const Color(0xFF34C759).withValues(alpha: 0.1)
                                    : (_toAccount!.card?.color ?? const Color(0xFF8E8E93)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _toAccount!.type.icon,
                                    color: _toAccount!.isCash 
                                        ? const Color(0xFF34C759)
                                        : _toAccount!.card?.color ?? const Color(0xFF8E8E93),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _toAccount!.getDisplayName(l10n),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Additional Details
              DescriptionField(
                controller: _descriptionController,
              ),
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
        ),
      ],
    );
  }

  /// Validates current step and advances to next step if valid
  /// 
  /// **Validation Logic by Step:**
  /// 
  /// **Step 0 (Amount):**
  /// - Checks if amount is entered and > 0
  /// 
  /// **Step 1 (Source Account):**
  /// - Ensures source account is selected
  /// 
  /// **Step 2 (Target Account):**
  /// - Ensures target account is selected
  /// - Validates source ≠ target
  /// - **Balance Validation:**
  ///   - Cash accounts: balance ≥ transfer amount
  ///   - Debit cards: balance ≥ transfer amount
  /// - **Credit Card Overpayment Check:**
  ///   - Calculates current debt = creditLimit - availableLimit
  ///   - If transferAmount > currentDebt → shows overpayment warning
  ///   - User can choose to continue or cancel
  /// 
  /// **Credit Card Overpayment Logic:**
  /// ```
  /// Example:
        /// Credit Limit: 10,000₺
      /// Available Limit: 7,000₺
      /// Current Debt: 3,000₺ (10,000 - 7,000)
      /// Transfer Amount: 5,000₺
      /// Overpayment: 2,000₺ (5,000 - 3,000)
      /// Result: Card will have 2,000₺ positive balance
  /// ```
  /// 
  /// **Error Handling:**
  /// - Sets appropriate error messages in state
  /// - Prevents navigation if validation fails
  /// - Shows warning dialogs for overpayment scenarios
  void _validateAndNextStep(int currentStep) {
    bool isValid = true;

    switch (currentStep) {
      case 0: // Amount
        if (_amountController.text.isEmpty) {
          setState(() {
            _amountError = AppLocalizations.of(context)?.pleaseEnterAmount ?? 'Please enter an amount';
          });
          isValid = false;
        } else {
          final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
          if (amount == null || amount <= 0) {
            setState(() {
              _amountError = AppLocalizations.of(context)?.pleaseEnterValidAmount ?? 'Please enter a valid amount';
            });
            isValid = false;
          }
        }
        break;
      case 1: // From Account
        if (_fromAccount == null) {
          setState(() {
            _fromAccountError = AppLocalizations.of(context)?.pleaseSelectSourceAccount ?? 'Please select source account';
          });
          isValid = false;
        }
        break;
      case 2: // To Account
        if (_toAccount == null) {
          setState(() {
            _toAccountError = AppLocalizations.of(context)?.pleaseSelectTargetAccount ?? 'Please select target account';
          });
          isValid = false;
        } else if (_fromAccount == _toAccount) {
          setState(() {
            _toAccountError = AppLocalizations.of(context)?.sourceAndTargetSame ?? 'Source and target account cannot be the same';
          });
          isValid = false;
        } else {
          // Bakiye kontrolü yap
          final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
          if (amount > 0 && _fromAccount != null) {
            // Nakit hesap için bakiye kontrolü
            if (_fromAccount!.isCash && _fromAccount!.cashAccount != null) {
              if (_fromAccount!.cashAccount!.balance < amount) {
                setState(() {
                  _toAccountError = 'Yetersiz bakiye. Mevcut: ${_formatCurrency(_fromAccount!.cashAccount!.balance)}';
                });
                isValid = false;
              }
            }
            // Banka kartı için bakiye kontrolü
            else if (_fromAccount!.isCard && _fromAccount!.card != null) {
              final cardTypeString = _fromAccount!.card!.type.toString();
              if (cardTypeString.contains('debit')) {
                // Banka kartı bakiye kontrolü
                final cardProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
                try {
                  final debitCard = cardProvider.debitCards.firstWhere(
                    (card) => card['id'] == _fromAccount!.card!.id,
                  );
                  final balance = (debitCard['balance'] as num?)?.toDouble() ?? 0.0;
                  if (balance < amount) {
                    setState(() {
                      _toAccountError = 'Yetersiz bakiye. Mevcut: ${_formatCurrency(balance)}';
                    });
                    isValid = false;
                  }
                } catch (e) {
                  // Kart bulunamazsa devam et
                }
              }
            }
          }
          
          // Kredi kartı fazla ödeme kontrolü (hedef hesap için)
          if (isValid && _toAccount!.isCard && _toAccount!.card != null) {
            final cardTypeString = _toAccount!.card!.type.toString();
            if (cardTypeString.contains('credit')) {
              final cardProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
              try {
                final creditCard = cardProvider.creditCards.firstWhere(
                  (card) => card['id'] == _toAccount!.card!.id,
                );
                
                // Calculate current debt and check for overpayment
                final availableLimit = creditCard['availableLimit']?.toDouble() ?? 0.0;
                final creditLimit = creditCard['creditLimit']?.toDouble() ?? 0.0;
                final currentDebt = creditLimit - availableLimit;
                
                // If transfer amount is greater than current debt, show overpayment warning
                if (amount > currentDebt) {
                  final overpaymentAmount = amount - currentDebt;
                  // Show warning but allow user to continue
                  _showOverpaymentWarning(amount, currentDebt, overpaymentAmount, creditCard['cardName']);
                  return; // Don't auto-advance, let user decide
                }
              } catch (e) {
                // Card not found, continue normally
              }
            }
          }
        }
        break;
    }

    if (isValid && currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  /// Saves the transfer transaction using v2 provider system
  /// 
  /// **Process Flow:**
  /// 1. Validates required data (accounts, amount)
  /// 2. Extracts account IDs from PaymentMethod objects
  /// 3. Creates transfer transaction via UnifiedProviderV2
  /// 4. Detects and reports credit card overpayment
  /// 5. Shows success/error messages
  /// 6. Navigates back on success
  /// 
  /// **Account ID Resolution:**
  /// - Cash accounts: uses cashAccount.id
  /// - Card accounts: uses card.id
  /// - Throws exception if IDs cannot be resolved
  /// 
  /// **Overpayment Detection (Post-Transfer):**
  /// After successful transfer, checks if target is credit card:
  /// - Recalculates current debt = creditLimit - availableLimit
  /// - If transferAmount > originalDebt → overpayment occurred
  /// - Shows enhanced success message with overpayment details
  /// 
  /// **Error Handling:**
  /// - Network errors: Shows error snackbar
  /// - Validation errors: Prevents save operation
  /// - Account resolution errors: Shows specific error message
  /// 
  /// **State Management:**
  /// - Sets loading state during operation
  /// - Clears loading state in finally block
  /// - Updates UI via mounted check
  /// 
  /// **CHANGELOG:**
  /// v2.1.0: Fixed overpayment calculation logic
  /// v2.0.0: Migrated to UnifiedProviderV2.createTransaction()
  Future<void> _saveTransfer() async {
    if (_fromAccount == null || _toAccount == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Get source and target account IDs
      String? sourceAccountId;
      String? targetAccountId;
      
      // Determine source account ID
      if (_fromAccount!.isCash) {
        sourceAccountId = _fromAccount!.cashAccount?.id;
      } else if (_fromAccount!.isCard && _fromAccount!.card != null) {
        sourceAccountId = _fromAccount!.card!.id;
      }
      
      // Determine target account ID
      if (_toAccount!.isCash) {
        targetAccountId = _toAccount!.cashAccount?.id;
      } else if (_toAccount!.isCard && _toAccount!.card != null) {
        targetAccountId = _toAccount!.card!.id;
      }
      
      if (sourceAccountId == null || targetAccountId == null) {
        throw Exception(AppLocalizations.of(context)?.accountInfoNotFound ?? 'Account information could not be retrieved');
      }
      
      // Create transfer using v2 system
      await providerV2.createTransaction(
        type: v2.TransactionType.transfer,
        amount: amount,
        description: _descriptionController.text.isEmpty ? (AppLocalizations.of(context)?.transfer ?? 'Transfer') : _descriptionController.text,
        sourceAccountId: sourceAccountId,
        targetAccountId: targetAccountId,
        transactionDate: _selectedDate,
      );
      
      if (mounted) {
        // Check for overpayment after transfer
        bool isOverpayment = false;
        String? cardName;
        double overpaymentAmount = 0;
        
        if (_toAccount!.isCard && _toAccount!.card != null) {
          final cardTypeString = _toAccount!.card!.type.toString();
          if (cardTypeString.contains('credit')) {
            try {
              final creditCard = providerV2.creditCards.firstWhere(
                (card) => card['id'] == targetAccountId,
              );
              
              // Calculate current debt and check for overpayment
              final availableLimit = creditCard['availableLimit']?.toDouble() ?? 0.0;
              final creditLimit = creditCard['creditLimit']?.toDouble() ?? 0.0;
              final currentDebt = creditLimit - availableLimit;
              
              // If transfer amount is greater than current debt, it's overpayment
              if (amount > currentDebt) {
                isOverpayment = true;
                cardName = creditCard['cardName'];
                overpaymentAmount = amount - currentDebt;
              }
            } catch (e) {
              // Card not found, show normal message
            }
          }
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOverpayment 
                ? 'Transfer tamamlandı! $cardName kartına ${_formatCurrency(overpaymentAmount)} fazla ödeme yapıldı.'
                : 'Transfer başarıyla tamamlandı: ${_formatCurrency(amount)}',
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: Duration(seconds: isOverpayment ? 4 : 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer işlemi başarısız: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOverpaymentWarning(double amount, double currentDebt, double overpaymentAmount, String cardName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF9500),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fazla Ödeme Uyarısı',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu transfer $cardName kartına fazla ödeme yapacak.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
              const SizedBox(height: 16),
              
              // Transfer detayları
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transfer Tutarı:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _formatCurrency(amount),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mevcut Borç:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _formatCurrency(currentDebt),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fazla Ödeme:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                        Text(
                          _formatCurrency(overpaymentAmount),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '💡 Fazla ödeme kartınızda pozitif bakiye oluşturacak. Bu tutar sonraki harcamalarınızda kullanılabilir.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancelAction,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Transfer işlemini devam ettir
                if (_currentStep < 3) {
      setState(() {
                    _currentStep++;
      });
                  _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Devam Et',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 
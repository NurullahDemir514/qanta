import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/cash_account.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../models/payment_method.dart';
import '../../models/card.dart';
import '../../../../l10n/app_localizations.dart';

/// Payment method selector for expense transactions using v2 provider system
/// 
/// Displays all available payment methods for expense transactions including:
/// - Cash accounts with current balance
/// - Debit cards with current balance  
/// - Credit cards with available limit and installment options
/// 
/// **Key Features:**
/// - Real-time balance/limit display
/// - Installment selection for credit cards (1-12 months)
/// - Haptic feedback on selection
/// - Error handling and loading states
/// - Currency formatting with TRY symbol
/// - Responsive design with consistent styling
/// 
/// **Payment Method Types:**
/// 
/// **Cash Accounts:**
/// - Shows current balance
/// - Direct selection (no installments)
/// - Green color scheme
/// - Icon: payments_rounded
/// 
/// **Debit Cards:**
/// - Shows current balance
/// - Direct selection (no installments)
/// - Blue color scheme
/// - Icon: credit_card_rounded
/// 
/// **Credit Cards:**
/// - Shows available limit
/// - Installment selection modal (1-12 months)
/// - Red color scheme
/// - Icon: credit_card_rounded with chevron indicator
/// 
/// **Installment Logic:**
/// - Only available for credit cards
/// - Modal bottom sheet with 1-12 month options
/// - "Peşin" (cash) for 1 installment
/// - "X Taksit" for multiple installments
/// - Automatic PaymentMethod creation with installment count
/// 
/// **Data Flow:**
/// 1. Fetches accounts from UnifiedProviderV2
/// 2. Converts AccountModel to PaymentCard/CashAccount
/// 3. User selects payment method
/// 4. For credit cards: shows installment modal
/// 5. Creates PaymentMethod object with selection
/// 6. Calls onPaymentMethodSelected callback
/// 
/// **Error Handling:**
/// - Provider loading states
/// - Network error recovery
/// - Empty account lists
/// - Invalid account data
/// 
/// **Dependencies:**
/// - [UnifiedProviderV2] for account data
/// - [PaymentMethod] for selection model
/// - [CurrencyUtils] for amount formatting
/// - [AccountModel] for account data structure
/// 
/// **Performance:**
/// - Efficient list rendering with map operations
/// - Cached account data in provider
/// - Minimal rebuilds with Consumer pattern
/// - Lazy modal creation for installments
/// 
/// **CHANGELOG:**
/// 
/// v2.1.0 (2024-01-XX):
/// - BREAKING: Migrated to UnifiedProviderV2
/// - Added real-time balance display for all account types
/// - Improved installment selection UX
/// - Fixed currency formatting consistency
/// - Added proper error handling and loading states
/// 
/// v2.0.0 (2024-01-XX):
/// - Initial implementation with v2 provider integration
/// - Support for all account types
/// - Installment functionality for credit cards
/// 
/// **Breaking Changes:**
/// - Provider changed from UnifiedCardProvider to UnifiedProviderV2
/// - Account data structure changed from legacy format
/// - PaymentMethod model updated for v2 compatibility
/// 
/// **Usage:**
/// ```dart
/// ExpensePaymentMethodSelector(
///   selectedPaymentMethod: _selectedPaymentMethod,
///   onPaymentMethodSelected: (paymentMethod) {
///     setState(() => _selectedPaymentMethod = paymentMethod);
///   },
///   errorText: _paymentMethodError,
/// )
/// ```
/// 
/// **See also:**
/// - [IncomePaymentMethodSelector] for income-specific payment methods
/// - [TransferAccountSelector] for transfer account selection
/// - [PaymentMethod] for payment method data model
/// - [UnifiedProviderV2] for account data management
class ExpensePaymentMethodSelector extends StatefulWidget {
  /// Currently selected payment method, if any
  final PaymentMethod? selectedPaymentMethod;
  
  /// Callback fired when user selects a payment method
  /// 
  /// **Parameters:**
  /// - [PaymentMethod] paymentMethod: Complete payment method with account and installment info
  final Function(PaymentMethod) onPaymentMethodSelected;
  
  /// Error message to display below the payment method list
  /// 
  /// Typically used for form validation errors like "Please select a payment method"
  final String? errorText;

  const ExpensePaymentMethodSelector({
    super.key,
    this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.errorText,
  });

  @override
  State<ExpensePaymentMethodSelector> createState() => _ExpensePaymentMethodSelectorState();
}

class _ExpensePaymentMethodSelectorState extends State<ExpensePaymentMethodSelector> {
  
  // State for tracking selected card and installment options
  PaymentCard? _selectedCreditCard;
  int? _selectedInstallments;
  
  // Para formatı için yardımcı metod
  String _formatCurrency(double amount) {
    return CurrencyUtils.formatAmount(amount, Currency.TRY);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              children: [
                Text(
                  'Kartlar yüklenirken hata oluştu',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAllData(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        // Gider için tüm hesapları al
        final creditCards = provider.creditCards;
        final debitCards = provider.debitCards;
        final cashAccounts = provider.cashAccounts;

        return Column(
          children: [
            if (widget.errorText != null) ...[
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFF3B30),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Nakit hesapları
            ...cashAccounts.map((cashAccount) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentOption(
                  context: context,
                  title: l10n.cash,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF34C759),
                  isSelected: widget.selectedPaymentMethod?.isCash == true &&
                              widget.selectedPaymentMethod?.cashAccount?.id == cashAccount.id,
                  balance: cashAccount.balance,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    
                    // Clear credit card selection state
                    setState(() {
                      _selectedCreditCard = null;
                      _selectedInstallments = null;
                    });
                    
                    final cashMethod = PaymentMethod(
                      type: PaymentMethodType.cash,
                      cashAccount: _convertAccountToCashAccount(cashAccount),
                    );
                    widget.onPaymentMethodSelected(cashMethod);
                  },
                ),
              );
            }),
            
            // Banka kartları (debit)
            ...debitCards.map((cardData) {
              final paymentCard = PaymentCard(
                id: cardData['id'] as String,
                name: cardData['cardName'] as String? ?? 'Banka Kartı',
                type: CardType.debit,
                number: cardData['maskedCardNumber'] as String? ?? '**** **** **** ****',
                expiryDate: '',
                bankName: cardData['bankName'] as String? ?? '',
                color: const Color(0xFF007AFF), // Mavi - banka kartı
              );
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCardOption(
                  context: context,
                  card: paymentCard,
                  balance: (cardData['balance'] as num?)?.toDouble(),
                  isSelected: widget.selectedPaymentMethod?.card?.id == paymentCard.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    
                    // Clear credit card selection state
                    setState(() {
                      _selectedCreditCard = null;
                      _selectedInstallments = null;
                    });
                    
                    final cardMethod = PaymentMethod(
                      type: PaymentMethodType.card,
                      card: paymentCard,
                      installments: 1, // Banka kartı için taksit yok
                    );
                    widget.onPaymentMethodSelected(cardMethod);
                  },
                ),
              );
            }),
            
            // Kredi kartları
            ...creditCards.map((cardData) {
              // Convert legacy format to PaymentCard
              final paymentCard = PaymentCard(
                id: cardData['id'] as String,
                name: cardData['cardName'] as String? ?? 'Kredi Kartı',
                type: CardType.credit,
                number: cardData['formattedCardNumber'] as String? ?? '**** **** **** ****',
                expiryDate: '',
                bankName: cardData['bankName'] as String? ?? '',
                color: const Color(0xFFFF3B30), // Red for credit cards
              );
              
              final isSelected = widget.selectedPaymentMethod?.card?.id == cardData['id'];
              final isSelectedForInstallments = _selectedCreditCard?.id == cardData['id'];
              
              return Column(
                children: [
                  // Credit Card Option
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCardOption(
                      context: context,
                      card: paymentCard,
                      isSelected: isSelected || isSelectedForInstallments,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCreditCard = paymentCard;
                          _selectedInstallments = null;
                        });
                        
                        // Clear any existing payment method selection
                        // This ensures other payment methods are deselected
                        widget.onPaymentMethodSelected(PaymentMethod(
                          type: PaymentMethodType.card,
                          card: paymentCard,
                          installments: 1, // Default to 1 installment when card is first selected
                        ));
                      },
                      balance: (cardData['availableLimit'] as num?)?.toDouble(),
                    ),
                  ),
                  
                  // Horizontal Installment Options (shown when card is selected)
                  if (isSelectedForInstallments) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // Horizontal Installment Options
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(12, (index) {
                                final installmentCount = index + 1;
                                final isInstallmentSelected = _selectedInstallments == installmentCount;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedInstallments = installmentCount;
                                      });
                                      
                                      // Create and return payment method
                                      final cardMethod = PaymentMethod(
                                        type: PaymentMethodType.card,
                                        card: paymentCard,
                                        installments: installmentCount,
                                      );
                                      widget.onPaymentMethodSelected(cardMethod);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width > 600 ? 20 : 14,
                                        vertical: MediaQuery.of(context).size.width > 600 ? 12 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isInstallmentSelected
                                            ? paymentCard.color
                                            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isInstallmentSelected
                                              ? paymentCard.color
                                              : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
                                          width: isInstallmentSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        installmentCount == 1 ? 'Peşin' : '$installmentCount Taksit',
                                        style: GoogleFonts.inter(
                                          fontSize: MediaQuery.of(context).size.width > 600 ? 15 : 13,
                                          fontWeight: FontWeight.w500,
                                          color: isInstallmentSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required double? balance,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? color.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? color
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text Content
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? color
                            : (isDark ? Colors.white : Colors.black),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (balance != null) ...[
                        const Spacer(),
                        Text(
                          _formatCurrency(balance),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required BuildContext context,
    required PaymentCard card,
    required bool isSelected,
    required VoidCallback onTap,
    required double? balance,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? card.color.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? card.color
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Card Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: card.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: card.color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Card Info
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        card.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? card.color
                            : (isDark ? Colors.white : Colors.black),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (balance != null) ...[
                        const Spacer(),
                        Text(
                          _formatCurrency(balance),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CashAccount _convertAccountToCashAccount(AccountModel account) {
    return CashAccount(
      id: account.id,
      userId: account.userId,
      name: account.name,
      balance: account.balance,
      currency: 'TRY', // Default currency
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/cash_account.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../core/theme/theme_provider.dart';
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
/// - "Cash" for 1 installment
/// - "X Installments" for multiple installments
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
    return Provider.of<ThemeProvider>(context, listen: false).formatAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    
    // Responsive değerler - Mobil odaklı
    final errorFontSize = isSmallMobile ? 10.0 :
                         isMobile ? 11.0 :
                         isLargeMobile ? 12.0 :
                         isSmallTablet ? 13.0 :
                         isTablet ? 14.0 : 16.0;
    
    final errorSpacing = isSmallMobile ? 8.0 :
                        isMobile ? 10.0 :
                        isLargeMobile ? 12.0 :
                        isSmallTablet ? 14.0 :
                        isTablet ? 16.0 : 20.0;
    
    final itemSpacing = isSmallMobile ? 8.0 :
                       isMobile ? 10.0 :
                       isLargeMobile ? 12.0 :
                       isSmallTablet ? 14.0 :
                       isTablet ? 16.0 : 20.0;
    
    final loadingPadding = isSmallMobile ? 24.0 :
                          isMobile ? 28.0 :
                          isLargeMobile ? 32.0 :
                          isSmallTablet ? 36.0 :
                          isTablet ? 40.0 : 48.0;
    
    final loadingStrokeWidth = isSmallMobile ? 1.5 :
                              isMobile ? 2.0 :
                              isLargeMobile ? 2.5 :
                              isSmallTablet ? 3.0 :
                              isTablet ? 3.5 : 4.0;
    
    final errorFontSizeLarge = isSmallMobile ? 12.0 :
                              isMobile ? 13.0 :
                              isLargeMobile ? 14.0 :
                              isSmallTablet ? 15.0 :
                              isTablet ? 16.0 : 18.0;
    
    final buttonSpacing = isSmallMobile ? 12.0 :
                         isMobile ? 14.0 :
                         isLargeMobile ? 16.0 :
                         isSmallTablet ? 18.0 :
                         isTablet ? 20.0 : 24.0;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(loadingPadding),
              child: CircularProgressIndicator(
                strokeWidth: loadingStrokeWidth,
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.cardsLoadingError ?? 'Error loading cards',
                  style: GoogleFonts.inter(
                    fontSize: errorFontSizeLarge,
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: buttonSpacing),
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
                  fontSize: errorFontSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFF3B30),
                  letterSpacing: -0.1,
                ),
              ),
              SizedBox(height: errorSpacing),
            ],
            
            // Nakit hesapları
            ...cashAccounts.map((cashAccount) {
              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
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
                      cashAccount: _convertAccountToCashAccount(cashAccount, context),
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
                name: cardData['cardName'] as String? ?? AppLocalizations.of(context)!.debitCard,
                type: CardType.debit,
                number: cardData['maskedCardNumber'] as String? ?? '**** **** **** ****',
                expiryDate: '',
                bankName: cardData['bankName'] as String? ?? '',
                color: const Color(0xFF007AFF), // Mavi - banka kartı
              );
              
              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
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
                name: cardData['cardName'] as String? ?? AppLocalizations.of(context)!.creditCard,
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
                        debugPrint('   Card Name: ${paymentCard.name}');
                        debugPrint('   Card ID: ${paymentCard.id}');
                        debugPrint('   Card Type: ${paymentCard.type}');
                        
                        setState(() {
                          _selectedCreditCard = paymentCard;
                          _selectedInstallments = null;
                        });
                        
                        // Clear any existing payment method selection
                        // This ensures other payment methods are deselected
                        final selectedMethod = PaymentMethod(
                          type: PaymentMethodType.card,
                          card: paymentCard,
                          installments: 1, // Default to 1 installment when card is first selected
                        );
                        
                        debugPrint('   Type: ${selectedMethod.type}');
                        debugPrint('   Card ID: ${selectedMethod.card?.id}');
                        debugPrint('   Card Name: ${selectedMethod.card?.name}');
                        
                        widget.onPaymentMethodSelected(selectedMethod);
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
                                        installmentCount == 1 ? (AppLocalizations.of(context)?.cash ?? 'NAKİT') : '$installmentCount ${AppLocalizations.of(context)?.installment ?? 'Installment'}',
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    
    // Responsive değerler - Mobil odaklı
    final borderRadius = isSmallMobile ? 10.0 :
                        isMobile ? 11.0 :
                        isLargeMobile ? 12.0 :
                        isSmallTablet ? 14.0 :
                        isTablet ? 16.0 : 18.0;
    
    final borderWidth = isSmallMobile ? 1.0 :
                       isMobile ? 1.2 :
                       isLargeMobile ? 1.5 :
                       isSmallTablet ? 1.8 :
                       isTablet ? 2.0 : 2.5;
    
    final containerPadding = isSmallMobile ? 12.0 :
                            isMobile ? 14.0 :
                            isLargeMobile ? 16.0 :
                            isSmallTablet ? 18.0 :
                            isTablet ? 20.0 : 24.0;
    
    final iconSize = isSmallMobile ? 32.0 :
                    isMobile ? 36.0 :
                    isLargeMobile ? 40.0 :
                    isSmallTablet ? 44.0 :
                    isTablet ? 48.0 : 56.0;
    
    final iconInnerSize = isSmallMobile ? 16.0 :
                         isMobile ? 18.0 :
                         isLargeMobile ? 20.0 :
                         isSmallTablet ? 22.0 :
                         isTablet ? 24.0 : 28.0;
    
    final iconBorderRadius = isSmallMobile ? 8.0 :
                            isMobile ? 9.0 :
                            isLargeMobile ? 10.0 :
                            isSmallTablet ? 11.0 :
                            isTablet ? 12.0 : 14.0;
    
    final spacing = isSmallMobile ? 8.0 :
                   isMobile ? 10.0 :
                   isLargeMobile ? 12.0 :
                   isSmallTablet ? 14.0 :
                   isTablet ? 16.0 : 20.0;
    
    final titleFontSize = isSmallMobile ? 14.0 :
                         isMobile ? 15.0 :
                         isLargeMobile ? 16.0 :
                         isSmallTablet ? 17.0 :
                         isTablet ? 18.0 : 20.0;
    
    final balanceFontSize = isSmallMobile ? 12.0 :
                           isMobile ? 13.0 :
                           isLargeMobile ? 14.0 :
                           isSmallTablet ? 15.0 :
                           isTablet ? 16.0 : 18.0;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? color.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isSelected 
            ? color
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? borderWidth : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: EdgeInsets.all(containerPadding),
            child: Row(
              children: [
                // Icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(iconBorderRadius),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconInnerSize,
                  ),
                ),
                
                SizedBox(width: spacing),
                
                // Text Content
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: titleFontSize,
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
                                fontSize: balanceFontSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    
    // Responsive değerler - Mobil odaklı
    final borderRadius = isSmallMobile ? 10.0 :
                        isMobile ? 11.0 :
                        isLargeMobile ? 12.0 :
                        isSmallTablet ? 14.0 :
                        isTablet ? 16.0 : 18.0;
    
    final borderWidth = isSmallMobile ? 1.0 :
                       isMobile ? 1.2 :
                       isLargeMobile ? 1.5 :
                       isSmallTablet ? 1.8 :
                       isTablet ? 2.0 : 2.5;
    
    final containerPadding = isSmallMobile ? 12.0 :
                            isMobile ? 14.0 :
                            isLargeMobile ? 16.0 :
                            isSmallTablet ? 18.0 :
                            isTablet ? 20.0 : 24.0;
    
    final iconSize = isSmallMobile ? 32.0 :
                    isMobile ? 36.0 :
                    isLargeMobile ? 40.0 :
                    isSmallTablet ? 44.0 :
                    isTablet ? 48.0 : 56.0;
    
    final iconInnerSize = isSmallMobile ? 16.0 :
                         isMobile ? 18.0 :
                         isLargeMobile ? 20.0 :
                         isSmallTablet ? 22.0 :
                         isTablet ? 24.0 : 28.0;
    
    final iconBorderRadius = isSmallMobile ? 8.0 :
                            isMobile ? 9.0 :
                            isLargeMobile ? 10.0 :
                            isSmallTablet ? 11.0 :
                            isTablet ? 12.0 : 14.0;
    
    final spacing = isSmallMobile ? 8.0 :
                   isMobile ? 10.0 :
                   isLargeMobile ? 12.0 :
                   isSmallTablet ? 14.0 :
                   isTablet ? 16.0 : 20.0;
    
    final titleFontSize = isSmallMobile ? 14.0 :
                         isMobile ? 15.0 :
                         isLargeMobile ? 16.0 :
                         isSmallTablet ? 17.0 :
                         isTablet ? 18.0 : 20.0;
    
    final balanceFontSize = isSmallMobile ? 12.0 :
                           isMobile ? 13.0 :
                           isLargeMobile ? 14.0 :
                           isSmallTablet ? 15.0 :
                           isTablet ? 16.0 : 18.0;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? card.color.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isSelected 
            ? card.color
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? borderWidth : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: EdgeInsets.all(containerPadding),
            child: Row(
              children: [
                // Card Icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: card.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(iconBorderRadius),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: card.color,
                    size: iconInnerSize,
                  ),
                ),
                
                SizedBox(width: spacing),
                
                // Card Info
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        card.name,
                        style: GoogleFonts.inter(
                          fontSize: titleFontSize,
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
                                fontSize: balanceFontSize,
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
  
  CashAccount _convertAccountToCashAccount(AccountModel account, BuildContext context) {
    return CashAccount(
      id: account.id,
      userId: account.userId,
      name: account.name == 'CASH_WALLET' 
          ? (AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap')
          : account.name,
      balance: account.balance,
      currency: 'TRY', // Default currency
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment_method.dart';
import '../../models/card.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/cash_account.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../l10n/app_localizations.dart';

class IncomePaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedPaymentMethod;
  final Function(PaymentMethod) onPaymentMethodSelected;
  final VoidCallback? onAutoAdvance;
  final String? errorText;

  const IncomePaymentMethodSelector({
    super.key,
    this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.onAutoAdvance,
    this.errorText,
  });

  @override
  State<IncomePaymentMethodSelector> createState() => _IncomePaymentMethodSelectorState();
}

class _IncomePaymentMethodSelectorState extends State<IncomePaymentMethodSelector> {
  
  // Para formatı için yardımcı metod
  String _formatCurrency(double amount) {
    return CurrencyUtils.formatAmount(amount, Currency.TRY);
  }

  @override
  void initState() {
    super.initState();
    // V2 provider automatically loads data when needed
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, cardProvider, child) {
        if (cardProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (cardProvider.error != null) {
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
                  onPressed: () => cardProvider.loadAllData(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        // Gelir için uygun hesapları filtrele (banka kartları ve nakit hesapları)
        final debitCards = cardProvider.debitCards;
        final cashAccounts = cardProvider.cashAccounts;

        return Column(
          children: [
            // Nakit hesapları
            ...cashAccounts.map((cashAccount) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentOption(
                  context: context,
                  title: l10n.cash,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF34C759),
                  isSelected: widget.selectedPaymentMethod?.isCash == true,
                  balance: cashAccount.balance,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final cashMethod = PaymentMethod(
                      type: PaymentMethodType.cash,
                      cashAccount: _convertAccountToCashAccount(cashAccount),
                    );
                    widget.onPaymentMethodSelected(cashMethod);
                    
                    // Auto-advance after selection
                    Future.delayed(const Duration(milliseconds: 300), () {
                      widget.onAutoAdvance?.call();
                    });
                  },
                ),
              );
            }),
            
            // Banka kartları
            ...debitCards.map((cardData) {
              final paymentCard = PaymentCard(
                id: cardData['id'] as String,
                name: cardData['cardName'] as String? ?? 'Banka Kartı',
                type: CardType.debit,
                number: cardData['maskedCardNumber'] as String? ?? '**** **** **** ****',
                expiryDate: '',
                bankName: cardData['bankName'] as String? ?? '',
                color: const Color(0xFF34C759), // Yeşil - gelir için
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
                    
                    final cardMethod = PaymentMethod(
                      type: PaymentMethodType.card,
                      card: paymentCard,
                      installments: 1, // Always 1 for income (no installments)
                    );
                    widget.onPaymentMethodSelected(cardMethod);
                    
                    // Auto-advance after selection
                    Future.delayed(const Duration(milliseconds: 300), () {
                      widget.onAutoAdvance?.call();
                    });
                  },
                ),
              );
            }),
            
            if (widget.errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFF3B30),
                  letterSpacing: -0.1,
                ),
              ),
            ],
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
                // Icon - gider formuyla aynı boyut
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
                // Card Icon - gider formuyla aynı boyut
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
                          const Spacer(),
                          // Bakiye gösterimi - UnifiedCardProvider'dan gelen balance bilgisi
                          if (balance != null) ...[
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
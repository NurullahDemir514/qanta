import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment_method.dart';
import '../../models/card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/cash_account.dart';

class TransferAccountSelector extends StatelessWidget {
  final PaymentMethod? selectedAccount;
  final Function(PaymentMethod) onAccountSelected;
  final String? errorText;
  final PaymentMethod? excludeAccount;
  final bool isSourceSelection; // Kaynak hesap seçimi mi?

  const TransferAccountSelector({
    super.key,
    this.selectedAccount,
    required this.onAccountSelected,
    this.errorText,
    this.excludeAccount,
    this.isSourceSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, cardProvider, child) {
        // Veritabanından hesapları çek
        final availableAccounts = <PaymentMethod>[];
        
        // Nakit hesabı ekle
        final cashAccounts = cardProvider.cashAccounts;
        if (cashAccounts.isNotEmpty) {
          // Use the first cash account (or you could show all)
          final cashAccount = cashAccounts.first;
          availableAccounts.add(PaymentMethod(
            type: PaymentMethodType.cash,
            cashAccount: _convertAccountToCashAccount(cashAccount),
          ));
        }
        
        // Kredi kartlarını ekle - SADECE HEDEF HESAP İÇİN
        // Kredi kartından transfer yapılamaz, sadece kredi kartına transfer yapılabilir
        if (!isSourceSelection) { // Hedef hesap seçimi ise kredi kartlarını göster
          for (final creditCardData in cardProvider.creditCards) {
            availableAccounts.add(PaymentMethod(
              type: PaymentMethodType.card,
              card: PaymentCard(
                id: creditCardData['id'],
                name: creditCardData['cardName'] ?? 'Kredi Kartı',
                number: creditCardData['formattedCardNumber'] ?? '**** **** **** ****',
                type: CardType.credit,
                bankName: creditCardData['bankName'] ?? '',
                color: Colors.blue, // Default color
                expiryDate: '',
              ),
            ));
          }
        }
        
        // Banka kartlarını ekle
        for (final debitCardData in cardProvider.debitCards) {
          availableAccounts.add(PaymentMethod(
            type: PaymentMethodType.card,
            card: PaymentCard(
              id: debitCardData['id'],
              name: debitCardData['cardName'] ?? 'Banka Kartı',
              number: debitCardData['maskedCardNumber'] ?? '**** **** **** ****',
              type: CardType.debit,
              bankName: debitCardData['bankName'] ?? '',
              color: Colors.green, // Default color
              expiryDate: '',
            ),
          ));
        }
        
        // Hariç tutulacak hesabı filtrele
        final filteredAccounts = availableAccounts
            .where((account) => account != excludeAccount)
            .toList();

        if (cardProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (filteredAccounts.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noAccountsAvailable,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Hesap seçenekleri
            ...filteredAccounts.map((account) {
              final isSelected = selectedAccount == account;
              
              if (account.isCash) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAccountOption(
                    context: context,
                    title: account.getDisplayName(l10n),
                    subtitle: l10n.digitalWallet,
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF34C759),
                    isSelected: isSelected,
                    balance: account.cashAccount?.balance,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onAccountSelected(account);
                    },
                  ),
                );
              } else if (account.card != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardOption(
                    context: context,
                    card: account.card!,
                    isSelected: isSelected,
                    cardProvider: cardProvider,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onAccountSelected(account);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            // Error Text
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
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

  Widget _buildAccountOption({
    required BuildContext context,
    required String title,
    required String subtitle,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (balance != null) ...[
                            const Spacer(),
                            Text(
                              Provider.of<ThemeProvider>(context, listen: false).formatAmount(balance),
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
    required UnifiedProviderV2 cardProvider,
    required VoidCallback onTap,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            card.bankName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                          ),
                          const Spacer(),
                          // Bakiye gösterimi
                          Text(
                            _getCardBalanceText(card, cardProvider, context),
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
                      ),
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

  String _getCardBalanceText(PaymentCard card, UnifiedProviderV2 cardProvider, BuildContext context) {
    try {
      // Kart tipine göre bakiye bilgisi al
      final cardTypeString = card.type.toString();
      
      if (cardTypeString.contains('credit')) {
        // Kredi kartı için kullanılabilir limit
        final creditCard = cardProvider.creditCards.firstWhere(
          (c) => c['id'] == card.id,
        );
        return '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(creditCard['availableLimit'])} limit';
      } else if (cardTypeString.contains('debit')) {
        // Banka kartı için bakiye
        final debitCard = cardProvider.debitCards.firstWhere(
          (c) => c['id'] == card.id,
        );
        return Provider.of<ThemeProvider>(context, listen: false).formatAmount(debitCard['balance']);
      }
    } catch (e) {
      // Kart bulunamazsa boş string döndür
      return '';
    }
    return '';
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
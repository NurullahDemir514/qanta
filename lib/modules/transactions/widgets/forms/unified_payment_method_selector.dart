import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/unified_card_provider.dart';
import '../../../../shared/models/transaction_model.dart' as txn;
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/payment_card_model.dart' as card;
import '../../../../shared/design_system/transaction_design_system.dart';

class UnifiedPaymentMethodSelector extends StatefulWidget {
  final Map<String, dynamic>? selectedCard;
  final int installmentCount;
  final Function(Map<String, dynamic>, int) onCardSelected;
  final String? errorText;
  final TransactionType transactionType;

  const UnifiedPaymentMethodSelector({
    super.key,
    this.selectedCard,
    this.installmentCount = 1,
    required this.onCardSelected,
    this.errorText,
    required this.transactionType,
  });

  @override
  State<UnifiedPaymentMethodSelector> createState() => _UnifiedPaymentMethodSelectorState();
}

class _UnifiedPaymentMethodSelectorState extends State<UnifiedPaymentMethodSelector> {
  @override
  void initState() {
    super.initState();
    // Kartları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardProvider = Provider.of<UnifiedCardProvider>(context, listen: false);
      if (cardProvider.allCards.isEmpty) {
        cardProvider.loadAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UnifiedCardProvider>(
      builder: (context, cardProvider, child) {
        if (cardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (cardProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.cardsLoadingError ?? 'Error loading cards',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => cardProvider.loadAllData(),
                  child: Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final availableCards = _getAvailableCards(cardProvider.allCards);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.errorText != null) ...[
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            if (availableCards.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      size: 48,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.noCardsAddedYet ?? 'No cards added yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Kartları listele
              ...availableCards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCardOption(
                  context: context,
                  card: card,
                  isSelected: widget.selectedCard?['id'] == card['id'],
                  isDark: isDark,
                  l10n: l10n,
                  onTap: () => _handleCardSelection(card),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getAvailableCards(List<Map<String, dynamic>> allCards) {
    // Gelir için sadece banka kartı ve nakit
    if (widget.transactionType == txn.TransactionType.income) {
      return allCards.where((card) => 
        card['type'] == card.CardType.debit || card['type'] == card.CardType.cash
      ).toList();
    }
    
    // Gider ve transfer için tüm kartlar
    return allCards;
  }

  void _handleCardSelection(Map<String, dynamic> card) {
    final cardType = card['type'] as card.CardType;
    
    // Kredi kartı ise taksit seçeneklerini göster
    if (cardType == card.CardType.credit && widget.transactionType == txn.TransactionType.expense) {
      _showInstallmentOptions(card);
    } else {
      // Diğer kartlar için direkt seç
      widget.onCardSelected(card, 1);
    }
  }

  void _showInstallmentOptions(Map<String, dynamic> card) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.installmentOptions ?? 'Taksit Seçenekleri',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Taksit seçenekleri
                  ...[1, 2, 3, 6, 9, 12].map((installments) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInstallmentOption(
                      installments: installments,
                      cardName: card['name'] as String,
                      isDark: isDark,
                      l10n: l10n,
                      onTap: () {
                        widget.onCardSelected(card, installments);
                        Navigator.pop(context);
                      },
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required BuildContext context,
    required Map<String, dynamic> card,
    required bool isSelected,
    required bool isDark,
    required AppLocalizations l10n,
    required VoidCallback onTap,
  }) {
    final cardType = card['type'] as card.CardType;
    final cardName = card['name'] as String;
    final subtitle = card['subtitle'] as String;
    final balance = card['balance'] as double?;
    
    Color cardColor;
    IconData cardIcon;
    
    switch (cardType) {
      case card.CardType.credit:
        cardColor = const Color(0xFF007AFF);
        cardIcon = Icons.credit_card_rounded;
        break;
      case card.CardType.debit:
        cardColor = Colors.green.shade500;
        cardIcon = Icons.credit_card_rounded;
        break;
      case card.CardType.cash:
        cardColor = const Color(0xFFFF9500);
        cardIcon = Icons.payments_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? cardColor.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? cardColor
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cardIcon,
                    color: cardColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? cardColor
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
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (balance != null) ...[
                            const Spacer(),
                            Text(
                              TransactionDesignSystem.formatNumber(balance),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cardType == card.CardType.credit 
                                  ? (balance > 0 ? Colors.green.shade500 : const Color(0xFFFF3B30))
                                  : Colors.green.shade500,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (cardType == card.CardType.credit && widget.transactionType == txn.TransactionType.expense)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    size: 20,
                  )
                else if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: cardColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentOption({
    required int installments,
    required String cardName,
    required bool isDark,
    required AppLocalizations l10n,
    required VoidCallback onTap,
  }) {
    final displayText = installments == 1 ? (AppLocalizations.of(context)?.cash ?? 'NAKİT') : '$installments ${AppLocalizations.of(context)?.installment_summary ?? 'Installment'}';
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
          width: 0.33,
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
                Expanded(
                  child: Text(
                    '$cardName ($displayText)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
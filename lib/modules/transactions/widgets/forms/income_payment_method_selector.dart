import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/payment_method.dart';
import '../../models/card.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/cash_account.dart';
import '../../../../core/theme/theme_provider.dart';
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
  State<IncomePaymentMethodSelector> createState() =>
      _IncomePaymentMethodSelectorState();
}

class _IncomePaymentMethodSelectorState
    extends State<IncomePaymentMethodSelector> {
  // Kart ismini temizle ve localize et
  String _getLocalizedCardName(String? cardName, String? bankName, CardType cardType) {
    final l10n = AppLocalizations.of(context)!;
    final localizedCardType = cardType == CardType.credit ? l10n.creditCard : l10n.debitCard;
    
    if (cardName == null || cardName.isEmpty) {
      return '${bankName ?? ''} $localizedCardType';
    }
    
    // Remove card type phrases in any language from cardName
    String cleanName = cardName
        .replaceAll(RegExp(r'\s*(Credit Card|Kredi Kartı|Debit Card|Banka Kartı)\s*$', caseSensitive: false), '')
        .trim();
    
    // If nothing left after cleaning, use bank name
    if (cleanName.isEmpty && bankName != null) {
      return '$bankName $localizedCardType';
    }
    
    // If still empty, return just card type
    if (cleanName.isEmpty) {
      return localizedCardType;
    }
    
    // Return cleaned name + localized card type
    return '$cleanName $localizedCardType';
  }

  // Para formatı için yardımcı metod
  String _formatCurrency(double amount) {
    return Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).formatAmount(amount);
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop

    // Responsive değerler
    final itemSpacing = isSmallMobile
        ? 8.0
        : isMobile
        ? 10.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 20.0;

    final errorFontSize = isSmallMobile
        ? 11.0
        : isMobile
        ? 12.0
        : isLargeMobile
        ? 13.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 15.0
        : 16.0;

    return Consumer<UnifiedProviderV2>(
      builder: (context, cardProvider, child) {
        if (cardProvider.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
              child: CircularProgressIndicator(
                strokeWidth: isTablet ? 3.0 : 2.0,
              ),
            ),
          );
        }

        if (cardProvider.error != null) {
          return Center(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.cardsLoadingError ??
                      'Error loading cards',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16.0 : 14.0,
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 20.0 : 16.0),
                ElevatedButton(
                  onPressed: () => cardProvider.loadAllData(),
                  child: Text(
                    'Tekrar Dene',
                    style: GoogleFonts.inter(fontSize: isTablet ? 16.0 : 14.0),
                  ),
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
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: _buildPaymentOption(
                  context: context,
                  title: l10n.cash,
                  icon: Icons.payments_rounded,
                  color: Colors.green.shade500,
                  isSelected: widget.selectedPaymentMethod?.isCash == true,
                  balance: cashAccount.balance,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final cashMethod = PaymentMethod(
                      type: PaymentMethodType.cash,
                      cashAccount: _convertAccountToCashAccount(cashAccount, context),
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
                name: _getLocalizedCardName(
                  cardData['cardName'] as String?,
                  cardData['bankName'] as String?,
                  CardType.debit,
                ),
                type: CardType.debit,
                number:
                    cardData['maskedCardNumber'] as String? ??
                    '**** **** **** ****',
                expiryDate: '',
                bankName: cardData['bankName'] as String? ?? '',
                color: Colors.green.shade500, // Yeşil - gelir için
              );

              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: _buildCardOption(
                  context: context,
                  card: paymentCard,
                  balance: (cardData['balance'] as num?)?.toDouble(),
                  isSelected:
                      widget.selectedPaymentMethod?.card?.id == paymentCard.id,
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
              SizedBox(height: itemSpacing),
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: errorFontSize,
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop

    // Responsive değerler - Mobil odaklı
    final borderRadius = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 18.0;

    final borderWidth = isSmallMobile
        ? 1.0
        : isMobile
        ? 1.2
        : isLargeMobile
        ? 1.5
        : isSmallTablet
        ? 1.8
        : isTablet
        ? 2.0
        : 2.5;

    final containerPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 18.0
        : isTablet
        ? 20.0
        : 24.0;

    final iconSize = isSmallMobile
        ? 32.0
        : isMobile
        ? 36.0
        : isLargeMobile
        ? 40.0
        : isSmallTablet
        ? 44.0
        : isTablet
        ? 48.0
        : 56.0;

    final iconInnerSize = isSmallMobile
        ? 16.0
        : isMobile
        ? 18.0
        : isLargeMobile
        ? 20.0
        : isSmallTablet
        ? 22.0
        : isTablet
        ? 24.0
        : 28.0;

    final iconBorderRadius = isSmallMobile
        ? 8.0
        : isMobile
        ? 9.0
        : isLargeMobile
        ? 10.0
        : isSmallTablet
        ? 11.0
        : isTablet
        ? 12.0
        : 14.0;

    final spacing = isSmallMobile
        ? 8.0
        : isMobile
        ? 10.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 20.0;

    final titleFontSize = isSmallMobile
        ? 14.0
        : isMobile
        ? 15.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 17.0
        : isTablet
        ? 18.0
        : 20.0;

    final balanceFontSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 13.0
        : isLargeMobile
        ? 14.0
        : isSmallTablet
        ? 15.0
        : isTablet
        ? 16.0
        : 18.0;

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
                  child: Icon(icon, color: color, size: iconInnerSize),
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
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop

    // Responsive değerler - Mobil odaklı
    final borderRadius = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 18.0;

    final borderWidth = isSmallMobile
        ? 1.0
        : isMobile
        ? 1.2
        : isLargeMobile
        ? 1.5
        : isSmallTablet
        ? 1.8
        : isTablet
        ? 2.0
        : 2.5;

    final containerPadding = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 18.0
        : isTablet
        ? 20.0
        : 24.0;

    final iconSize = isSmallMobile
        ? 32.0
        : isMobile
        ? 36.0
        : isLargeMobile
        ? 40.0
        : isSmallTablet
        ? 44.0
        : isTablet
        ? 48.0
        : 56.0;

    final iconInnerSize = isSmallMobile
        ? 16.0
        : isMobile
        ? 18.0
        : isLargeMobile
        ? 20.0
        : isSmallTablet
        ? 22.0
        : isTablet
        ? 24.0
        : 28.0;

    final iconBorderRadius = isSmallMobile
        ? 8.0
        : isMobile
        ? 9.0
        : isLargeMobile
        ? 10.0
        : isSmallTablet
        ? 11.0
        : isTablet
        ? 12.0
        : 14.0;

    final spacing = isSmallMobile
        ? 8.0
        : isMobile
        ? 10.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 14.0
        : isTablet
        ? 16.0
        : 20.0;

    final titleFontSize = isSmallMobile
        ? 14.0
        : isMobile
        ? 15.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 17.0
        : isTablet
        ? 18.0
        : 20.0;

    final balanceFontSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 13.0
        : isLargeMobile
        ? 14.0
        : isSmallTablet
        ? 15.0
        : isTablet
        ? 16.0
        : 18.0;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          if (balance != null) ...[
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
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)?.debitCard ?? 'Banka Kartı',
                        style: GoogleFonts.inter(
                          fontSize: balanceFontSize - 2,
                          fontWeight: FontWeight.w400,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                          letterSpacing: -0.1,
                        ),
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

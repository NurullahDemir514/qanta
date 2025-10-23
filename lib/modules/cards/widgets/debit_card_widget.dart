import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';

class DebitCardWidget extends StatelessWidget {
  final dynamic card; // Can be DebitCardModel or Map
  final VoidCallback? onTap;

  const DebitCardWidget({super.key, required this.card, this.onTap});

  // Helper methods to extract data from either DebitCardModel or Map
  String get bankCode {
    if (card is Map) {
      return card['bankCode'] ?? 'qanta';
    } else {
      return card.bankCode;
    }
  }

  double get balance {
    if (card is Map) {
      return card['balance']?.toDouble() ?? 0.0;
    } else {
      return card.balance;
    }
  }

  String getCardName(BuildContext context) {
    if (card is Map) {
      return card['cardName'] ??
          card['name'] ??
          AppLocalizations.of(context)!.debitCard;
    } else {
      return card.cardName ??
          card.name ??
          AppLocalizations.of(context)!.debitCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuthService.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
    final isLandscape = screenHeight < screenWidth;

    // Responsive değerler - Mobil odaklı (büyütüldü)
    final cardPadding = isSmallMobile
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

    final cardBorderRadius = isSmallMobile
        ? 14.0
        : isMobile
        ? 16.0
        : isLargeMobile
        ? 18.0
        : isSmallTablet
        ? 20.0
        : isTablet
        ? 22.0
        : 26.0;

    final chipSize = isSmallMobile
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

    final chipRadius = isSmallMobile
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

    final iconSize = isSmallMobile
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

    final bankBadgePadding = isSmallMobile
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

    final bankBadgeRadius = isSmallMobile
        ? 4.0
        : isMobile
        ? 5.0
        : isLargeMobile
        ? 6.0
        : isSmallTablet
        ? 7.0
        : isTablet
        ? 8.0
        : 10.0;

    final bankBadgeFontSize = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 13.0
        : isTablet
        ? 14.0
        : 16.0;

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
        : 18.0;

    final labelFontSize = isSmallMobile
        ? 9.0
        : isMobile
        ? 10.0
        : isLargeMobile
        ? 11.0
        : isSmallTablet
        ? 12.0
        : isTablet
        ? 13.0
        : 14.0;

    final cardNameFontSize = isSmallMobile
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

    final balanceLabelFontSize = isSmallMobile
        ? 10.0
        : isMobile
        ? 11.0
        : isLargeMobile
        ? 12.0
        : isSmallTablet
        ? 13.0
        : isTablet
        ? 14.0
        : 15.0;

    final balanceFontSize = isSmallMobile
        ? 18.0
        : isMobile
        ? 20.0
        : isLargeMobile
        ? 22.0
        : isSmallTablet
        ? 24.0
        : isTablet
        ? 26.0
        : 28.0;

    final contactlessIconSize = isSmallMobile
        ? 18.0
        : isMobile
        ? 20.0
        : isLargeMobile
        ? 22.0
        : isSmallTablet
        ? 24.0
        : isTablet
        ? 26.0
        : 28.0;

    // Get design from constants
    final gradientColors = AppConstants.getBankGradientColors(bankCode);
    final accentColor = AppConstants.getBankAccentColor(bankCode);
    final bankName = AppConstants.getLocalizedBankName(
      bankCode,
      AppLocalizations.of(context)!,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(cardBorderRadius),
            ),
            child: Stack(
              children: [
                // Holographic effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                      gradient: AppConstants.getHolographicGradient(
                        accentColor,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Card Name and Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           // Card name on the left
                           Expanded(
                             flex: 3,
                             child: Text(
                               getCardName(context).toUpperCase(),
                               style: GoogleFonts.inter(
                                 fontSize: isSmallMobile ? 11.0 : 12.0,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.white,
                                 letterSpacing: 0.5,
                               ),
                               overflow: TextOverflow.ellipsis,
                               maxLines: 1,
                               textAlign: TextAlign.start,
                             ),
                           ),
                          
                          // Minimal contactless badge on the right
                          Container(
                            padding: EdgeInsets.all(isSmallMobile ? 6.0 : 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(isSmallMobile ? 6.0 : 8.0),
                            ),
                            child: Icon(
                              Icons.contactless_rounded,
                              color: Colors.white,
                              size: isSmallMobile ? 16.0 : 18.0,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallMobile ? 50.0 : 60.0),

                      // Balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.availableBalance,
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallMobile ? 11.0 : 12.0,
                                    color: Colors.white.withValues(alpha: 1.0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: isSmallMobile ? 1.0 : 2.0),
                                CurrencyUtils.buildCurrencyText(
                                  themeProvider.formatAmount(balance),
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallMobile ? 16.0 : 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  currency: themeProvider.currency,
                                ),
                              ],
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
        );
      },
    );
  }
}

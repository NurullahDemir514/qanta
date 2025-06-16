import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/debit_card_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';

class DebitCardWidget extends StatelessWidget {
  final dynamic card; // Can be DebitCardModel or Map
  final VoidCallback? onTap;

  const DebitCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

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

  String get cardName {
    if (card is Map) {
      return card['cardName'] ?? card['name'] ?? 'Banka Kartı';
    } else {
      return card.cardName ?? card.name ?? 'Banka Kartı';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = SupabaseService.instance.currentUser;
    
    // Get design from constants
    final gradientColors = AppConstants.getBankGradientColors(bankCode);
    final accentColor = AppConstants.getBankAccentColor(bankCode);
    final bankName = AppConstants.getBankName(bankCode);

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
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              boxShadow: AppConstants.getCardShadows(accentColor),
            ),
            child: Stack(
              children: [
                // Holographic effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                      gradient: AppConstants.getHolographicGradient(accentColor),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(AppConstants.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Chip and Bank Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // EMV Chip
                          Container(
                            width: AppConstants.cardChipSize,
                            height: AppConstants.cardChipSize,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(AppConstants.cardChipRadius),
                            ),
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: AppConstants.cardIconSize,
                            ),
                          ),
                          
                          // Bank Name
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bankName.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Card name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KART ADI',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cardName.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Spacer(),
                      
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
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                CurrencyUtils.buildCurrencyText(
                                  themeProvider.formatAmount(balance),
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  currency: themeProvider.currency,
                                ),
                              ],
                            ),
                          ),
                          
                          // Contactless payment icon
                          Icon(
                            Icons.contactless,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/bank_service.dart';
import '../../core/theme/theme_provider.dart';
import '../models/credit_card_model.dart';
import '../../l10n/app_localizations.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCardModel card;
  final VoidCallback? onTap;

  const CreditCardWidget({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get bank color from BankService (dynamic) or fallback to AppConstants
    final bankService = BankService();
    final bank = bankService.getBankByCode(card.bankCode);
    final bankColor = bank != null 
        ? bank.accentColorValue 
        : AppConstants.getBankAccentColor(card.bankCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppConstants.cardWidth,
        height: AppConstants.cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.cardMarginHorizontal,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bankColor,
              bankColor.withOpacity(0.8),
              bankColor.withOpacity(0.6),
            ],
          ),
          boxShadow: AppConstants.getCardShadows(bankColor),
        ),
        child: Stack(
          children: [
            // Holographic effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardBorderRadius,
                  ),
                  gradient: AppConstants.getHolographicGradient(bankColor),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank name and card type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConstants.getLocalizedBankName(
                          card.bankCode,
                          AppLocalizations.of(context)!,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CREDIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Card name
                  Text(
                    card.cardName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Card type
                  Text(
                    AppLocalizations.of(context)?.creditCard ?? 'Credit Card',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Credit info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.availableCredit ??
                                'Available Credit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).formatAmount(card.creditLimit - card.totalDebt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.creditLimit ??
                                'Credit Limit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).formatAmount(card.creditLimit),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
  }
}

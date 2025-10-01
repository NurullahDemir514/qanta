import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../bottom_sheets/card_detail_bottom_sheet.dart';
import '../../../shared/utils/currency_utils.dart';

class CreditCardWidget extends StatelessWidget {
  final String cardType;
  final String cardTypeLabel;
  final String cardNumber;
  final double balance;
  final String? bankCode;
  final String? expiryDate;
  final double? totalDebt;
  final double? creditLimit;
  final double? usagePercentage;
  final int? statementDate;
  final int? dueDate;
  final String? cardName;

  const CreditCardWidget({
    super.key,
    required this.cardType,
    required this.cardTypeLabel,
    required this.cardNumber,
    required this.balance,
    this.bankCode,
    this.expiryDate,
    this.totalDebt,
    this.creditLimit,
    this.usagePercentage,
    this.statementDate,
    this.dueDate,
    this.cardName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final gradientColors = bankCode != null 
        ? AppConstants.getBankGradientColors(bankCode!)
        : AppConstants.getCardGradientColors(cardTypeLabel);
    final accentColor = bankCode != null 
        ? AppConstants.getBankAccentColor(bankCode!)
        : AppConstants.getCardAccentColor(cardTypeLabel);
    final bankName = bankCode != null 
        ? AppConstants.getBankName(bankCode!)
        : null;
    
    final isCreditCardWithDebt = totalDebt != null && creditLimit != null;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => _showCardDetail(context, themeProvider, isDark),
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
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bankName?.toUpperCase() ?? cardTypeLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Card name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cardName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (cardName ?? (bankName != null ? '$bankName ${l10n.creditCard}' : cardTypeLabel)).toUpperCase(),
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
                      
                      const SizedBox(height: 4),
                      const Spacer(),
                      
                      // Credit Card Usage Info
                      if (isCreditCardWithDebt) ...[
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (usagePercentage! / 100).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: usagePercentage! > 80 
                                    ? const Color(0xFFFF453A)
                                    : usagePercentage! > 50 
                                        ? const Color(0xFFFF9F0A)
                                        : const Color(0xFF32D74B),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          '${l10n.usage}: ${usagePercentage!.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                      ],
                      
                      // Balance Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCreditCardWithDebt ? l10n.availableLimit : l10n.availableBalance,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
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
                                if (isCreditCardWithDebt) ...[
                                  const SizedBox(height: 1),
                                  CurrencyUtils.buildCurrencyText(
                                    '${l10n.debt}: ${themeProvider.formatAmount(totalDebt!)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    currency: themeProvider.currency,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (statementDate != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${l10n.lastPayment}: ${_formatDueDate(statementDate!, context)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                              ],
                              Icon(
                                Icons.contactless,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 18,
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
      },
    );
  }

  void _showCardDetail(BuildContext context, ThemeProvider themeProvider, bool isDark) {
    final gradientColors = bankCode != null 
        ? AppConstants.getBankGradientColors(bankCode!)
        : AppConstants.getCardGradientColors(cardTypeLabel);
    final accentColor = bankCode != null 
        ? AppConstants.getBankAccentColor(bankCode!)
        : AppConstants.getCardAccentColor(cardTypeLabel);
    
    CardDetailBottomSheet.show(
      context,
      bankCode != null ? AppConstants.getBankName(bankCode!) : cardType,
      cardTypeLabel,
      cardNumber,
      balance,
      gradientColors,
      accentColor,
      themeProvider,
      isDark,
      expiryDate: expiryDate,
      totalDebt: totalDebt,
      creditLimit: creditLimit,
      usagePercentage: usagePercentage,
      statementDate: statementDate,
      dueDate: dueDate,
    );
  }

  String _formatDueDate(int statementDate, BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Bu ayın ekstre tarihini hesapla
    DateTime currentStatementDate = DateTime(currentYear, currentMonth, statementDate);
    
    // Bu ayın son ödeme tarihini hesapla
    DateTime currentDueDate = currentStatementDate.add(const Duration(days: 10));
    // İlk hafta içi günü bul
    while (currentDueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      currentDueDate = currentDueDate.add(const Duration(days: 1));
    }
    
    // Çok dilli ay isimleri (kısaltılmış)
    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      '', 
      l10n.januaryShort,
      l10n.februaryShort,
      l10n.marchShort,
      l10n.aprilShort,
      l10n.mayShort,
      l10n.juneShort,
      l10n.julyShort,
      l10n.augustShort,
      l10n.septemberShort,
      l10n.octoberShort,
      l10n.novemberShort,
      l10n.decemberShort
    ];
    
    // Eğer bu ayın son ödeme tarihi henüz geçmemişse, bu ayın son ödeme tarihini göster
    if (currentDueDate.isAfter(now) || currentDueDate.isAtSameMomentAs(now)) {
      return '${currentDueDate.day} ${monthNames[currentDueDate.month]}';
    }
    
    // Eğer bu ayın son ödeme tarihi geçmişse, gelecek ayın hesaplamasını yap
    DateTime nextStatementDate;
    if (currentMonth == 12) {
      nextStatementDate = DateTime(currentYear + 1, 1, statementDate);
    } else {
      nextStatementDate = DateTime(currentYear, currentMonth + 1, statementDate);
    }
    
    // Gelecek ayın son ödeme tarihini hesapla
    DateTime nextDueDate = nextStatementDate.add(const Duration(days: 10));
    while (nextDueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      nextDueDate = nextDueDate.add(const Duration(days: 1));
    }
    
    return '${nextDueDate.day} ${monthNames[nextDueDate.month]}';
  }
} 
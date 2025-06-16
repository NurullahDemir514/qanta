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
                            (cardName ?? (bankName != null ? '$bankName Kredi Kartı' : cardTypeLabel)).toUpperCase(),
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
                        
                        const SizedBox(height: 6),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kullanım: ${usagePercentage!.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            if (statementDate != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Son Ödeme: ${_formatDueDate(statementDate!)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
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
                                  isCreditCardWithDebt ? 'Kullanılabilir Limit' : l10n.availableBalance,
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
                                if (isCreditCardWithDebt) ...[
                                  const SizedBox(height: 1),
                                  CurrencyUtils.buildCurrencyText(
                                    'Borç: ${themeProvider.formatAmount(totalDebt!)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 7,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    currency: themeProvider.currency,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
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

  String _formatDueDate(int statementDate) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    DateTime statementDateTime = DateTime(currentYear, currentMonth, statementDate);
    
    if (statementDateTime.isBefore(now)) {
      if (currentMonth == 12) {
        statementDateTime = DateTime(currentYear + 1, 1, statementDate);
      } else {
        statementDateTime = DateTime(currentYear, currentMonth + 1, statementDate);
      }
    }
    
    DateTime tentativeDueDate = statementDateTime.add(const Duration(days: 10));
    
    DateTime dueDate = tentativeDueDate;
    while (dueDate.weekday > 5) {
      dueDate = dueDate.add(const Duration(days: 1));
    }
    
    const monthNames = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    
    return '${dueDate.day} ${monthNames[dueDate.month]}';
  }
} 
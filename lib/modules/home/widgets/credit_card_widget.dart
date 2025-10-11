import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    final gradientColors = bankCode != null 
        ? AppConstants.getBankGradientColors(bankCode!)
        : AppConstants.getCardGradientColors(cardTypeLabel);
    final accentColor = bankCode != null 
        ? AppConstants.getBankAccentColor(bankCode!)
        : AppConstants.getCardAccentColor(cardTypeLabel);
    final bankName = bankCode != null 
        ? AppConstants.getLocalizedBankName(bankCode!, AppLocalizations.of(context)!)
        : null;
    
    final isCreditCardWithDebt = totalDebt != null && creditLimit != null;
    
    // Responsive dimensions
    final cardHeight = isSmallScreen ? 200.h : 220.h;
    final cardPadding = isSmallScreen ? 12.w : 16.w;
    final borderRadius = isSmallScreen ? 14.r : 16.r;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => _showCardDetail(context, themeProvider, isDark),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: AppConstants.getCardShadows(accentColor),
            ),
            child: Stack(
              children: [
                // Holographic effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: AppConstants.getHolographicGradient(accentColor),
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                     children: [
                       // Top row: Card Name and Badge
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           // Card name on the left
                           Expanded(
                             flex: 2,
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   l10n.cardName,
                                   style: GoogleFonts.inter(
                                     fontSize: isSmallScreen ? 10.sp : 11.sp,
                                     color: Colors.white.withValues(alpha: 1.0),
                                     letterSpacing: 0.3,
                                   ),
                                 ),
                                 SizedBox(height: isSmallScreen ? 1.h : 1.5.h),
                                 Text(
                                   (cardName ?? (bankName != null ? '$bankName ${l10n.creditCard}' : cardTypeLabel)).toUpperCase(),
                                   style: GoogleFonts.inter(
                                     fontSize: isSmallScreen ? 12.sp : 13.sp,
                                     fontWeight: FontWeight.w600,
                                     color: Colors.white,
                                     letterSpacing: 0.5,
                                   ),
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 1,
                                   textAlign: TextAlign.start,
                                 ),
                               ],
                             ),
                           ),
                           
                           // Bank badge on the right
                           Container(
                             padding: EdgeInsets.symmetric(
                               horizontal: isSmallScreen ? 8.w : 10.w, 
                               vertical: isSmallScreen ? 3.h : 4.h,
                             ),
                             decoration: BoxDecoration(
                               color: accentColor,
                               borderRadius: BorderRadius.circular(isSmallScreen ? 4.r : 5.r),
                             ),
                             child: Text(
                               bankName?.toUpperCase() ?? cardTypeLabel.toUpperCase(),
                               style: GoogleFonts.inter(
                                 fontSize: isSmallScreen ? 10.sp : 11.sp,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                                 letterSpacing: 0.6,
                               ),
                               overflow: TextOverflow.ellipsis,
                               maxLines: 1,
                             ),
                           ),
                         ],
                       ),
                       
                       SizedBox(height: isSmallScreen ? 8.h : 9.h),
                       
                       // Credit Card Usage Info
                      if (isCreditCardWithDebt) ...[
                          Text(
                            '${l10n.usage}: ${usagePercentage!.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 10.sp : 11.sp,
                              color: Colors.white.withValues(alpha: 1.0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                         SizedBox(height: isSmallScreen ? 4.h : 5.h),
                         
                          Container(
                            height: isSmallScreen ? 3.h : 4.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 1.5.r : 2.r),
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (usagePercentage! / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 1.5.r : 2.r),
                                  color: usagePercentage! > 80 
                                      ? const Color(0xFFFF453A)
                                      : usagePercentage! > 50 
                                          ? const Color(0xFFFF9F0A)
                                          : const Color(0xFF32D74B),
                                ),
                              ),
                            ),
                          ),
                          
                         SizedBox(height: isSmallScreen ? 2.h : 2.5.h),
                        ],
                        
                        SizedBox(height: isSmallScreen ? 3.h : 4.h),
                      
                      // Balance Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: isSmallScreen ? 7.h : 8.h),
                                 Text(
                                   isCreditCardWithDebt ? l10n.availableLimit : l10n.availableBalance,
                                   style: GoogleFonts.inter(
                                     fontSize: isSmallScreen ? 10.sp : 11.sp,
                                     color: Colors.white.withValues(alpha: 1.0),
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                                 CurrencyUtils.buildCurrencyText(
                                   themeProvider.formatAmount(balance),
                                   style: GoogleFonts.inter(
                                     fontSize: isSmallScreen ? 15.sp : 17.sp,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                   ),
                                   currency: themeProvider.currency,
                                 ),
                                 if (isCreditCardWithDebt) ...[
                                   CurrencyUtils.buildCurrencyText(
                                     '${l10n.debt}: ${themeProvider.formatAmount(totalDebt!)}',
                                     style: GoogleFonts.inter(
                                       fontSize: isSmallScreen ? 10.sp : 11.sp,
                                       fontWeight: FontWeight.w500,
                                       color: Colors.white.withValues(alpha: 1.0),
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
                                      size: isSmallScreen ? 10.w : 12.w,
                                    ),
                                    SizedBox(width: isSmallScreen ? 2.w : 3.w),
                                    Flexible(
                                       child: Text(
                                         '${l10n.lastPayment}: ${_formatDueDate(statementDate!, context)}',
                                         style: GoogleFonts.inter(
                                           fontSize: isSmallScreen ? 10.sp : 11.sp,
                                           color: Colors.white.withValues(alpha: 1.0),
                                           fontWeight: FontWeight.w500,
                                         ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                 SizedBox(height: isSmallScreen ? 3.h : 4.h),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Temassız ikon - sağ alt köşede
                Positioned(
                  right: isSmallScreen ? 12.w : 16.w,
                  bottom: isSmallScreen ? 8.h : 12.h,
                  child: Icon(
                    Icons.contactless,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: isSmallScreen ? 16.w : 18.w,
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
      bankCode != null ? AppConstants.getLocalizedBankName(bankCode!, AppLocalizations.of(context)!) : cardType,
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/bank_service.dart';
import '../../../l10n/app_localizations.dart';
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
  final VoidCallback? onTap;
  final VoidCallback? onStatementsPressed;

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
    this.onTap,
    this.onStatementsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Get bank design from BankService (dynamic) or fallback to AppConstants
    final bankService = BankService();
    final bank = bankCode != null ? bankService.getBankByCode(bankCode!) : null;
    
    final gradientColors = bank != null
        ? bank.gradientColorsList
        : (bankCode != null 
            ? AppConstants.getBankGradientColors(bankCode!)
            : AppConstants.getCardGradientColors(cardTypeLabel));
    final accentColor = bank != null
        ? bank.accentColorValue
        : (bankCode != null 
            ? AppConstants.getBankAccentColor(bankCode!)
            : AppConstants.getCardAccentColor(cardTypeLabel));
    final bankName = bank != null
        ? bank.name
        : (bankCode != null 
            ? AppConstants.getLocalizedBankName(bankCode!, AppLocalizations.of(context)!)
            : null);
    
    final isCreditCardWithDebt = totalDebt != null && creditLimit != null;
    
    // Responsive dimensions
    final cardHeight = isSmallScreen ? 200.h : 220.h;
    final cardPadding = isSmallScreen ? 12.w : 16.w;
    final borderRadius = isSmallScreen ? 14.r : 16.r;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
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
                              child: Text(
                                (cardName ?? (bankName != null ? '$bankName ${l10n.creditCard}' : cardTypeLabel)).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 10.sp : 11.sp,
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
                             padding: EdgeInsets.all(isSmallScreen ? 6.w : 8.w),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.15),
                               borderRadius: BorderRadius.circular(isSmallScreen ? 6.r : 8.r),
                             ),
                             child: Icon(
                               Icons.contactless_rounded,
                               color: Colors.white,
                               size: isSmallScreen ? 16.sp : 18.sp,
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
                                   isCreditCardWithDebt ? l10n.availableLimit : l10n.availableBalanceLabel,
                                   style: GoogleFonts.inter(
                                     fontSize: isSmallScreen ? 10.sp : 11.sp,
                                     color: Colors.white.withValues(alpha: 1.0),
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                                 SizedBox(height: isSmallScreen ? 3.h : 4.h),
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
                                   SizedBox(height: isSmallScreen ? 3.h : 4.h),
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
                              if (onStatementsPressed != null) ...[
                                GestureDetector(
                                  onTap: onStatementsPressed,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          size: 12.w,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          l10n.statements,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                              ],
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
                
              ],
            ),
          ),
        );
      },
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
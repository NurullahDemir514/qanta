import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../services/cash_management_service.dart';

class CashBalanceCard extends StatelessWidget {
  final double balance;
  final ThemeProvider themeProvider;
  final VoidCallback? onTap;

  const CashBalanceCard({
    super.key,
    required this.balance,
    required this.themeProvider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Responsive height with max limit
    final cardHeight = isSmallScreen ? 140.h : 160.h;
    final maxHeight = 180.h; // Max height limit
    final finalHeight = cardHeight > maxHeight ? maxHeight : cardHeight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: finalHeight,
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C2C2E),
                  const Color(0xFF1C1C1E),
                  const Color(0xFF0A0A0A),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE9ECEF),
                  const Color(0xFFDEE2E6),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: isDark
            ? Border.all(color: const Color(0xFF38383A), width: 1)
            : Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Stack(
        children: [
          // Holographic effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: AppConstants.getHolographicGradient(
                  AppConstants.getCardAccentColor('cash'),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isSmallScreen ? 32.w : 36.w,
                  height: isSmallScreen ? 32.w : 36.w,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isDark ? Colors.white : const Color(0xFF6D6D70),
                    size: isSmallScreen ? 16.w : 18.w,
                  ),
                ),
                Text(
                  l10n.cash,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 11.sp : 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 20.h : 24.h),

            // Balance başlığı
            Text(
              l10n.cashBalance,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 13.sp : 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
              ),
            ),

            SizedBox(height: isSmallScreen ? 8.h : 10.h),

            // Balance değeri ve Bakiye Güncelle butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    themeProvider.formatAmount(balance),
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 20.sp : 22.sp.clamp(16, 22),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Bakiye Güncelle butonu
                GestureDetector(
                  onTap: () {
                    // Bakiye güncelleme bottom sheet'ini aç
                    CashManagementService.showDirectUpdateDialog(
                      context,
                      balance,
                      (newBalance) {
                        // Balance updated callback - provider will automatically update
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8.w : 10.w,
                      vertical: isSmallScreen ? 4.h : 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: isSmallScreen ? 10.w : 12.w,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                        ),
                        SizedBox(width: isSmallScreen ? 2.w : 3.w),
                        Text(
                          l10n.updateBalance,
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

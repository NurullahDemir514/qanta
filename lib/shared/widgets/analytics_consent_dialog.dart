import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/analytics_consent_service.dart';

/// Anonim veri toplama izin modalı
class AnalyticsConsentDialog extends StatelessWidget {
  final VoidCallback? onConsentGiven;
  final VoidCallback? onConsentDeclined;

  const AnalyticsConsentDialog({
    super.key,
    this.onConsentGiven,
    this.onConsentDeclined,
  });

  /// Modalı göster
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onConsentGiven,
    VoidCallback? onConsentDeclined,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Kullanıcı karar vermeli
      builder: (context) => AnalyticsConsentDialog(
        onConsentGiven: onConsentGiven,
        onConsentDeclined: onConsentDeclined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1C1C1E),
                    const Color(0xFF2C2C2E),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF007AFF),
                    Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              l10n.analyticsConsentTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: 12.h),

            // Message
            Text(
              l10n.analyticsConsentMessage,
              textAlign: TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF6D6D70),
                height: 1.5,
              ),
            ),

            SizedBox(height: 20.h),

            // Buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                // Decline
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 140.w,
                  ),
                  child: OutlinedButton(
                    onPressed: () async {
                      await AnalyticsConsentService.saveConsent(false);
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                      }
                      onConsentDeclined?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      l10n.analyticsDecline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                  ),
                ),

                // Accept
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 140.w,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF007AFF),
                          Color(0xFF2E7D32),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                          blurRadius: 6.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await AnalyticsConsentService.saveConsent(true);
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                        onConsentGiven?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 16.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        l10n.analyticsAccept,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Notice
            Text(
              l10n.analyticsConsentNotice,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


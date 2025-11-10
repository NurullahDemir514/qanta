import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/utils/screen_compatibility.dart';
import '../../../l10n/app_localizations.dart';
import '../../premium/premium_offer_screen.dart';

/// Premium Upgrade Banner Widget
/// Shows upgrade to premium banner for free users
class PremiumUpgradeBanner extends StatelessWidget {
  const PremiumUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        if (premiumService.isPremium) return const SizedBox.shrink();
        
        return Container(
          margin: EdgeInsets.only(
            bottom: ScreenCompatibility.responsiveHeight(context, 12.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ScreenCompatibility.responsiveWidth(context, 16.0),
            vertical: ScreenCompatibility.responsiveHeight(context, 12.0),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
              ],
            ),
            borderRadius: BorderRadius.circular(
              ScreenCompatibility.responsiveWidth(context, 12.0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: ScreenCompatibility.responsiveFontSize(
                  context,
                  isSmallScreen ? 22.0 : 24.0,
                ),
              ),
              SizedBox(
                width: ScreenCompatibility.responsiveWidth(context, 12.0),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.upgradeToPremiumBanner,
                      style: GoogleFonts.inter(
                        fontSize: ScreenCompatibility.responsiveFontSize(
                          context,
                          isSmallScreen ? 14.0 : 15.0,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(
                      height: ScreenCompatibility.responsiveHeight(context, 3.0),
                    ),
                    Text(
                      l10n.premiumBannerSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: ScreenCompatibility.responsiveFontSize(
                          context,
                          isSmallScreen ? 11.0 : 12.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumOfferScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenCompatibility.responsiveWidth(context, 16.0),
                    vertical: ScreenCompatibility.responsiveHeight(context, 8.0),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      ScreenCompatibility.responsiveWidth(context, 8.0),
                    ),
                  ),
                  child: Text(
                    l10n.upgradeNow,
                    style: GoogleFonts.inter(
                      fontSize: ScreenCompatibility.responsiveFontSize(
                        context,
                        isSmallScreen ? 11.0 : 12.0,
                      ),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFA500),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


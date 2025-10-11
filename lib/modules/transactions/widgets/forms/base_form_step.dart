import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

class BaseFormStep extends StatelessWidget {
  final String title;
  final Widget content;
  final String? subtitle;
  final Widget? action;

  const BaseFormStep({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    
    // Responsive değerler - Mobil odaklı ve ekran boyutuna göre
    final titleFontSize = isSmallMobile ? 22.0 :
                         isMobile ? 24.0 :
                         isLargeMobile ? 26.0 :
                         isSmallTablet ? 28.0 :
                         isTablet ? 30.0 : 32.0;
    
    final subtitleFontSize = isSmallMobile ? 13.0 :
                            isMobile ? 14.0 :
                            isLargeMobile ? 15.0 :
                            isSmallTablet ? 16.0 :
                            isTablet ? 17.0 : 18.0;
    
    // Ekran boyutuna göre padding ayarla
    final verticalPadding = isSmallMobile ? 12.0 :
                           isMobile ? 14.0 :
                           isLargeMobile ? 16.0 :
                           isSmallTablet ? 18.0 :
                           isTablet ? 20.0 : 24.0;
    
    final titleSpacing = isSmallMobile ? 4.0 :
                        isMobile ? 5.0 :
                        isLargeMobile ? 6.0 :
                        isSmallTablet ? 7.0 :
                        isTablet ? 8.0 : 10.0;
    
    // Content spacing'i ekran boyutuna göre ayarla
    final contentSpacing = isSmallMobile ? 16.0 :
                          isMobile ? 20.0 :
                          isLargeMobile ? 24.0 :
                          isSmallTablet ? 28.0 :
                          isTablet ? 32.0 : 36.0;
    
    final actionSpacing = isSmallMobile ? 16.0 :
                         isMobile ? 18.0 :
                         isLargeMobile ? 20.0 :
                         isSmallTablet ? 24.0 :
                         isTablet ? 28.0 : 32.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mevcut alanı hesapla
        final availableHeight = constraints.maxHeight;
        final isLandscape = screenHeight < screenWidth;
        
        // Landscape modda daha kompakt spacing kullan
        final adjustedContentSpacing = isLandscape ? contentSpacing * 0.7 : contentSpacing;
        final adjustedActionSpacing = isLandscape ? actionSpacing * 0.7 : actionSpacing;
        
        return Padding(
          padding: EdgeInsets.all(verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Subtitle (optional)
              if (subtitle != null) ...[
                SizedBox(height: titleSpacing),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: adjustedContentSpacing),
              
              // Content - Flexible kullanarak kaydırmayı önle
              Flexible(
                child: content,
              ),
              
              // Action (optional)
              if (action != null) ...[
                SizedBox(height: adjustedActionSpacing),
                action!,
              ],
            ],
          ),
        );
      },
    );
  }
}

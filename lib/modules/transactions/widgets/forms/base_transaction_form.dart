import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

class BaseTransactionForm extends StatelessWidget {
  final String title;
  final List<String> stepTitles;
  final int currentStep;
  final PageController pageController;
  final List<Widget> steps;
  final VoidCallback? onNext;
  final VoidCallback? onSave;
  final VoidCallback? onBack;
  final String? nextButtonText;
  final String? saveButtonText;
  final bool isLoading;
  final bool isLastStep;

  const BaseTransactionForm({
    super.key,
    required this.title,
    required this.stepTitles,
    required this.currentStep,
    required this.pageController,
    required this.steps,
    this.onNext,
    this.onSave,
    this.onBack,
    this.nextButtonText,
    this.saveButtonText,
    this.isLoading = false,
    this.isLastStep = false,
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
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar (iPhone Pro Max)
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    final isLandscape = screenHeight < screenWidth;
    
    // Responsive değerler - Mobil odaklı
    final appBarHeight = isSmallMobile ? 52.0 : 
                        isMobile ? 54.0 : 
                        isLargeMobile ? 56.0 :
                        isSmallTablet ? 58.0 :
                        isTablet ? 60.0 : 64.0;
    
    final titleFontSize = isSmallMobile ? 15.0 :
                         isMobile ? 16.0 :
                         isLargeMobile ? 17.0 :
                         isSmallTablet ? 18.0 :
                         isTablet ? 20.0 : 22.0;
    
    final progressHeight = isSmallMobile ? 2.5 :
                          isMobile ? 3.0 :
                          isLargeMobile ? 3.5 :
                          isSmallTablet ? 4.0 :
                          isTablet ? 4.5 : 5.0;
    
    final progressPadding = isSmallMobile ? 16.0 :
                           isMobile ? 18.0 :
                           isLargeMobile ? 20.0 :
                           isSmallTablet ? 22.0 :
                           isTablet ? 24.0 : 28.0;
    
    final progressSpacing = isSmallMobile ? 6.0 :
                           isMobile ? 8.0 :
                           isLargeMobile ? 10.0 :
                           isSmallTablet ? 12.0 :
                           isTablet ? 14.0 : 16.0;
    
    final bottomPadding = isSmallMobile ? 16.0 :
                         isMobile ? 18.0 :
                         isLargeMobile ? 20.0 :
                         isSmallTablet ? 22.0 :
                         isTablet ? 24.0 : 28.0;
    
    final buttonHeight = isSmallMobile ? 44.0 :
                        isMobile ? 48.0 :
                        isLargeMobile ? 50.0 :
                        isSmallTablet ? 52.0 :
                        isTablet ? 56.0 : 60.0;
    
    final buttonFontSize = isSmallMobile ? 14.0 :
                          isMobile ? 15.0 :
                          isLargeMobile ? 16.0 :
                          isSmallTablet ? 17.0 :
                          isTablet ? 18.0 : 20.0;
    
    final buttonSpacing = isSmallMobile ? 8.0 :
                         isMobile ? 10.0 :
                         isLargeMobile ? 12.0 :
                         isSmallTablet ? 14.0 :
                         isTablet ? 16.0 : 20.0;
    
    final borderRadius = isSmallMobile ? 10.0 :
                        isMobile ? 11.0 :
                        isLargeMobile ? 12.0 :
                        isSmallTablet ? 14.0 :
                        isTablet ? 16.0 : 18.0;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: appBarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: isTablet ? 24.0 : 20.0,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: progressPadding, 
              vertical: isTablet ? 20.0 : 16.0,
            ),
            child: Row(
              children: List.generate(
                stepTitles.length,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < stepTitles.length - 1 ? progressSpacing : 0,
                    ),
                    height: progressHeight,
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? isDark 
                              ? Colors.white
                              : Colors.black
                          : isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(progressHeight / 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: steps,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(bottomPadding),
          child: currentStep == 0
              ? _buildSingleButton(context, l10n, isDark, buttonHeight, buttonFontSize, borderRadius)
              : _buildTwoButtons(context, l10n, isDark, buttonHeight, buttonFontSize, borderRadius, buttonSpacing),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, AppLocalizations l10n, bool isDark, double buttonHeight, double buttonFontSize, double borderRadius) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          nextButtonText ?? l10n.next,
          style: GoogleFonts.inter(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n, bool isDark, double buttonHeight, double buttonFontSize, double borderRadius) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark 
            ? const Color(0xFF2C2C2E) 
            : const Color(0xFFE5E5EA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isTablet ? 24.0 : 20.0,
                height: isTablet ? 24.0 : 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                saveButtonText ?? l10n.save,
                style: GoogleFonts.inter(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildSingleButton(BuildContext context, AppLocalizations l10n, bool isDark, double buttonHeight, double buttonFontSize, double borderRadius) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          nextButtonText ?? l10n.next,
          style: GoogleFonts.inter(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoButtons(BuildContext context, AppLocalizations l10n, bool isDark, double buttonHeight, double buttonFontSize, double borderRadius, double buttonSpacing) {
    return Row(
      children: [
        Expanded(
          child: _buildBackButton(context, l10n, isDark, buttonHeight, buttonFontSize, borderRadius),
        ),
        SizedBox(width: buttonSpacing),
        Expanded(
          child: isLastStep
              ? _buildSaveButton(context, l10n, isDark, buttonHeight, buttonFontSize, borderRadius)
              : _buildNextButton(context, l10n, isDark, buttonHeight, buttonFontSize, borderRadius),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, AppLocalizations l10n, bool isDark, double buttonHeight, double buttonFontSize, double borderRadius) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onBack,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          l10n.back,
          style: GoogleFonts.inter(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class BaseFormStep extends StatelessWidget {
  final String title;
  final Widget content;
  final EdgeInsets? padding;

  const BaseFormStep({
    super.key,
    required this.title,
    required this.content,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding ?? const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 40, // Padding'i çıkar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                content,
              ],
            ),
          ),
        );
      },
    );
  }
} 
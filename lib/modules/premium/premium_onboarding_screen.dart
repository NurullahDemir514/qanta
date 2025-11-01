import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Calm tarzı, sade ve şık iOS tarzı Premium Onboarding ekranı
/// Kullanıcı premium satın aldıktan sonra gösterilen kısa tanıtım
class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({super.key});

  @override
  State<PremiumOnboardingScreen> createState() => _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    
    // Scale animation için
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Fade animation için
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Son sayfada - Home'a yönlendir
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip butonu (sadece ilk 2 sayfada)
            if (_currentPage < 2)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      l10n.skip,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral,
                      ),
                    ),
                  ),
                ),
              ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  
                  // Her sayfa değiştiğinde animasyonları yeniden başlat
                  _scaleController.reset();
                  _fadeController.reset();
                  _scaleController.forward();
                  _fadeController.forward();
                },
                children: [
                  _buildWelcomePage(isDark, l10n),
                  _buildFeaturesPage(isDark, l10n),
                  _buildGetStartedPage(isDark, l10n),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? AppColors.primary
                          : isDark 
                              ? AppColors.neutral.withOpacity(0.3)
                              : AppColors.neutral.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildContinueButton(l10n),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Hoş Geldiniz Ekranı
  Widget _buildWelcomePage(bool isDark, AppLocalizations l10n) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Confetti/Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.mintGreen.withOpacity(0.3),
                      AppColors.mintGreen.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: AppColors.mintGreen,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Title
              Text(
                l10n.premiumWelcomeTitle,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                l10n.premiumWelcomeSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutral,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Premium Özellikler Ekranı
  Widget _buildFeaturesPage(bool isDark, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              l10n.premiumFeaturesTitle,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Features list
            _buildFeatureItem(
              icon: Icons.auto_awesome,
              title: l10n.premiumFeatureAI,
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            _buildFeatureItem(
              icon: Icons.insights,
              title: l10n.premiumFeatureReports,
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            _buildFeatureItem(
              icon: Icons.credit_card,
              title: l10n.premiumFeatureCards,
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            _buildFeatureItem(
              icon: Icons.trending_up,
              title: l10n.premiumFeatureStocks,
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            _buildFeatureItem(
              icon: Icons.block,
              title: l10n.premiumFeatureNoAds,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // 3. Başlayalım Ekranı
  Widget _buildGetStartedPage(bool isDark, AppLocalizations l10n) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rocket/Start icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.rocket_launch,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Title
              Text(
                l10n.premiumReadyTitle,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                l10n.premiumReadySubtitle,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutral,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Feature item widget
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkCard.withOpacity(0.5)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          
          // Checkmark
          Icon(
            Icons.check_circle,
            color: AppColors.mintGreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  // Continue button
  Widget _buildContinueButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextPage,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              _currentPage == 2 ? l10n.getStarted : l10n.continueButton,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


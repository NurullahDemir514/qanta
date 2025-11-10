import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/currency_utils.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/ios_dialog.dart';
import '../../shared/widgets/qanta_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5; // Welcome, Features, Language, Currency, Theme

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<bool> _showExitDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return await IOSDialog.show<bool>(
      context,
      title: l10n.exitOnboarding,
      message: l10n.exitOnboardingMessage,
      actions: [
        IOSDialogAction(
          text: l10n.exitCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        IOSDialogAction(
          text: l10n.exitOnboarding,
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Professional responsive breakpoints
    final isSmallMobile = screenWidth <= 375;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 375 && screenWidth <= 414;  // iPhone 12/13/14
    final isLargeMobile = screenWidth > 414 && screenWidth <= 480;  // iPhone Pro Max
    final isSmallTablet = screenWidth > 480 && screenWidth <= 768;  // iPad Mini
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // iPad
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // iPad Pro
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    final isLandscape = screenHeight < screenWidth;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF000000),
                      const Color(0xFF0A0A0A),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      const Color(0xFFF8F9FA),
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF1F3F4),
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: EdgeInsets.all(
                    isSmallMobile ? 20.0 :
                    isMobile ? 24.0 :
                    isLargeMobile ? 28.0 :
                    isSmallTablet ? 32.0 :
                    isTablet ? 36.0 :
                    isLargeTablet ? 40.0 : 44.0,
                  ),
                  child: Row(
                    children: List.generate(_totalPages, (index) {
                      return Expanded(
                        child: Container(
                          height: isSmallMobile ? 3 :
                                 isMobile ? 4 :
                                 isLargeMobile ? 4 :
                                 isSmallTablet ? 5 :
                                 isTablet ? 6 :
                                 isLargeTablet ? 6 : 7,
                          margin: EdgeInsets.only(
                            right: index < _totalPages - 1 ? (
                              isSmallMobile ? 6 :
                              isMobile ? 8 :
                              isLargeMobile ? 10 :
                              isSmallTablet ? 12 :
                              isTablet ? 14 :
                              isLargeTablet ? 16 : 18
                            ) : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentPage
                                ? const Color(0xFF6D6D70) // Sophisticated grey
                                : isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(
                              isSmallMobile ? 1.5 :
                              isMobile ? 2 :
                              isLargeMobile ? 2 :
                              isSmallTablet ? 2.5 :
                              isTablet ? 3 :
                              isLargeTablet ? 3 : 3.5,
                            ),
                          ),
                        ),
                      );
                    }),
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
                  },
                  children: [
                    _buildWelcomePage(l10n),
                    _buildFeaturesPage(l10n),
                    _buildLanguagePage(l10n),
                    _buildCurrencyPage(l10n),
                    _buildThemePage(l10n),
                  ],
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: EdgeInsets.all(
                  isSmallMobile ? 20.0 :
                  isMobile ? 24.0 :
                  isLargeMobile ? 28.0 :
                  isSmallTablet ? 32.0 :
                  isTablet ? 36.0 :
                  isLargeTablet ? 40.0 : 44.0,
                ),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: Container(
                          height: isSmallMobile ? 44 :
                                 isMobile ? 48 :
                                 isLargeMobile ? 50 :
                                 isSmallTablet ? 52 :
                                 isTablet ? 56 :
                                 isLargeTablet ? 58 : 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isSmallMobile ? 10 :
                              isMobile ? 12 :
                              isLargeMobile ? 12 :
                              isSmallTablet ? 14 :
                              isTablet ? 16 :
                              isLargeTablet ? 16 : 18,
                            ),
                            border: Border.all(
                              color: isDark 
                                  ? const Color(0xFF6D6D70)
                                  : const Color(0xFF6D6D70),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _previousPage,
                              borderRadius: BorderRadius.circular(
                                isSmallMobile ? 10 :
                                isMobile ? 12 :
                                isLargeMobile ? 12 :
                                isSmallTablet ? 14 :
                                isTablet ? 16 :
                                isLargeTablet ? 16 : 18,
                              ),
                              child: Center(
                                child: Text(
                                  l10n.back,
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallMobile ? 14 :
                                             isMobile ? 15 :
                                             isLargeMobile ? 16 :
                                             isSmallTablet ? 17 :
                                             isTablet ? 18 :
                                             isLargeTablet ? 19 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6D6D70),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) SizedBox(
                      width: isSmallMobile ? 12 :
                             isMobile ? 16 :
                             isLargeMobile ? 18 :
                             isSmallTablet ? 20 :
                             isTablet ? 22 :
                             isLargeTablet ? 24 : 26,
                    ),
                    Expanded(
                      flex: _currentPage == 0 ? 1 : 2,
                      child: Container(
                        height: isSmallMobile ? 44 :
                               isMobile ? 48 :
                               isLargeMobile ? 50 :
                               isSmallTablet ? 52 :
                               isTablet ? 56 :
                               isLargeTablet ? 58 : 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            isSmallMobile ? 10 :
                            isMobile ? 12 :
                            isLargeMobile ? 12 :
                            isSmallTablet ? 14 :
                            isTablet ? 16 :
                            isLargeTablet ? 16 : 18,
                          ),
                          color: const Color(0xFF6D6D70), // Sophisticated grey
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D6D70).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _nextPage,
                            borderRadius: BorderRadius.circular(
                              isSmallMobile ? 10 :
                              isMobile ? 12 :
                              isLargeMobile ? 12 :
                              isSmallTablet ? 14 :
                              isTablet ? 16 :
                              isLargeTablet ? 16 : 18,
                            ),
                            child: Center(
                              child: Text(
                                _currentPage == _totalPages - 1 ? l10n.getStarted : l10n.continueButton,
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile ? 14 :
                                           isMobile ? 15 :
                                           isLargeMobile ? 16 :
                                           isSmallTablet ? 17 :
                                           isTablet ? 18 :
                                           isLargeTablet ? 19 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildWelcomePage(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Professional responsive breakpoints
    final isSmallMobile = screenWidth <= 375;
    final isMobile = screenWidth > 375 && screenWidth <= 414;
    final isLargeMobile = screenWidth > 414 && screenWidth <= 480;
    final isSmallTablet = screenWidth > 480 && screenWidth <= 768;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200;
    final isDesktop = screenWidth > 1200;
    final isLandscape = screenHeight < screenWidth;
    
    return Padding(
      padding: EdgeInsets.all(
        isSmallMobile ? 24.0 :
        isMobile ? 28.0 :
        isLargeMobile ? 32.0 :
        isSmallTablet ? 36.0 :
        isTablet ? 40.0 :
        isLargeTablet ? 44.0 : 48.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple logo without circular container
          QantaLogo(
            size: isSmallMobile ? 120 :
                   isMobile ? 140 :
                   isLargeMobile ? 160 :
                   isSmallTablet ? 180 :
                   isTablet ? 200 :
                   isLargeTablet ? 220 : 240,
          ),
          SizedBox(
            height: isSmallMobile ? 32 :
                   isMobile ? 36 :
                   isLargeMobile ? 40 :
                   isSmallTablet ? 44 :
                   isTablet ? 48 :
                   isLargeTablet ? 52 : 56,
          ),
          Text(
            l10n.welcome,
            style: GoogleFonts.inter(
              fontSize: isSmallMobile ? 28 :
                       isMobile ? 32 :
                       isLargeMobile ? 36 :
                       isSmallTablet ? 40 :
                       isTablet ? 44 :
                       isLargeTablet ? 48 : 52,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: isSmallMobile ? 16 :
                   isMobile ? 18 :
                   isLargeMobile ? 20 :
                   isSmallTablet ? 22 :
                   isTablet ? 24 :
                   isLargeTablet ? 26 : 28,
          ),
          Text(
            l10n.onboardingDescription,
            style: GoogleFonts.inter(
              fontSize: isSmallMobile ? 16 :
                       isMobile ? 17 :
                       isLargeMobile ? 18 :
                       isSmallTablet ? 19 :
                       isTablet ? 20 :
                       isLargeTablet ? 21 : 22,
              fontWeight: FontWeight.w400,
              color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Professional responsive breakpoints
    final isSmallMobile = screenWidth <= 375;
    final isMobile = screenWidth > 375 && screenWidth <= 414;
    final isLargeMobile = screenWidth > 414 && screenWidth <= 480;
    final isSmallTablet = screenWidth > 480 && screenWidth <= 768;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200;
    final isDesktop = screenWidth > 1200;
    final isLandscape = screenHeight < screenWidth;
    
    // Single column layout for all screen sizes
    final isSingleColumn = true;
    
    return Padding(
      padding: EdgeInsets.all(
        isSmallMobile ? 20.0 :
        isMobile ? 24.0 :
        isLargeMobile ? 28.0 :
        isSmallTablet ? 32.0 :
        isTablet ? 36.0 :
        isLargeTablet ? 40.0 : 44.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingFeaturesTitle,
            style: GoogleFonts.inter(
              fontSize: isSmallMobile ? 22 :
                       isMobile ? 26 :
                       isLargeMobile ? 30 :
                       isSmallTablet ? 34 :
                       isTablet ? 38 :
                       isLargeTablet ? 42 : 46,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: isSmallMobile ? 24 :
                   isMobile ? 28 :
                   isLargeMobile ? 32 :
                   isSmallTablet ? 36 :
                   isTablet ? 40 :
                   isLargeTablet ? 44 : 48,
          ),
          // Single column layout for all screen sizes
          _buildFeatureItem(
            icon: Icons.account_balance_wallet,
            title: l10n.expenseTrackingTitle,
            description: l10n.expenseTrackingDescShort,
            color: const Color(0xFF6D6D70),
            isSmallMobile: isSmallMobile,
            isMobile: isMobile,
            isLargeMobile: isLargeMobile,
            isSmallTablet: isSmallTablet,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
            isDesktop: isDesktop,
            isDark: isDark,
          ),
          SizedBox(height: isSmallMobile ? 12 : 16),
          _buildFeatureItem(
            icon: Icons.credit_card,
            title: l10n.cardManagementTitle,
            description: l10n.cardManagementDescShort,
            color: const Color(0xFF007AFF),
            isSmallMobile: isSmallMobile,
            isMobile: isMobile,
            isLargeMobile: isLargeMobile,
            isSmallTablet: isSmallTablet,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
            isDesktop: isDesktop,
            isDark: isDark,
          ),
          SizedBox(height: isSmallMobile ? 12 : 16),
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: l10n.stockTrackingTitle,
            description: l10n.stockTrackingDescShort,
            color: const Color(0xFF4CAF50),
            isSmallMobile: isSmallMobile,
            isMobile: isMobile,
            isLargeMobile: isLargeMobile,
            isSmallTablet: isSmallTablet,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
            isDesktop: isDesktop,
            isDark: isDark,
          ),
          SizedBox(height: isSmallMobile ? 12 : 16),
          _buildFeatureItem(
            icon: Icons.account_balance,
            title: l10n.budgetManagementTitle,
            description: l10n.budgetManagementDescShort,
            color: const Color(0xFFFFC300),
            isSmallMobile: isSmallMobile,
            isMobile: isMobile,
            isLargeMobile: isLargeMobile,
            isSmallTablet: isSmallTablet,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
            isDesktop: isDesktop,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.translate,
            size: 80,
            color: const Color(0xFF6D6D70),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.languageSelectionTitle,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.languageSelectionDesc,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  _buildLanguageOption(
                    flag: '🇹🇷',
                    language: 'Türkçe',
                    isSelected: themeProvider.isTurkish,
                    onTap: () => themeProvider.setLocale(const Locale('tr')),
                  ),
                  SizedBox(height: 12.h),
                  _buildLanguageOption(
                    flag: '🇺🇸',
                    language: 'English',
                    isSelected: themeProvider.locale.languageCode == 'en',
                    onTap: () => themeProvider.setLocale(const Locale('en')),
                  ),
                  SizedBox(height: 12.h),
                  _buildLanguageOption(
                    flag: '🇩🇪',
                    language: 'Deutsch',
                    isSelected: themeProvider.isGerman,
                    onTap: () => themeProvider.setLocale(const Locale('de')),
                  ),
                  SizedBox(height: 12.h),
                  _buildLanguageOption(
                    flag: '🇮🇳',
                    language: 'हिंदी',
                    isSelected: themeProvider.locale.languageCode == 'hi',
                    onTap: () => themeProvider.setLocale(const Locale('hi')),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.currency_exchange,
            size: 80,
            color: const Color(0xFF6D6D70),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.selectCurrency,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectCurrencyDescription,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...Currency.values.map((c) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildCurrencyOption(
                              currency: c,
                              displayName: CurrencyUtils.getDisplayName(
                                c,
                                themeProvider.locale.languageCode,
                              ),
                              isSelected: themeProvider.currency == c,
                              onTap: () => themeProvider.setCurrency(c),
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette,
            size: 80,
            color: const Color(0xFF6D6D70),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.themeSelectionTitle,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.themeSelectionDesc,
            style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  _buildThemeOption(
                    icon: Icons.light_mode,
                    title: l10n.lightThemeTitle,
                    description: l10n.lightThemeDesc,
                    isSelected: !themeProvider.isDarkMode,
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.light);
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildThemeOption(
                    icon: Icons.dark_mode,
                    title: l10n.darkThemeTitle,
                    description: l10n.darkThemeDesc,
                    isSelected: themeProvider.isDarkMode,
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.dark);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSmallMobile,
    required bool isMobile,
    required bool isLargeMobile,
    required bool isSmallTablet,
    required bool isTablet,
    required bool isLargeTablet,
    required bool isDesktop,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isSmallMobile ? 16 :
        isMobile ? 18 :
        isLargeMobile ? 20 :
        isSmallTablet ? 22 :
        isTablet ? 24 :
        isLargeTablet ? 26 : 28,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(
          isSmallMobile ? 12 :
          isMobile ? 14 :
          isLargeMobile ? 16 :
          isSmallTablet ? 18 :
          isTablet ? 20 :
          isLargeTablet ? 22 : 24,
        ),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 48 :
                   isMobile ? 52 :
                   isLargeMobile ? 56 :
                   isSmallTablet ? 60 :
                   isTablet ? 64 :
                   isLargeTablet ? 68 : 72,
            height: isSmallMobile ? 48 :
                   isMobile ? 52 :
                   isLargeMobile ? 56 :
                   isSmallTablet ? 60 :
                   isTablet ? 64 :
                   isLargeTablet ? 68 : 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 12 :
                isMobile ? 14 :
                isLargeMobile ? 16 :
                isSmallTablet ? 18 :
                isTablet ? 20 :
                isLargeTablet ? 22 : 24,
              ),
            ),
            child: Icon(
              icon,
              size: isSmallMobile ? 24 :
                     isMobile ? 26 :
                     isLargeMobile ? 28 :
                     isSmallTablet ? 30 :
                     isTablet ? 32 :
                     isLargeTablet ? 34 : 36,
              color: color,
            ),
          ),
          SizedBox(
            width: isSmallMobile ? 16 :
                   isMobile ? 18 :
                   isLargeMobile ? 20 :
                   isSmallTablet ? 22 :
                   isTablet ? 24 :
                   isLargeTablet ? 26 : 28,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 16 :
                             isMobile ? 17 :
                             isLargeMobile ? 18 :
                             isSmallTablet ? 19 :
                             isTablet ? 20 :
                             isLargeTablet ? 21 : 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(
                  height: isSmallMobile ? 4 :
                         isMobile ? 5 :
                         isLargeMobile ? 6 :
                         isSmallTablet ? 7 :
                         isTablet ? 8 :
                         isLargeTablet ? 9 : 10,
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 13 :
                             isMobile ? 14 :
                             isLargeMobile ? 15 :
                             isSmallTablet ? 16 :
                             isTablet ? 17 :
                             isLargeTablet ? 18 : 19,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w.clamp(12.w, 20.w),
          vertical: 12.h.clamp(8.h, 16.h),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF6D6D70) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5.w.clamp(1.w, 2.w),
          ),
          borderRadius: BorderRadius.circular(10.r.clamp(8.r, 12.r)),
          color: isSelected ? const Color(0xFF6D6D70).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Text(
              flag, 
              style: TextStyle(fontSize: 20.sp.clamp(16.sp, 24.sp)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                language,
                style: GoogleFonts.inter(
                  fontSize: 16.sp.clamp(14.sp, 18.sp),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF6D6D70),
                size: 20.sp.clamp(16.sp, 24.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption({
    required Currency currency,
    required String displayName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w.clamp(12.w, 20.w),
          vertical: 12.h.clamp(8.h, 16.h),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF6D6D70) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5.w.clamp(1.w, 2.w),
          ),
          borderRadius: BorderRadius.circular(10.r.clamp(8.r, 12.r)),
          color: isSelected ? const Color(0xFF6D6D70).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Text(
              currency.symbol,
              style: GoogleFonts.inter(
                fontSize: 20.sp.clamp(16.sp, 24.sp),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 16.sp.clamp(14.sp, 18.sp),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF6D6D70),
                size: 20.sp.clamp(16.sp, 24.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w.clamp(12.w, 20.w),
          vertical: 12.h.clamp(8.h, 16.h),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF6D6D70) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5.w.clamp(1.w, 2.w),
          ),
          borderRadius: BorderRadius.circular(10.r.clamp(8.r, 12.r)),
          color: isSelected ? const Color(0xFF6D6D70).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp.clamp(20.sp, 28.sp),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp.clamp(14.sp, 18.sp),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp.clamp(10.sp, 14.sp),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF6D6D70),
                size: 20.sp.clamp(16.sp, 24.sp),
              ),
          ],
        ),
      ),
    );
  }
} 

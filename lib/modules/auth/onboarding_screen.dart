import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/currency_utils.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/ios_dialog.dart';

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
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index < _totalPages - 1 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? const Color(0xFF10B981)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
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
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF10B981)),
                          ),
                          child: Text(
                            l10n.back,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentPage == 0 ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentPage == _totalPages - 1 ? l10n.getStarted : l10n.continueButton,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildWelcomePage(AppLocalizations l10n) {
    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
              color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Q',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.welcome,
            style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
            l10n.onboardingDescription,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingFeaturesTitle,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(
            icon: Icons.account_balance_wallet,
            title: l10n.expenseTrackingTitle,
            description: l10n.expenseTrackingDesc,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: l10n.smartSavingsTitle,
            description: l10n.smartSavingsDesc,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.analytics,
            title: l10n.financialAnalysisTitle,
            description: l10n.financialAnalysisDesc,
            color: const Color(0xFF9C27B0),
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
            Icons.language,
            size: 80,
            color: const Color(0xFF10B981),
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
                  const SizedBox(height: 16),
                  _buildLanguageOption(
                    flag: '🇺🇸',
                    language: 'English',
                    isSelected: !themeProvider.isTurkish,
                    onTap: () => themeProvider.setLocale(const Locale('en')),
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
            Icons.monetization_on,
            size: 80,
            color: const Color(0xFF10B981),
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
              return Column(
                children: [
                  _buildCurrencyOption(
                    currency: Currency.TRY,
                    displayName: l10n.currencyTRY,
                    isSelected: themeProvider.currency == Currency.TRY,
                    onTap: () => themeProvider.setCurrency(Currency.TRY),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrencyOption(
                    currency: Currency.USD,
                    displayName: l10n.currencyUSD,
                    isSelected: themeProvider.currency == Currency.USD,
                    onTap: () => themeProvider.setCurrency(Currency.USD),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrencyOption(
                    currency: Currency.EUR,
                    displayName: l10n.currencyEUR,
                    isSelected: themeProvider.currency == Currency.EUR,
                    onTap: () => themeProvider.setCurrency(Currency.EUR),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrencyOption(
                    currency: Currency.GBP,
                    displayName: l10n.currencyGBP,
                    isSelected: themeProvider.currency == Currency.GBP,
                    onTap: () => themeProvider.setCurrency(Currency.GBP),
                  ),
                ],
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
            color: const Color(0xFF10B981),
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
                  const SizedBox(height: 16),
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
  }) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
                ),
          child: Icon(
            icon,
            size: 30,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              language,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Text(
              currency.symbol,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
            ),
          ],
        ),
      ),
    );
  }
} 
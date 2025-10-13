import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/services/quick_note_notification_service.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../l10n/app_localizations.dart';
import '../stocks/providers/stock_provider.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../profile/profile_screen.dart';
import '../cards/cards_screen.dart';
import '../cards/widgets/add_card_fab.dart';
import '../transactions/index.dart';
import '../transactions/screens/transactions_screen.dart';
import '../insights/statistics_screen.dart';
import '../calendar/calendar_screen.dart';
import '../stocks/screens/stocks_screen.dart';
import 'widgets/main_tab_bar.dart';
import 'widgets/balance_overview_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/cards_section.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/quick_notes_card.dart';
import 'widgets/top_gainers_section.dart';
import 'utils/greeting_utils.dart';
import '../../core/providers/profile_provider.dart';
import '../../shared/widgets/quick_note_dialog.dart';
import '../../shared/widgets/reminder_checker.dart';
import '../../modules/advertisement/services/google_ads_real_banner_service.dart';
import '../../modules/advertisement/config/advertisement_config.dart' as config;
import '../../modules/advertisement/models/advertisement_models.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              const TransactionsScreen(),
              const CardsScreen(),
              const StatisticsScreen(),
              const CalendarScreen(),
              const StocksScreen(),
            ],
          ),
          MainTabBar(currentIndex: _currentIndex, onTabChanged: _onTabChanged),
          if (_currentIndex != 2 && _currentIndex != 4 && _currentIndex != 5) const TransactionFab(),
          if (_currentIndex == 2) AddCardFab(currentTabIndex: _currentIndex),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, IconData icon, Color color) {
    // This method can be removed now as we're using the actual StatisticsScreen
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.comingSoon,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleAdsRealBannerService _budgetBannerService;

  @override
  void initState() {
    super.initState();
    
    // Bütçe kartından sonraki banner reklam service'ini başlat
    _budgetBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.testBanner4.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: true,
    );
    
    // İkinci reklamı hemen yükle
    _budgetBannerService.loadAd();
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Data already loaded in splash screen, no need to reload
      // Set context for notification service
      QuickNoteNotificationService.setContext(context);
      
      debugPrint('🏠 HomeScreen.initState() - Data loading completed');
    });
  }

  @override
  void dispose() {
    _budgetBannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final fullName = profileProvider.userName ?? l10n.defaultUserName;
        final firstName = GreetingUtils.getFirstName(fullName);
        final profileImageUrl = profileProvider.profileImageUrl;

        return Stack(
          children: [
            AppPageScaffold(
              title: l10n.greetingHello(firstName),
              subtitle: GreetingUtils.getGreetingByTime(l10n),
              titleFontSize: 20, // Daha büyük başlık
              subtitleFontSize: 13, // Daha küçük alt başlık
              bottomPadding: 125,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ProfileAvatar(
                    imageUrl: profileImageUrl,
                    userName: fullName,
                    size: 44,
                    showBorder: true,
                    onTap: () {
                      _navigateToProfile(context);
                    },
                  ),
                ),
              ],
              body: SliverToBoxAdapter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double containerWidth = constraints.maxWidth * 1;
                        return SizedBox(
                          width: containerWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BalanceOverviewCard(),
                              // TopGainersSection - Kendi içinde reactive
                              const Column(
                                children: [
                                  SizedBox(height: 20),
                                  TopGainersSection(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const BudgetOverviewCard(),
                              // Banner reklam - Bütçe kartından sonra (sadece yüklendiyse göster)
                              if (_budgetBannerService.isLoaded && _budgetBannerService.bannerWidget != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  height: 50,
                                  child: _budgetBannerService.bannerWidget!,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (!_budgetBannerService.isLoaded || _budgetBannerService.bannerWidget == null)
                                const SizedBox(height: 20),
                              const CardsSection(),
                              const SizedBox(height: 20),
                              const RecentTransactionsSection(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog(BuildContext context) {
    // Implementation of _showAddCardDialog method
  }

  /// Navigate to profile screen
  void _navigateToProfile(BuildContext context) {
    // Navigate directly to profile screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }
}

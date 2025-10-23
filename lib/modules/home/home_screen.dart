import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../core/services/premium_service.dart';
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
import 'widgets/top_gainers_section.dart';
import 'utils/greeting_utils.dart';
import '../../core/providers/profile_provider.dart';
import '../../shared/widgets/reminder_checker.dart';
import '../../modules/advertisement/config/advertisement_config.dart' as config;
import '../../modules/advertisement/services/native_ad_service.dart';
import '../../core/services/analytics_consent_service.dart';
import '../../shared/widgets/analytics_consent_dialog.dart';
import '../advertisement/providers/advertisement_provider.dart';
import '../advertisement/services/google_ads_interstitial_service.dart';
import '../premium/premium_offer_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  int _statisticsTabVisitCount = 0; // İstatistik sekmesi kaç kez ziyaret edildi
  int _transactionsTabVisitCount = 0; // İşlemler sekmesi kaç kez ziyaret edildi
  int _stocksTabVisitCount = 0; // Yatırım sekmesi kaç kez ziyaret edildi
  late GoogleAdsInterstitialService _transactionsInterstitialService;
  late GoogleAdsInterstitialService _stocksInterstitialService;
  late PremiumService _premiumService;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Transactions için interstitial servisini başlat
    _transactionsInterstitialService = GoogleAdsInterstitialService(
      adUnitId: config.AdvertisementConfig.transactionsInterstitial.interstitialAdUnitId,
      isTestMode: false,
    );
    
    // Stocks için interstitial servisini başlat
    _stocksInterstitialService = GoogleAdsInterstitialService(
      adUnitId: config.AdvertisementConfig.stocksInterstitial.interstitialAdUnitId,
      isTestMode: false,
    );
    
    // Reklamları yükle
    _transactionsInterstitialService.loadAd();
    _stocksInterstitialService.loadAd();
    
    // Premium service'i al ve dinle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _premiumService = context.read<PremiumService>();
      _premiumService.addListener(_onPremiumChanged);
    });
  }
  
  void _onPremiumChanged() {
    if (!_premiumService.isPremium) {
      // Premium kapatıldığında sayaçları sıfırla (tekrar reklam gösterebilmek için)
      setState(() {
        _transactionsTabVisitCount = 0;
        _stocksTabVisitCount = 0;
      });
      debugPrint('💎 Premium deactivated - Resetting visit counters');
    }
  }

  @override
  void dispose() {
    _premiumService.removeListener(_onPremiumChanged);
    _transactionsInterstitialService.dispose();
    _stocksInterstitialService.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      
      // İstatistik sekmesine (index 3) geçildiğinde sayacı artır
      if (index == 3) {
        _statisticsTabVisitCount++;
      }
      
      // İşlemler sekmesine (index 1) geçildiğinde
      if (index == 1) {
        _transactionsTabVisitCount++;
        debugPrint('📊 Transactions tab visit count: $_transactionsTabVisitCount');
        
        // İlk ziyaret VEYA 3'ün katları (3, 6, 9, ...) ise reklam göster
        if (_transactionsTabVisitCount == 1 || _transactionsTabVisitCount % 3 == 0) {
          debugPrint('🎬 Transactions: Should show ad (visit #$_transactionsTabVisitCount)');
          _showTransactionsInterstitialAd();
        }
      }
      
      // Yatırım sekmesine (index 5) geçildiğinde
      if (index == 5) {
        _stocksTabVisitCount++;
        debugPrint('📊 Stocks tab visit count: $_stocksTabVisitCount');
        
        // İlk ziyaret VEYA 3'ün katları (3, 6, 9, ...) ise reklam göster
        if (_stocksTabVisitCount == 1 || _stocksTabVisitCount % 3 == 0) {
          debugPrint('🎬 Stocks: Should show ad (visit #$_stocksTabVisitCount)');
          _showStocksInterstitialAd();
        }
      }
    });
  }

  /// İşlemler sayfası için geçiş reklamını göster
  Future<void> _showTransactionsInterstitialAd() async {
    // Premium kullanıcılar için reklam gösterme
    if (_premiumService.isPremium) {
      debugPrint('💎 Transactions: Premium user - Skipping interstitial ad');
      return;
    }
    
    // Bir saniye bekle (smooth geçiş için)
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    try {
      // Interstitial reklamın yüklenmesini bekle (max 15 saniye)
      int loadAttempts = 0;
      while (!_transactionsInterstitialService.isLoaded && loadAttempts < 30) {
        debugPrint('⏳ Transactions: Waiting for ad to load... (${loadAttempts + 1}/30)');
        await Future.delayed(const Duration(milliseconds: 500));
        loadAttempts++;
      }
      
      if (!_transactionsInterstitialService.isLoaded) {
        debugPrint('⚠️ Transactions: Interstitial ad not loaded after 15 seconds');
        debugPrint('💡 TIP: Test cihazlarda AdMob "No fill" nedeniyle reklam göstermeyebilir');
        return;
      }
      
      debugPrint('🎬 Transactions: Showing interstitial ad...');
      await _transactionsInterstitialService.showInterstitialAd();
      debugPrint('✅ Transactions: Interstitial ad shown successfully');
      
      // Bir sonraki için reklamı tekrar yükle
      _transactionsInterstitialService.loadAd();
    } catch (e) {
      debugPrint('❌ Transactions: Failed to show ad: $e');
    }
  }

  /// Yatırım (Stocks) sayfası için geçiş reklamını göster
  Future<void> _showStocksInterstitialAd() async {
    // Premium kullanıcılar için reklam gösterme
    if (_premiumService.isPremium) {
      debugPrint('💎 Stocks: Premium user - Skipping interstitial ad');
      return;
    }
    
    // Bir saniye bekle (smooth geçiş için)
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    try {
      // Interstitial reklamın yüklenmesini bekle (max 15 saniye)
      int loadAttempts = 0;
      while (!_stocksInterstitialService.isLoaded && loadAttempts < 30) {
        debugPrint('⏳ Stocks: Waiting for ad to load... (${loadAttempts + 1}/30)');
        await Future.delayed(const Duration(milliseconds: 500));
        loadAttempts++;
      }
      
      if (!_stocksInterstitialService.isLoaded) {
        debugPrint('⚠️ Stocks: Interstitial ad not loaded after 15 seconds');
        debugPrint('💡 TIP: Test cihazlarda AdMob "No fill" nedeniyle reklam göstermeyebilir');
        return;
      }
      
      debugPrint('🎬 Stocks: Showing interstitial ad...');
      await _stocksInterstitialService.showInterstitialAd();
      debugPrint('✅ Stocks: Interstitial ad shown successfully');
      
      // Bir sonraki için reklamı tekrar yükle
      _stocksInterstitialService.loadAd();
    } catch (e) {
      debugPrint('❌ Stocks: Failed to show ad: $e');
    }
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
              StatisticsScreen(
                key: ValueKey(_statisticsTabVisitCount),
                isActive: _currentIndex == 3, // Sadece bu tab aktifken true
              ),
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
  late NativeAdService _homeNativeAd;
  late PremiumService _premiumService;

  @override
  void initState() {
    super.initState();
    
    // Yerel gelişmiş reklam
    _homeNativeAd = NativeAdService(
      adUnitId: config.AdvertisementConfig.production.nativeAdUnitId!,
    );
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Premium service listener ekle
      _premiumService = context.read<PremiumService>();
      _premiumService.addListener(_onPremiumChanged);
      
      // Premium değilse reklamı yükle
      if (!_premiumService.isPremium) {
        _homeNativeAd.load();
        debugPrint('💎 HomeScreen: Loading native ad (not premium)');
      } else {
        debugPrint('💎 HomeScreen: Skipping native ad (premium user)');
      }
      // Data already loaded in splash screen, no need to reload
      // Set context for notification service
      NotificationService().setContext(context);
      
      // Initialize advertisement provider
      final adProvider = context.read<AdvertisementProvider>();
      adProvider.initialize();
      
      debugPrint('🏠 HomeScreen.initState() - Data loading completed');
      
      // Analytics consent kontrolü - sadece ilk açılışta
      _checkAndShowAnalyticsConsent();
    });
  }

  void _onPremiumChanged() {
    if (_premiumService.isPremium) {
      // Premium aktif - Native ad'ı dispose et
      _homeNativeAd.disposeAd();
      setState(() {}); // UI'ı güncelle
      debugPrint('💎 HomeScreen: Premium active - Native ad disposed');
    } else {
      // Premium kapatıldı - Native ad'ı tekrar yükle
      _homeNativeAd.load();
      setState(() {}); // UI'ı güncelle
      debugPrint('💎 HomeScreen: Premium deactivated - Reloading native ad');
    }
  }

  /// Analytics consent kontrolü ve modalı göster
  Future<void> _checkAndShowAnalyticsConsent() async {
    try {
      // Daha önce sorulmuş mu kontrol et
      final hasBeenAsked = await AnalyticsConsentService.hasBeenAsked();
      
      if (!hasBeenAsked && mounted) {
        // 1 saniye bekle (smooth görünüm için)
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        // Modalı göster
        await AnalyticsConsentDialog.show(
          context,
          onConsentGiven: () {
            debugPrint('✅ Analytics consent given');
          },
          onConsentDeclined: () {
            debugPrint('❌ Analytics consent declined');
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking analytics consent: $e');
    }
  }

  @override
  void dispose() {
    _premiumService.removeListener(_onPremiumChanged);
    _homeNativeAd.disposeAd();
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
                Consumer<PremiumService>(
                  builder: (context, premiumService, child) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ProfileAvatar(
                        imageUrl: profileImageUrl,
                        userName: fullName,
                        size: 44,
                        showBorder: true,
                        isPremium: premiumService.isPremium,
                        onTap: () {
                          _navigateToProfile(context);
                        },
                      ),
                    );
                  },
                ),
              ],
              body: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                      const SizedBox(height: 20),
                      // Native Ad - RecentTransactionsSection üstü (Premium kullanıcılara gösterilmez)
                      Consumer<PremiumService>(
                        builder: (context, premiumService, child) {
                          if (premiumService.isPremium) return const SizedBox.shrink();
                          
                          if (_homeNativeAd.isLoaded && _homeNativeAd.adWidget != null) {
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  height: 90,
                                  child: _homeNativeAd.adWidget!,
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const CardsSection(),
                      const SizedBox(height: 20),
                      const RecentTransactionsSection(),
                      const SizedBox(height: 16),
                    ],
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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
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
import 'widgets/subscriptions_overview_card.dart';
import 'widgets/cards_section.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/top_gainers_section.dart';
import 'utils/greeting_utils.dart';
import '../../core/providers/profile_provider.dart';
import '../../shared/widgets/reminder_checker.dart';
import '../../modules/advertisement/config/advertisement_config.dart' as config;
import '../../modules/advertisement/services/native_ad_service.dart';
import '../advertisement/providers/advertisement_provider.dart';
import '../advertisement/services/google_ads_interstitial_service.dart';
import '../premium/premium_offer_screen.dart';
import '../../shared/utils/fab_positioning.dart';
import '../transactions/widgets/quick_add_chat_fab.dart';
import '../../core/services/tutorial_service.dart';
import '../../shared/widgets/tutorial_overlay.dart';
import '../../shared/models/tutorial_step_model.dart';
import '../transactions/widgets/transaction_fab.dart';

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
  
  // Tutorial için keys
  final GlobalKey _balanceOverviewTutorialKey = GlobalKey();
  final GlobalKey _fabTutorialKey = GlobalKey();
  final GlobalKey _recentTransactionsTutorialKey = GlobalKey();
  final GlobalKey _aiChatTutorialKey = GlobalKey();
  final GlobalKey _cardsSectionTutorialKey = GlobalKey();
  final GlobalKey _bottomNavTutorialKey = GlobalKey();
  final GlobalKey _budgetOverviewTutorialKey = GlobalKey();
  final GlobalKey _profileAvatarTutorialKey = GlobalKey();

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
      
      // Tutorial kontrolü - İlk açılışta göster
      _checkAndShowTutorial();
    });
  }
  
  /// Tutorial kontrolü ve gösterimi
  Future<void> _checkAndShowTutorial() async {
    try {
      // Tutorial gösterilmeli mi kontrol et
      final shouldShow = await TutorialService.shouldShowTutorial();
      
      if (!shouldShow || !mounted) return;
      
      // Widget'ların render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Tutorial steps oluştur - Tüm adımlar birbirine bağlı
      // HomeScreen'in render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      final steps = [
        // Step 1: Balance Overview (Total Assets) tutorial
        TutorialStep.balanceOverview(
          targetKey: _balanceOverviewTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Balance Overview tutorial step completed');
          },
        ),
        // Step 2: FAB tutorial
        TutorialStep.fab(
          targetKey: _fabTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ FAB tutorial step completed');
          },
        ),
        // Step 3: Recent Transactions tutorial
        TutorialStep.recentTransactions(
          targetKey: _recentTransactionsTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Recent Transactions tutorial step completed');
          },
        ),
        // Step 4: AI Chat tutorial
        TutorialStep.aiChat(
          targetKey: _aiChatTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ AI Chat tutorial step completed');
          },
        ),
        // Step 5: Budget Overview tutorial
        TutorialStep.budgetOverview(
          targetKey: _budgetOverviewTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Budget Overview tutorial step completed');
          },
        ),
        // Step 6: Cards Section tutorial
        TutorialStep.cardsSection(
          targetKey: _cardsSectionTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Cards Section tutorial step completed');
          },
        ),
        // Step 7: Bottom Navigation tutorial
        TutorialStep.bottomNavigation(
          targetKey: _bottomNavTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Bottom Navigation tutorial step completed');
          },
        ),
        // Step 8: Profile Avatar tutorial
        TutorialStep.profileAvatar(
          targetKey: _profileAvatarTutorialKey,
          onStepCompleted: () {
            debugPrint('✅ Profile Avatar tutorial step completed');
          },
        ),
      ];
      
      // Tutorial göster
      await TutorialOverlay.show(
        context,
        steps,
        onCompleted: () {
          debugPrint('✅ Tutorial completed');
        },
        onSkipped: () {
          debugPrint('⏭️ Tutorial skipped');
        },
      );
    } catch (e) {
      debugPrint('❌ Tutorial error: $e');
    }
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
              HomeScreen(
                cardsSectionKey: _cardsSectionTutorialKey, // Key'i geçir
                balanceOverviewKey: _balanceOverviewTutorialKey, // Balance Overview key'i geçir
                fabTutorialKey: _fabTutorialKey, // FAB key'i geçir (debug butonu için)
                recentTransactionsKey: _recentTransactionsTutorialKey, // Recent Transactions key'i geçir
                aiChatTutorialKey: _aiChatTutorialKey, // AI Chat key'i geçir (debug butonu için)
                budgetOverviewKey: _budgetOverviewTutorialKey, // Budget Overview key'i geçir
                profileAvatarKey: _profileAvatarTutorialKey, // Profile Avatar key'i geçir
                bottomNavKey: _bottomNavTutorialKey, // Bottom Nav key'i geçir (debug butonu için)
              ),
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
          MainTabBar(
            currentIndex: _currentIndex,
            onTabChanged: _onTabChanged,
            tutorialKey: _bottomNavTutorialKey, // Tutorial key ekle
          ),
          // FAB'ları Recent Transactions tutorial adımında gizle
          if (_currentIndex != 2 && _currentIndex != 4 && _currentIndex != 5 && !TutorialService.isRecentTransactionsStep)
            Builder(
              builder: (context) {
                final baseBottom = FabPositioning.getBottomPosition(context);
                return TransactionFab(
                  customBottom: baseBottom + 60,
                  tutorialKey: _fabTutorialKey, // Tutorial key ekle
                );
              },
            ),
          if (_currentIndex != 2 && _currentIndex != 4 && _currentIndex != 5 && !TutorialService.isRecentTransactionsStep)
            Builder(
              builder: (context) {
                final right = FabPositioning.getRightPosition(context);
                final baseBottom = FabPositioning.getBottomPosition(context);
                // Stocks ekranındaki düzenle aynı: Chat en altta (baseBottom)
                return QuickAddChatFAB(
                  customRight: right,
                  customBottom: baseBottom,
                  tutorialKey: _aiChatTutorialKey, // Tutorial key ekle
                );
              },
            ),
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
  final GlobalKey? cardsSectionKey; // Tutorial için key
  final GlobalKey? balanceOverviewKey; // Tutorial için Balance Overview key
  final GlobalKey? fabTutorialKey; // Tutorial için FAB key
  final GlobalKey? recentTransactionsKey; // Tutorial için Recent Transactions key
  final GlobalKey? aiChatTutorialKey; // Tutorial için AI Chat key
  final GlobalKey? budgetOverviewKey; // Tutorial için Budget Overview key
  final GlobalKey? profileAvatarKey; // Tutorial için Profile Avatar key
  final GlobalKey? bottomNavKey; // Tutorial için Bottom Navigation key
  
  const HomeScreen({
    super.key,
    this.cardsSectionKey,
    this.balanceOverviewKey,
    this.fabTutorialKey,
    this.recentTransactionsKey,
    this.aiChatTutorialKey,
    this.budgetOverviewKey,
    this.profileAvatarKey,
    this.bottomNavKey,
  });

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
    });
  }
  
  /// Debug: Tutorial'ı manuel başlat (kDebugMode)
  Future<void> _startTutorialDebug() async {
    try {
      // Tutorial'ı reset et (debug için)
      await TutorialService.resetTutorial();
      
      // Widget'ların render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Tüm tutorial adımları (MainScreen'den geçirilen key'ler ile)
      final steps = [
        // Step 1: Balance Overview (Total Assets) tutorial
        TutorialStep.balanceOverview(
          targetKey: widget.balanceOverviewKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Balance Overview tutorial step completed');
          },
        ),
        // Step 2: FAB tutorial
        TutorialStep.fab(
          targetKey: widget.fabTutorialKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] FAB tutorial step completed');
          },
        ),
        // Step 3: Recent Transactions tutorial
        TutorialStep.recentTransactions(
          targetKey: widget.recentTransactionsKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Recent Transactions tutorial step completed');
          },
        ),
        // Step 4: AI Chat tutorial
        TutorialStep.aiChat(
          targetKey: widget.aiChatTutorialKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] AI Chat tutorial step completed');
          },
        ),
        // Step 5: Budget Overview tutorial
        TutorialStep.budgetOverview(
          targetKey: widget.budgetOverviewKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Budget Overview tutorial step completed');
          },
        ),
        // Step 6: Cards Section tutorial
        TutorialStep.cardsSection(
          targetKey: widget.cardsSectionKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Cards Section tutorial step completed');
          },
        ),
        // Step 7: Bottom Navigation tutorial
        TutorialStep.bottomNavigation(
          targetKey: widget.bottomNavKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Bottom Navigation tutorial step completed');
          },
        ),
        // Step 8: Profile Avatar tutorial
        TutorialStep.profileAvatar(
          targetKey: widget.profileAvatarKey ?? GlobalKey(),
          onStepCompleted: () {
            debugPrint('✅ [DEBUG] Profile Avatar tutorial step completed');
          },
        ),
      ];
      
      // Tutorial göster (Debug: Tüm adımlar)
      await TutorialOverlay.show(
        context,
        steps,
        onCompleted: () {
          debugPrint('✅ [DEBUG] Tutorial completed');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎓 Tutorial tamamlandı!'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF34D399),
              ),
            );
          }
        },
        onSkipped: () {
          debugPrint('⏭️ [DEBUG] Tutorial skipped');
        },
      );
    } catch (e) {
      debugPrint('❌ [DEBUG] Tutorial error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Tutorial hatası: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                // Debug: Tutorial butonu (kDebugMode)
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.school_outlined),
                      tooltip: 'Tutorial Başlat (Debug)',
                      onPressed: () => _startTutorialDebug(),
                      color: const Color(0xFF6D6D70),
                    ),
                  ),
                Consumer<PremiumService>(
                  builder: (context, premiumService, child) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ProfileAvatar(
                        tutorialKey: widget.profileAvatarKey, // Tutorial key ekle
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
                      BalanceOverviewCard(
                        tutorialKey: widget.balanceOverviewKey, // Tutorial key - sadece Balance Card için
                      ),
                      // TopGainersSection - Kendi içinde reactive
                      const Column(
                        children: [
                          SizedBox(height: 20),
                          TopGainersSection(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BudgetOverviewCard(
                        tutorialKey: widget.budgetOverviewKey, // Tutorial key ekle
                      ),
                      const SizedBox(height: 20),
                      const SubscriptionsOverviewCard(),
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
                      CardsSection(
                        tutorialKey: widget.cardsSectionKey, // Tutorial key ekle
                      ),
                      const SizedBox(height: 20),
                      RecentTransactionsSection(
                        tutorialKey: widget.recentTransactionsKey, // Tutorial key ekle
                      ),
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
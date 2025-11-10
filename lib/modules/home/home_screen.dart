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
import 'widgets/savings_goals_section.dart';
import 'widgets/cards_section.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/top_gainers_section.dart';
import 'widgets/daily_tasks_card.dart';
import 'widgets/daily_streak_indicator.dart';
import 'widgets/premium_upgrade_banner.dart';
import 'utils/greeting_utils.dart';
import '../../core/providers/profile_provider.dart';
import '../../modules/profile/providers/point_provider.dart';
import '../../shared/widgets/reminder_checker.dart';
import '../../core/services/country_detection_service.dart';
import '../../core/services/point_service.dart';
import '../../shared/models/point_activity_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../modules/advertisement/config/advertisement_config.dart' as config;
import '../../modules/advertisement/services/google_ads_real_banner_service.dart';
import '../../modules/advertisement/models/advertisement_models.dart';
import '../advertisement/providers/advertisement_provider.dart';
import '../advertisement/services/google_ads_interstitial_service.dart';
import '../premium/premium_offer_screen.dart';
import '../../shared/utils/fab_positioning.dart';
import '../transactions/widgets/quick_add_chat_fab.dart';
import '../../core/services/tutorial_service.dart';
import '../../shared/widgets/tutorial_overlay.dart';
import '../../shared/models/tutorial_step_model.dart';
import '../transactions/widgets/transaction_fab.dart';
import '../../core/services/referral_service.dart';
import 'widgets/referral_code_modal.dart';

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
      
      // Initialize Point Provider for daily tasks
      Provider.of<PointProvider>(context, listen: false).initialize();
      
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
  late GoogleAdsRealBannerService _homeBannerAd;
  late GoogleAdsRealBannerService _cardsBannerAd;
  late PremiumService _premiumService;

  @override
  void initState() {
    super.initState();
    
    // Banner reklam servisleri
    _homeBannerAd = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.homeScreenBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Cards Section altı için banner reklam servisi
    _cardsBannerAd = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.homeBanner2.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Premium service listener ekle
      _premiumService = context.read<PremiumService>();
      _premiumService.addListener(_onPremiumChanged);
      
      // Premium değilse banner reklamları yükle
      if (!_premiumService.isPremium) {
        debugPrint('💎 HomeScreen: Loading banner ads (not premium)');
        debugPrint('📱 Banner Ad Unit ID 1: ${config.AdvertisementConfig.homeScreenBanner.bannerAdUnitId}');
        debugPrint('📱 Banner Ad Unit ID 2 (Cards): ${config.AdvertisementConfig.homeBanner2.bannerAdUnitId}');
        _homeBannerAd.loadAd();
        _cardsBannerAd.loadAd();
      } else {
        debugPrint('💎 HomeScreen: Skipping banner ads (premium user)');
      }
      // Data already loaded in splash screen, no need to reload
      // Set context for notification service
      NotificationService().setContext(context);
      
      // Initialize advertisement provider
      final adProvider = context.read<AdvertisementProvider>();
      adProvider.initialize();
      
      // Check and show daily login points modal
      _checkAndShowDailyLoginModal();
      
      // Check and show referral code modal (only once, if user hasn't entered a code)
      _checkAndShowReferralCodeModal();
      
      debugPrint('🏠 HomeScreen.initState() - Data loading completed');
    });
  }
  
  /// Check if user has entered a referral code and show modal if not
  Future<void> _checkAndShowReferralCodeModal() async {
    try {
      // Wait a bit for user document to be ready
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (!mounted) return;
      
      final referralService = ReferralService();
      
      // Check if user has already entered a referral code
      final hasEnteredCode = await referralService.hasEnteredReferralCode();
      
      if (hasEnteredCode) {
        debugPrint('✅ User has already entered a referral code, skipping modal');
        return;
      }
      
      // Check if modal was already shown (using SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final modalShown = prefs.getBool('referral_code_modal_shown') ?? false;
      
      if (modalShown) {
        debugPrint('✅ Referral code modal already shown, skipping');
        return;
      }
      
      // Wait a bit more for UI to be fully loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      
      // Show bottom sheet
      debugPrint('🎁 Showing referral code bottom sheet');
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        isDismissible: false, // User must interact with bottom sheet
        enableDrag: false, // Prevent dragging to dismiss
        builder: (context) => const ReferralCodeModal(),
      );
      
      // Mark modal as shown
      await prefs.setBool('referral_code_modal_shown', true);
      
      if (result == true) {
        debugPrint('✅ Referral code was successfully applied');
      } else {
        debugPrint('⏭️ User skipped referral code entry');
      }
    } catch (e) {
      debugPrint('❌ Error checking/showing referral code modal: $e');
    }
  }
  

  /// Check if daily login points were earned today and show modal
  Future<void> _checkAndShowDailyLoginModal() async {
    try {
      // Check if user is Turkish (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) return;

      // Wait a bit for PointProvider to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      final pointProvider = Provider.of<PointProvider>(context, listen: false);
      if (pointProvider.balance == null) {
        // Try again after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _checkAndShowDailyLoginModal();
        });
        return;
      }

      final balance = pointProvider.balance!;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Check if user logged in today
      if (balance.lastDailyLogin == null) return;
      if (!balance.lastDailyLogin!.isAfter(todayStart.subtract(const Duration(seconds: 1)))) {
        return; // Not today's login
      }

      // Check if modal was already shown today
      final prefs = await SharedPreferences.getInstance();
      final lastShownDate = prefs.getString('daily_login_modal_shown_date');
      final todayString = DateFormat('yyyy-MM-dd').format(today);

      if (lastShownDate == todayString) {
        return; // Already shown today
      }

      // Get today's daily login transaction to get points
      final todayTransactions = pointProvider.transactions.where((transaction) {
        return transaction.activity == PointActivity.dailyLogin &&
            transaction.earnedAt.isAfter(todayStart) &&
            transaction.earnedAt.isBefore(todayStart.add(const Duration(days: 1)));
      }).toList();

      if (todayTransactions.isEmpty) {
        return; // No transaction found
      }

      final pointsEarned = todayTransactions.first.points;
      final hasWeeklyBonus = todayTransactions.first.description?.contains('seri') ?? false;

      // Mark as shown
      await prefs.setString('daily_login_modal_shown_date', todayString);

      // Show modal
      if (mounted) {
        _showDailyLoginPointsModal(pointsEarned, hasWeeklyBonus, balance.weeklyStreakCount);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking daily login modal: $e');
      }
    }
  }

  /// Show daily login points modal
  void _showDailyLoginPointsModal(int points, bool hasWeeklyBonus, int streakCount) {
    final premiumService = PremiumService();
    final isPremium = premiumService.isPremium;
    final isPremiumPlus = premiumService.isPremiumPlus;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFCD34D), // Daha açık, yumuşak turuncu
                const Color(0xFFF59E0B), // Orta ton
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), // Daha hafif gölge
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Günlük Giriş Ödülü!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Points
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '+${NumberFormat('#,###').format(points)}',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'puan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              if (hasWeeklyBonus) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$streakCount günlük seri!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isPremium || isPremiumPlus) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isPremiumPlus ? '2x Çarpan Aktif' : '1.5x Çarpan Aktif',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Harika!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              SnackBar(
                content: const Text('🎓 Tutorial tamamlandı!'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green.shade500,
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
      // Premium aktif - Banner ad'ları dispose et
      _homeBannerAd.dispose();
      _cardsBannerAd.dispose();
      setState(() {}); // UI'ı güncelle
      debugPrint('💎 HomeScreen: Premium active - Banner ads disposed');
    } else {
      // Premium kapatıldı - Banner ad'ları tekrar yükle
      _homeBannerAd.loadAd();
      _cardsBannerAd.loadAd();
      setState(() {}); // UI'ı güncelle
      debugPrint('💎 HomeScreen: Premium deactivated - Reloading banner ads');
    }
  }


  @override
  void dispose() {
    if (mounted) {
      try {
        _premiumService.removeListener(_onPremiumChanged);
      } catch (e) {
        // Premium service might not be initialized yet
        debugPrint('⚠️ HomeScreen: Error removing premium listener: $e');
      }
    }
    _homeBannerAd.dispose();
    _cardsBannerAd.dispose();
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
                      // 0. Premium Upgrade Banner - Premium olmayanlar için
                      const PremiumUpgradeBanner(),
                      
                      // 0.5. Daily Streak Indicator - Streak progress (sadece Türkiye'deki kullanıcılara)
                      const DailyStreakIndicator(),
                      
                      // 1. Balance Overview - En önemli bilgi, en üstte
                      BalanceOverviewCard(
                        tutorialKey: widget.balanceOverviewKey,
                      ),
                      const SizedBox(height: 20),
                      
                      // 1.5. Daily Tasks - Günlük görevler ve puanlar (sadece Türkiye'deki kullanıcılara)
                      const DailyTasksCard(),
                      const SizedBox(height: 20),
                      
                      // 2. Cards Section - Kartlar ve hesaplar (balance'dan hemen sonra mantıklı)
                      CardsSection(
                        tutorialKey: widget.cardsSectionKey,
                      ),
                      const SizedBox(height: 20),
                      
                      // 2.5. Banner Ad - Cards Section altında (Premium olmayanlar için)
                      Consumer<PremiumService>(
                        builder: (context, premiumService, child) {
                          // Premium kontrolü - Premium ise gizle
                          if (premiumService.isPremium) {
                            return const SizedBox.shrink();
                          }
                          
                          // Banner ad kontrolü - Yüklenmemişse gizle
                          if (!_cardsBannerAd.isLoaded || _cardsBannerAd.bannerWidget == null) {
                            return const SizedBox.shrink();
                          }
                          
                          debugPrint('✅ HomeScreen: Rendering cards banner ad widget');
                          
                          // Banner ad widget'ı göster
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: _cardsBannerAd.bannerHeight,
                                  child: _cardsBannerAd.bannerWidget!,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                      
                      // 3. Budget Overview - Bütçe durumu
                      BudgetOverviewCard(
                        tutorialKey: widget.budgetOverviewKey,
                      ),
                      const SizedBox(height: 20),
                      
                      // 4. Subscriptions - Abonelikler (tekrarlayan ödemeler)
                      const SubscriptionsOverviewCard(),
                      const SizedBox(height: 20),
                      
                      // 5. Savings Goals - Tasarruf hedefleri (aboneliklerle benzer kategori)
                      const SavingsGoalsSection(),
                      const SizedBox(height: 28), // Birikimler ile banner arası boşluk artırıldı (20 -> 28)
                      
                      // 6. Banner Ad - Premium olmayanlar için
                      Consumer<PremiumService>(
                        builder: (context, premiumService, child) {
                          // Premium kontrolü - Premium ise gizle
                          if (premiumService.isPremium) {
                            return const SizedBox.shrink();
                          }
                          
                          // Banner ad kontrolü - Yüklenmemişse gizle
                          if (!_homeBannerAd.isLoaded || _homeBannerAd.bannerWidget == null) {
                            return const SizedBox.shrink();
                          }
                          
                          debugPrint('✅ HomeScreen: Rendering banner ad widget');
                          
                          // Banner ad widget'ı göster
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: _homeBannerAd.bannerHeight,
                                  child: _homeBannerAd.bannerWidget!,
                                ),
                              ),
                              const SizedBox(height: 28), // Banner ile son işlemler arası boşluk artırıldı (20 -> 28)
                            ],
                          );
                        },
                      ),
                      
                      // Premium ise banner yok, direkt boşluk ekle
                      Consumer<PremiumService>(
                        builder: (context, premiumService, child) {
                          if (!premiumService.isPremium) {
                            return const SizedBox.shrink(); // Banner varsa boşluk zaten eklendi
                          }
                          // Premium ise banner yok, ekstra boşluk ekle
                          return const SizedBox(height: 8);
                        },
                      ),
                      
                      // 7. Recent Transactions - Son işlemler
                      RecentTransactionsSection(
                        tutorialKey: widget.recentTransactionsKey,
                      ),
                      const SizedBox(height: 20),
                      
                      // 8. Top Gainers - Hisse senedi performansı (en altta, daha az öncelikli)
                      const TopGainersSection(),
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
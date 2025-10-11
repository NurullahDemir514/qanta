import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_client.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../core/providers/profile_provider.dart';
import '../../modules/stocks/providers/stock_provider.dart';
import '../../modules/insights/providers/statistics_provider.dart';
import '../../modules/insights/models/statistics_model.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/qanta_logo.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  String _loadingText = 'Başlatılıyor...';

  @override
  void initState() {
    super.initState();

    // Fade animation for smooth entrance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulse animation for very subtle breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Start all animations simultaneously for smoother experience
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);

    // Wait for initial animations to complete
    await Future.delayed(const Duration(milliseconds: 1200));
    await _checkAuthAndNavigate();
  }

  void _updateLoadingText(String text) {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    try {
      _updateLoadingText('Kimlik doğrulanıyor...');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      // Check if onboarding is completed
      if (!themeProvider.onboardingCompleted) {
        context.go('/onboarding');
        return;
      }

      // Check if user is logged in using SupabaseManager
      final isLoggedIn = FirebaseManager.isLoggedIn;
      final currentUser = FirebaseManager.currentUser;

      debugPrint(
        '🔍 Auth Check: isLoggedIn=$isLoggedIn, user=${currentUser?.email}',
      );

      if (isLoggedIn && currentUser != null) {
        // Kullanıcı giriş yapmışsa verilerini önceden yükle
        _updateLoadingText('Veriler yükleniyor...');
        await _preloadUserData();

        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (e) {
      // On error, go to onboarding
      context.go('/onboarding');
    }
  }

  Future<void> _preloadUserData() async {
    try {
      // 🚀 V2 PROVIDER: Modern unified data loading with cache
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

      _updateLoadingText('Veriler kontrol ediliyor...');

      // StockProvider'ı set et (eğer henüz set edilmemişse)
      if (!providerV2.hasStockProvider) {
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        providerV2.setStockProvider(stockProvider);
      }

      // Cache'li veri yükleme - Hisse verileri için her zaman güncel
      _updateLoadingText('Veriler yükleniyor...');

      // Kritik verileri paralel yükle - Hisse verileri için forceRefresh: true
      await Future.wait([
        providerV2.loadAllData(forceRefresh: true),
        // Hisse pozisyonlarını ayrı yükle
        _loadStockPositionsAsync(providerV2),
        // Profil verilerini yükle
        _loadProfileDataAsync(),
        // Günlük performans verilerini paralel yükle
        _loadDailyPerformanceDataAsync(providerV2),
      ]);

      // Hisse verilerini yükle ve fiyatları güncelle
      _updateLoadingText('Hisse verileri yükleniyor...');
      try {
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        final userId = FirebaseManager.currentUser?.uid;

        if (userId != null) {
          // Önce kullanıcının hisselerini yükle (daha hızlı)
          await stockProvider
              .loadWatchedStocks(userId)
              .timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  debugPrint('⚠️ Hisse yükleme timeout');
                },
              );

          // Eğer hisse varsa fiyatları güncelle - Her zaman güncel veriler
          if (stockProvider.watchedStocks.isNotEmpty) {
            _updateLoadingText('Hisse fiyatları güncelleniyor...');
            // Force refresh ile her zaman güncel fiyatları al
            await stockProvider.updateRealTimePrices(forceRefresh: true).timeout(
              const Duration(seconds: 8), // Daha kısa timeout - 5 saniye API + 3 saniye buffer
              onTimeout: () {
                debugPrint('⚠️ Hisse fiyat güncelleme timeout (8 san) - cache verileri kullanılacak');
              },
            );
          } else {
            debugPrint('ℹ️ Kullanıcının takip ettiği hisse yok');
          }
        }
      } catch (e) {
        // Hisse verileri yüklenemezse devam et
        debugPrint('❌ Hisse verileri yüklenemedi: $e');
      }

      // Real-time listeners'ı kur
      _updateLoadingText('Dinleyiciler kuruluyor...');
      providerV2.setupRealTimeListeners();

      _updateLoadingText('Hazırlanıyor...');
      // Son gecikme kaldırıldı - hemen geç
    } catch (e) {
      // Kritik veri yükleme hatası olsa bile home'a git, orada tekrar denenecek
    }
  }

  /// Hisse pozisyonlarını asenkron yükle
  Future<void> _loadStockPositionsAsync(UnifiedProviderV2 providerV2) async {
    try {
      await providerV2.loadStockPositions();
    } catch (e) {
      // Hisse verileri yüklenemezse sessizce devam et
    }
  }

  /// Profil verilerini asenkron yükle
  Future<void> _loadProfileDataAsync() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.refresh();
      debugPrint('✅ Profil verileri ön yüklendi');
    } catch (e) {
      debugPrint('⚠️ Profil verileri yüklenemedi: $e');
    }
  }

  /// Günlük performans verilerini asenkron yükle
  Future<void> _loadDailyPerformanceDataAsync(UnifiedProviderV2 providerV2) async {
    try {
      // Sadece veriler yüklendiyse istatistik yükle
      if (providerV2.isDataLoaded && providerV2.transactions.isNotEmpty) {
        // Global StatisticsProvider kullan
        final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        await statisticsProvider.loadStatistics(TimePeriod.thisMonth);
      }
    } catch (e) {
      debugPrint('⚠️ Günlük performans verileri yüklenemedi: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAFAFA),
                    Color(0xFFFFFFFF),
                    Color(0xFFF5F5F5),
                  ],
                ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with subtle pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: const QantaLogo(size: 140),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // App name
                      Text(
                        'Qanta',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: isDark
                              ? Colors.white
                              : AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Slogan
                      Text(
                        l10n?.appSlogan ?? 'Finansal Özgürlüğünüz',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : AppConstants.primaryColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Loading indicator at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? Colors.white.withOpacity(0.3)
                              : AppConstants.primaryColor.withOpacity(0.3),
                        ),
                        minHeight: 4,
                      ),
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
}

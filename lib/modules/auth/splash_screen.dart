import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_client.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../modules/stocks/providers/stock_provider.dart';
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
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
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
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        providerV2.setStockProvider(stockProvider);
      }

      // Cache'li veri yükleme (10 dakika cache süresi)
      _updateLoadingText('Veriler yükleniyor...');
      
      // Kritik verileri paralel yükle
      await Future.wait([
        providerV2.loadAllData(forceRefresh: false),
        // Hisse pozisyonlarını ayrı yükle
        _loadStockPositionsAsync(providerV2),
      ]);

      // Hisse fiyatlarını güncelle (net worth için kritik)
      _updateLoadingText('Hisse fiyatları güncelleniyor...');
      try {
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        if (stockProvider.watchedStocks.isNotEmpty) {
          // Timer bağlı güncellemeyi bekle (maksimum 8 saniye)
          await stockProvider.updateRealTimePrices().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              // Timeout durumunda sessizce devam et
            },
          );
        }
      } catch (e) {
        // Hisse verileri yüklenemezse devam et
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
                          color: isDark ? Colors.white : AppConstants.primaryColor,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_client.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
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
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late AnimationController _textController;
  late Animation<double> _textFade;
  String _loadingText = 'Başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
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
      // 🚀 V2 PROVIDER: Modern unified data loading
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

      _updateLoadingText('Veriler kontrol ediliyor...');

      // V2 provider ile veri yükle
      await providerV2.loadAllData();

      _updateLoadingText('Hazırlanıyor...');
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Smooth transition

    } catch (e) {
      // Veri yükleme hatası olsa bile home'a git, orada tekrar denenecek
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFFCF6), // Mint'in çok açık tonu (üstte hafif)
              Color(0xFFF7F8FA), // Açık gri-beyaz (orta)
              Colors.white, // Tam beyaz (ağırlık)
            ],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const QantaLogo(size: 130),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            'Qanta',
                            style: GoogleFonts.inter(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.2,
                              color: AppConstants.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.appSlogan ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4CAF50),
                      ),
                      minHeight: 3,
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

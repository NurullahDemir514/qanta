import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _loadingText = 'Başlatılıyor...';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _startAnimation();
  }

  void _startAnimation() async {
    await _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _checkAuthAndNavigate();
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
        debugPrint('🎯 First time user, navigating to onboarding');
        context.go('/onboarding');
        return;
      }
      
      // Check if user is logged in using SupabaseManager
      final isLoggedIn = SupabaseManager.isLoggedIn;
      final currentUser = SupabaseManager.currentUser;
      
      debugPrint('🔍 Auth Check: isLoggedIn=$isLoggedIn, user=${currentUser?.email}');
    
      if (isLoggedIn && currentUser != null) {
        debugPrint('✅ User is logged in, preloading data...');
        
        // Kullanıcı giriş yapmışsa verilerini önceden yükle
        _updateLoadingText('Veriler yükleniyor...');
        await _preloadUserData();
        
        debugPrint('✅ Data preloaded, navigating to home');
        context.go('/home');
      } else {
        debugPrint('❌ User not logged in, navigating to login');
        context.go('/login');
      }
    } catch (e) {
      debugPrint('❌ Error checking auth: $e');
      // On error, go to onboarding
      context.go('/onboarding');
    }
  }

  Future<void> _preloadUserData() async {
    try {
      // 🚀 V2 PROVIDER: Modern unified data loading
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      _updateLoadingText('Veriler kontrol ediliyor...');
      debugPrint('🚀 Using UnifiedProviderV2 for data preloading...');
      
      // V2 provider ile veri yükle
      await providerV2.loadAllData();
      
      _updateLoadingText('Hazırlanıyor...');
      await Future.delayed(const Duration(milliseconds: 200)); // Smooth transition
      
      debugPrint('✅ V2 data loading completed');
    } catch (e) {
      debugPrint('❌ Error preloading user data: $e');
      // Veri yükleme hatası olsa bile home'a git, orada tekrar denenecek
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF34D399),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Q',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Qanta',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appSlogan,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 
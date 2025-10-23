import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modules/advertisement/providers/advertisement_provider.dart';
import '../services/premium_service.dart';

/// Uygulama yaşam döngüsü yöneticisi
/// App Open Ads için kullanılır
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({super.key, required this.child});
  
  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _isFirstLaunch = true;
  bool _isFirstTimeUser = true; // Kullanıcı ilk kez uygulama açıyor mu?
  static const String _firstOpenKey = 'app_first_open_completed';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // İlk açılışta App Open Ad göster (ama ilk kez açılan kullanıcılara gösterme)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser().then((_) {
        _showAppOpenAdIfNeeded();
      });
    });
  }
  
  /// Kullanıcının ilk kez uygulama açıp açmadığını kontrol et
  Future<void> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasOpenedBefore = prefs.getBool(_firstOpenKey) ?? false;
      
      _isFirstTimeUser = !hasOpenedBefore;
      
      if (_isFirstTimeUser) {
        debugPrint('🆕 First time user - App Open Ad will be skipped');
        // İlk açılışı kaydet
        await prefs.setBool(_firstOpenKey, true);
      } else {
        debugPrint('👤 Returning user - App Open Ad can be shown');
      }
    } catch (e) {
      debugPrint('❌ Error checking first time user: $e');
      _isFirstTimeUser = false; // Hata durumunda eski kullanıcı gibi davran
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && !_isFirstLaunch) {
      debugPrint('📱 App resumed from background');
      _showAppOpenAdIfNeeded();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('📱 App went to background');
    }
  }
  
  Future<void> _showAppOpenAdIfNeeded() async {
    if (!mounted) return;
    
    // İlk kez kullanıcılara reklam gösterme
    if (_isFirstTimeUser) {
      debugPrint('🆕 App Open: First time user - Skipping ad');
      return;
    }
    
    // Premium kullanıcılar için reklam gösterme
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      debugPrint('💎 App Open: Premium user - Skipping ad');
      return;
    }
    
    final adProvider = context.read<AdvertisementProvider>();
    
    // Ad provider initialize olana kadar bekle (max 10 saniye)
    int attempts = 0;
    while (!adProvider.isInitialized && attempts < 20) {
      debugPrint('⏳ App Open: Waiting for ad provider... (${attempts + 1}/20)');
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    
    if (!adProvider.isInitialized) {
      debugPrint('⚠️ App Open: Ad provider not initialized after 10 seconds');
      return;
    }
    
    // İlk açılış bayrağını kaldır
    if (_isFirstLaunch) {
      _isFirstLaunch = false;
      debugPrint('🎉 First launch, showing App Open Ad');
    }
    
    // App Open Ad gösterilebilir mi kontrol et
    final appOpenService = adProvider.adManager.appOpenService;
    if (appOpenService == null) {
      debugPrint('⚠️ App Open Ad service not available');
      return;
    }
    
    if (!appOpenService.isLoaded) {
      debugPrint('⏳ App Open Ad not loaded yet, waiting...');
      // Reklamın yüklenmesini bekle (max 5 saniye)
      int loadAttempts = 0;
      while (!appOpenService.isLoaded && loadAttempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        loadAttempts++;
      }
      
      if (!appOpenService.isLoaded) {
        debugPrint('⚠️ App Open Ad failed to load in time');
        return;
      }
    }
    
    if (!appOpenService.canShowAd()) {
      debugPrint('⏰ App Open Ad cooldown active, skipping');
      return;
    }
    
    debugPrint('🎬 Showing App Open Ad...');
    await adProvider.showAppOpenAd();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


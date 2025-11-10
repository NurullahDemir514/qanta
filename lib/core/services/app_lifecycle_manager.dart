import 'package:flutter/foundation.dart';
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
        // İlk açılışı kaydet
        await prefs.setBool(_firstOpenKey, true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error checking first time user: $e');
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
      _showAppOpenAdIfNeeded();
    }
  }
  
  Future<void> _showAppOpenAdIfNeeded() async {
    if (!mounted) return;
    
    // İlk kez kullanıcılara reklam gösterme (sadece ilk açılışta)
    if (_isFirstTimeUser && _isFirstLaunch) {
      return;
    }
    
    // Premium kullanıcılar için reklam gösterme
    try {
      final premiumService = context.read<PremiumService>();
      if (premiumService.isPremium) {
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ App Open: Error reading PremiumService: $e');
    }
    
    final adProvider = context.read<AdvertisementProvider>();
    
    // Ad provider initialize olana kadar bekle (max 10 saniye)
    int attempts = 0;
    while (!adProvider.isInitialized && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    
    if (!adProvider.isInitialized) {
      return;
    }
    
    // İlk açılış bayrağını kaldır
    if (_isFirstLaunch) {
      _isFirstLaunch = false;
    }
    
    // App Open Ad gösterilebilir mi kontrol et
    final appOpenService = adProvider.adManager.appOpenService;
    if (appOpenService == null) {
      return;
    }
    
    if (!appOpenService.isLoaded) {
      // Reklamın yüklenmesini bekle (max 5 saniye)
      int loadAttempts = 0;
      while (!appOpenService.isLoaded && loadAttempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        loadAttempts++;
      }
      
      if (!appOpenService.isLoaded) {
        // Yüklemeyi tekrar dene
        await appOpenService.loadAd();
        return;
      }
    }
    
    if (!appOpenService.canShowAd()) {
      return;
    }
    
    try {
      await adProvider.showAppOpenAd();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error showing App Open Ad: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


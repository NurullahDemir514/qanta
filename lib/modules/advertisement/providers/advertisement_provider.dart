import 'package:flutter/material.dart';
import '../services/advertisement_manager.dart';
import '../config/advertisement_config.dart';
import '../models/advertisement_models.dart' as models;
import '../../../core/services/premium_service.dart';

/// Reklam provider'ı
/// SOLID - Single Responsibility Principle (SRP)
class AdvertisementProvider extends ChangeNotifier {
  late final AdvertisementManager _adManager;
  final AdvertisementConfig _config;
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // Reklam gösterim sayacı
  int _adShowCount = 0;
  
  AdvertisementProvider({
    AdvertisementConfig? config,
  }) : _config = config ?? AdvertisementConfig.production {
    _adManager = AdvertisementManager(
      bannerAdUnitId: _config.bannerAdUnitId,
      interstitialAdUnitId: _config.interstitialAdUnitId,
      rewardedAdUnitId: _config.rewardedAdUnitId,
      appOpenAdUnitId: _config.appOpenAdUnitId, // App Open Ad eklendi
      isTestMode: _config.isTestMode,
    );
    
    // Otomatik initialize (App Open Ads için kritik!)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }
  
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdvertisementManager get adManager => _adManager;
  
  /// Reklam servislerini başlat
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      debugPrint('⚠️ AdvertisementProvider: Already initialized or loading');
      return;
    }
    
    // Premium kullanıcılar için reklam yükleme
    final isPremium = PremiumService().isPremium;
    if (isPremium) {
      debugPrint('💎 AdvertisementProvider: User is PREMIUM - Skipping ads initialization');
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    debugPrint('🔄 AdvertisementProvider: Starting initialization...');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _adManager.initializeAll();
      _isInitialized = true;
      _isLoading = false;
      debugPrint('✅ AdvertisementProvider: Initialization complete');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AdvertisementProvider: Initialization failed - $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Reklam gösterim sıklığını kontrol et
  bool shouldShowAd() {
    return _adShowCount % _config.showFrequency == 0;
  }
  
  /// Reklam gösterim sayacını artır
  void incrementAdShowCount() {
    _adShowCount++;
    notifyListeners();
  }
  
  /// Banner reklam widget'ını al
  Widget? getBannerWidget({
    models.AdvertisementPosition position = models.AdvertisementPosition.bottom,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    // Premium kullanıcılar için reklam gösterme
    if (PremiumService().isPremium) {
      return null;
    }
    
    if (!_isInitialized || !_adManager.bannerService.isLoaded) {
      return null;
    }
    
    return _adManager.bannerService.bannerWidget;
  }
  
  /// Interstitial reklam göster
  Future<void> showInterstitialAd() async {
    // Premium kullanıcılar için reklam gösterme
    if (PremiumService().isPremium) return;
    
    if (!_isInitialized) return;
    
    try {
      await _adManager.interstitialService.showInterstitialAd();
      incrementAdShowCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Rewarded reklam göster
  Future<void> showRewardedAd() async {
    // Premium kullanıcılar için reklam gösterme
    if (PremiumService().isPremium) return;
    
    if (!_isInitialized) return;
    
    try {
      await _adManager.rewardedService.showRewardedAd();
      incrementAdShowCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// App Open reklam göster
  Future<void> showAppOpenAd() async {
    // Premium kullanıcılar için reklam gösterme
    if (PremiumService().isPremium) return;
    
    if (!_isInitialized) return;
    
    final appOpenService = _adManager.appOpenService;
    if (appOpenService == null) {
      debugPrint('⚠️ App Open Ad service not initialized');
      return;
    }
    
    try {
      await appOpenService.showAppOpenAd();
      incrementAdShowCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// App Open reklam gösterilebilir mi?
  bool canShowAppOpenAd() {
    final appOpenService = _adManager.appOpenService;
    if (appOpenService == null) return false;
    
    return appOpenService.isLoaded && appOpenService.canShowAd();
  }
  
  /// Hata durumunu temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _adManager.disposeAll();
    super.dispose();
  }
}

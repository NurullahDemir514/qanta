import 'package:flutter/material.dart';
import '../services/advertisement_manager.dart';
import '../config/advertisement_config.dart';
import '../models/advertisement_models.dart' as models;

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
  }) : _config = config ?? AdvertisementConfig.development {
    _adManager = AdvertisementManager(
      bannerAdUnitId: _config.bannerAdUnitId,
      interstitialAdUnitId: _config.interstitialAdUnitId,
      rewardedAdUnitId: _config.rewardedAdUnitId,
      isTestMode: _config.isTestMode,
    );
  }
  
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdvertisementManager get adManager => _adManager;
  
  /// Reklam servislerini başlat
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _adManager.initializeAll();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
    if (!_isInitialized || !_adManager.bannerService.isLoaded) {
      return null;
    }
    
    return _adManager.bannerService.bannerWidget;
  }
  
  /// Interstitial reklam göster
  Future<void> showInterstitialAd() async {
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
    if (!_isInitialized) return;
    
    try {
      await _adManager.rewardedService.showRewardedAd();
      incrementAdShowCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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

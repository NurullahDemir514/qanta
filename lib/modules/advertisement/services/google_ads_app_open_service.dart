import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../contracts/advertisement_service_contract.dart';

/// Google Ads App Open (Uygulama Açıkken) reklam servisi
/// SOLID - Single Responsibility Principle (SRP)
class GoogleAdsAppOpenService implements AppOpenAdvertisementServiceContract {
  final String _adUnitId;
  final bool _isTestMode;
  final Duration _cooldownDuration;
  
  AppOpenAd? _appOpenAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastShownTime;
  
  GoogleAdsAppOpenService({
    required String adUnitId,
    bool isTestMode = false,
    Duration cooldownDuration = const Duration(hours: 4),
  })  : _adUnitId = adUnitId,
        _isTestMode = isTestMode,
        _cooldownDuration = cooldownDuration;
  
  @override
  bool get isLoaded => _isLoaded;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get error => _error;
  
  @override
  DateTime? get lastShownTime => _lastShownTime;
  
  @override
  bool canShowAd() {
    if (_lastShownTime == null) return true; // İlk gösterim
    
    final timeSinceLastAd = DateTime.now().difference(_lastShownTime!);
    return timeSinceLastAd >= _cooldownDuration;
  }
  
  @override
  Future<void> loadAd() async {
    if (_isLoading || _isLoaded) {
      return;
    }
    
    _isLoading = true;
    _error = null;
    
    try {
      await AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoaded = true;
            _isLoading = false;
            
            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                // Ad showed
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
                _isLoaded = false;
                // Otomatik olarak yeni reklam yükle (5 saniye sonra)
                Future.delayed(const Duration(seconds: 5), () {
                  loadAd();
                });
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                if (kDebugMode) debugPrint('❌ App Open Ad failed to show: $error');
                ad.dispose();
                _appOpenAd = null;
                _isLoaded = false;
                _error = error.message;
                // Otomatik olarak yeni reklam yükle (10 saniye sonra)
                Future.delayed(const Duration(seconds: 10), () {
                  loadAd();
                });
              },
            );
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
            debugPrint('❌ App Open Ad failed to load: $error');
            }
            _error = error.message;
            _isLoading = false;
            _isLoaded = false;
            
            // "No fill" hatası için retry mekanizması (30 saniye sonra)
            if (error.code == 3) {
              Future.delayed(const Duration(seconds: 30), () {
                if (!_isLoaded && !_isLoading) {
                  loadAd();
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ App Open Ad load exception: $e');
      _error = e.toString();
      _isLoading = false;
      _isLoaded = false;
      
      // Exception durumunda da retry (30 saniye sonra)
      Future.delayed(const Duration(seconds: 30), () {
        if (!_isLoaded && !_isLoading) {
          loadAd();
        }
      });
    }
  }
  
  @override
  Future<void> showAd() async {
    await showAppOpenAd();
  }
  
  @override
  Future<void> showAppOpenAd() async {
    if (!_isLoaded || _appOpenAd == null) {
      return;
    }
    
    if (!canShowAd()) {
      return;
    }
    
    try {
      await _appOpenAd!.show();
      _lastShownTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to show App Open Ad: $e');
      _error = e.toString();
    }
  }
  
  @override
  Future<void> hideAd() async {
    // App Open Ads cannot be hidden manually
  }
  
  @override
  Future<void> dispose() async {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoaded = false;
    _isLoading = false;
    _error = null;
  }
}


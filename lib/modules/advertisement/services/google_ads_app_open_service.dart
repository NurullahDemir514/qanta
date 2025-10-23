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
    final canShow = timeSinceLastAd >= _cooldownDuration;
    
    debugPrint('🕐 App Open Ad Cooldown Check:');
    debugPrint('   Last shown: ${_lastShownTime}');
    debugPrint('   Time since: ${timeSinceLastAd.inMinutes} minutes');
    debugPrint('   Can show: $canShow');
    
    return canShow;
  }
  
  @override
  Future<void> loadAd() async {
    if (_isLoading || _isLoaded) {
      debugPrint('⚠️ App Open Ad: Already loading or loaded');
      return;
    }
    
    _isLoading = true;
    _error = null;
    
    debugPrint('📱 Loading App Open Ad...');
    debugPrint('   Ad Unit ID: $_adUnitId');
    debugPrint('   Test Mode: $_isTestMode');
    
    try {
      await AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ App Open Ad loaded successfully');
            _appOpenAd = ad;
            _isLoaded = true;
            _isLoading = false;
            
            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('🎬 App Open Ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('👋 App Open Ad dismissed');
                ad.dispose();
                _appOpenAd = null;
                _isLoaded = false;
                // Otomatik olarak yeni reklam yükle
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ App Open Ad failed to show: $error');
                ad.dispose();
                _appOpenAd = null;
                _isLoaded = false;
                _error = error.message;
                // Otomatik olarak yeni reklam yükle
                loadAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ App Open Ad failed to load: $error');
            _error = error.message;
            _isLoading = false;
            _isLoaded = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ App Open Ad load exception: $e');
      _error = e.toString();
      _isLoading = false;
      _isLoaded = false;
    }
  }
  
  @override
  Future<void> showAd() async {
    await showAppOpenAd();
  }
  
  @override
  Future<void> showAppOpenAd() async {
    if (!_isLoaded || _appOpenAd == null) {
      debugPrint('⚠️ App Open Ad not loaded yet');
      return;
    }
    
    if (!canShowAd()) {
      debugPrint('⏰ App Open Ad cooldown active, skipping');
      return;
    }
    
    debugPrint('🎬 Showing App Open Ad...');
    
    try {
      await _appOpenAd!.show();
      _lastShownTime = DateTime.now();
      debugPrint('✅ App Open Ad shown successfully at $_lastShownTime');
    } catch (e) {
      debugPrint('❌ Failed to show App Open Ad: $e');
      _error = e.toString();
    }
  }
  
  @override
  Future<void> hideAd() async {
    // App Open Ads cannot be hidden manually
    debugPrint('⚠️ App Open Ads cannot be hidden manually');
  }
  
  @override
  Future<void> dispose() async {
    debugPrint('🗑️ Disposing App Open Ad service...');
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoaded = false;
    _isLoading = false;
    _error = null;
  }
}


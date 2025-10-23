import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../contracts/advertisement_service_contract.dart';

/// Google Ads Interstitial (Geçiş) reklam servisi
/// SOLID - Single Responsibility Principle (SRP)
class GoogleAdsInterstitialService implements InterstitialAdvertisementServiceContract {
  final String _adUnitId;
  final bool _isTestMode;
  
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;
  
  GoogleAdsInterstitialService({
    required String adUnitId,
    bool isTestMode = false,
  })  : _adUnitId = adUnitId,
        _isTestMode = isTestMode;
  
  @override
  bool get isLoaded => _isLoaded;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get error => _error;
  
  @override
  Future<void> loadAd() async {
    if (_isLoading || _isLoaded) {
      debugPrint('⚠️ Interstitial ad: Already loading or loaded. isLoading=$_isLoading, isLoaded=$_isLoaded');
      return;
    }
    
    _isLoading = true;
    _error = null;
    
    debugPrint('🔄 Interstitial ad: Starting to load...');
    debugPrint('📱 Ad Unit ID: $_adUnitId');
    debugPrint('🧪 Test Mode: $_isTestMode');
    
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ Interstitial ad loaded successfully: $_adUnitId');
            _interstitialAd = ad;
            _isLoaded = true;
            _isLoading = false;
            
            // Set full screen content callback
            _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('📱 Interstitial ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('❌ Interstitial ad dismissed');
                ad.dispose();
                _isLoaded = false;
                _interstitialAd = null;
                // Reload ad for next time
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Interstitial ad failed to show: $error');
                _error = error.message;
                ad.dispose();
                _isLoaded = false;
                _interstitialAd = null;
                // Reload ad
                loadAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Interstitial ad failed to load: $error');
            _error = error.message;
            _isLoading = false;
            _isLoaded = false;
            
            // Retry after delay
            Future.delayed(const Duration(seconds: 5), () {
              if (!_isLoaded && !_isLoading) {
                loadAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Interstitial ad exception: $e');
      _error = e.toString();
      _isLoading = false;
      _isLoaded = false;
    }
  }
  
  @override
  Future<void> showAd() async {
    await showInterstitialAd();
  }
  
  @override
  Future<void> hideAd() async {
    // Interstitial ads cannot be hidden, they are full screen
    debugPrint('⚠️ Interstitial ads cannot be hidden');
  }
  
  @override
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad is not loaded yet');
      _error = 'Ad not loaded';
      
      // Try to load if not already loading
      if (!_isLoading) {
        await loadAd();
      }
      return;
    }
    
    try {
      await _interstitialAd?.show();
    } catch (e) {
      debugPrint('❌ Failed to show interstitial ad: $e');
      _error = e.toString();
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isLoaded = false;
      
      // Reload ad
      loadAd();
    }
  }
  
  @override
  Future<void> dispose() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
    _isLoading = false;
  }
}


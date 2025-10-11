import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../contracts/advertisement_service_contract.dart';
import '../models/advertisement_models.dart';

/// Gerçek Google Ads Banner servisi implementasyonu
/// SOLID - Single Responsibility Principle (SRP)
class GoogleAdsRealBannerService implements BannerAdvertisementServiceContract {
  final String adUnitId;
  final AdvertisementSize size;
  final bool isTestMode;
  
  BannerAd? _bannerAd;
  Widget? _bannerWidget;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  GoogleAdsRealBannerService({
    required this.adUnitId,
    required this.size,
    this.isTestMode = false,
  });
  
  @override
  bool get isLoaded => _isLoaded;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get error => _error;
  
  @override
  Widget? get bannerWidget => _bannerWidget;
  
  @override
  double get bannerHeight => size.height;
  
  @override
  Future<void> loadAd() async {
    if (_isLoading || _isLoaded) return;
    
    _isLoading = true;
    _error = null;
    
    debugPrint('🔄 GoogleAdsRealBannerService: Reklam yükleniyor...');
    debugPrint('📱 Ad Unit ID: $adUnitId');
    debugPrint('📏 Ad Size: ${_getAdSize()}');
    debugPrint('🧪 Test Mode: $isTestMode');
    
    try {
      // Banner ad oluştur
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: _getAdSize(),
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            debugPrint('✅ Banner reklam başarıyla yüklendi!');
            _isLoaded = true;
            _isLoading = false;
            _retryCount = 0; // Başarılı yüklemede retry sayacını sıfırla
            // Her seferinde yeni AdWidget oluştur
            _bannerWidget = AdWidget(ad: ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Banner reklam yüklenemedi: ${error.message}');
            debugPrint('🔍 Error Code: ${error.code}');
            debugPrint('🔍 Error Domain: ${error.domain}');
            _error = error.message;
            _isLoading = false;
            ad.dispose();
            
            // Error Code 3 (No fill) için retry (max 3 kez)
            if (error.code == 3 && _retryCount < _maxRetries) {
              _retryCount++;
              debugPrint('🔄 No fill hatası - 10 saniye sonra tekrar denenecek... (Deneme: $_retryCount/$_maxRetries)');
              Future.delayed(const Duration(seconds: 10), () {
                if (!_isLoaded) {
                  debugPrint('🔄 Retry: Reklam tekrar yükleniyor... (Deneme: $_retryCount/$_maxRetries)');
                  loadAd();
                }
              });
            } else if (error.code == 3) {
              debugPrint('❌ Maksimum retry sayısına ulaşıldı. Reklam yüklenemedi.');
            }
          },
          onAdOpened: (ad) {
            debugPrint('📱 Banner reklam açıldı');
          },
          onAdClosed: (ad) {
            debugPrint('📱 Banner reklam kapandı');
          },
        ),
      );
      
      // Reklamı yükle
      await _bannerAd!.load();
      
    } catch (e) {
      debugPrint('❌ Banner reklam yükleme hatası: $e');
      _error = e.toString();
      _isLoading = false;
    }
  }
  
  @override
  Future<void> showAd() async {
    if (!_isLoaded) {
      await loadAd();
    }
  }
  
  @override
  Future<void> hideAd() async {
    // Banner reklamları genellikle gizlenmez, sadece widget'tan kaldırılır
  }
  
  @override
  Future<void> dispose() async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerWidget = null;
    _isLoaded = false;
    _isLoading = false;
    _error = null;
  }
  
  /// Ad boyutunu dönüştür
  AdSize _getAdSize() {
    switch (size) {
      case AdvertisementSize.banner320x50:
        return AdSize.banner;
      case AdvertisementSize.banner320x100:
        return AdSize.largeBanner;
      case AdvertisementSize.banner300x250:
        return AdSize.mediumRectangle;
      case AdvertisementSize.banner728x90:
        return AdSize.leaderboard;
      default:
        return AdSize.banner;
    }
  }
}

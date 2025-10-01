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
    
    try {
      // Banner ad oluştur
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: _getAdSize(),
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _isLoaded = true;
            _isLoading = false;
            // Her seferinde yeni AdWidget oluştur
            _bannerWidget = AdWidget(ad: ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            _error = error.message;
            _isLoading = false;
            ad.dispose();
          },
          onAdOpened: (ad) {
            // Ad opened
          },
          onAdClosed: (ad) {
            // Ad closed
          },
        ),
      );
      
      // Reklamı yükle
      await _bannerAd!.load();
      
    } catch (e) {
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

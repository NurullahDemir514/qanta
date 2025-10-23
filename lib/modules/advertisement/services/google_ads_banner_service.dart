import 'package:flutter/material.dart';
import '../contracts/advertisement_service_contract.dart';
import '../models/advertisement_models.dart';

/// Google Ads Banner servisi implementasyonu
/// SOLID - Single Responsibility Principle (SRP)
class GoogleAdsBannerService implements BannerAdvertisementServiceContract {
  final String adUnitId;
  final AdvertisementSize size;
  final bool isTestMode;
  
  Widget? _bannerWidget;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _error;
  
  GoogleAdsBannerService({
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
      // TODO: Google Mobile Ads SDK entegrasyonu
      // Şimdilik mock widget oluşturuyoruz
      await Future.delayed(const Duration(seconds: 1)); // Simüle edilmiş yükleme
      
      _bannerWidget = _buildMockBanner();
      _isLoaded = true;
      _isLoading = false;
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
    _bannerWidget = null;
    _isLoaded = false;
    _isLoading = false;
    _error = null;
  }
  
  /// Mock banner widget oluştur (tamamen boş - sadece gerçek reklamlar gösterilecek)
  Widget _buildMockBanner() {
    return SizedBox(
      width: size.width,
      height: size.height,
      // Tamamen boş - sadece gerçek AdMob reklamları gösterilecek
    );
  }
}


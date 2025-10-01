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
  
  /// Mock banner widget oluştur
  Widget _buildMockBanner() {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ads_click,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              isTestMode ? 'Test Ad' : 'Advertisement',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isTestMode) ...[
              const SizedBox(height: 1),
              Text(
                adUnitId.length > 20 ? '${adUnitId.substring(0, 20)}...' : adUnitId,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

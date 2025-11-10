import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Basit Native Ad servis/widget birleşimi
class NativeAdService with ChangeNotifier {
  final String adUnitId;
  final String factoryId;

  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _disposed = false;

  NativeAdService({required this.adUnitId, this.factoryId = 'listTile'});

  bool get isLoaded {
    // Native ad yüklenmiş ve geçerli olmalı
    if (!_isLoaded || _nativeAd == null) {
      return false;
    }
    return true;
  }
  
  Widget? get adWidget {
    if (_nativeAd == null || !_isLoaded) {
      debugPrint('⚠️ NativeAdService: adWidget is null - _nativeAd: ${_nativeAd != null}, _isLoaded: $_isLoaded');
      return null;
    }
    try {
      final widget = AdWidget(ad: _nativeAd!);
      debugPrint('✅ NativeAdService: adWidget created successfully');
      return widget;
    } catch (e, stackTrace) {
      debugPrint('❌ NativeAdService: Error creating AdWidget: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Hata durumunda null döndür, böylece widget gizlenecek
      return null;
    }
  }
  
  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ NativeAdService: Error notifying listeners: $e');
      }
    }
  }

  Future<void> load() async {
    if (_disposed) {
      debugPrint('⚠️ NativeAdService: Cannot load, service is disposed');
      return;
    }
    
    try {
      debugPrint('🔄 NativeAdService: Starting to load native ad...');
      debugPrint('📱 Ad Unit ID: $adUnitId');
      debugPrint('🏭 Factory ID: $factoryId');
      
      _nativeAd?.dispose();
      _isLoaded = false;
      _safeNotifyListeners();

      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: factoryId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ NativeAd.onAdLoaded callback triggered');
            if (!_disposed && _nativeAd != null) {
              // Native ad'ın headline kontrolü - headline yoksa geçersiz sayılır
              // Ancak AdWidget oluşturmayı denemeyelim, sadece ad'ın kendisini kontrol edelim
              _isLoaded = true;
              debugPrint('✅ NativeAd loaded successfully: $adUnitId');
              debugPrint('✅ NativeAd headline: ${ad.responseInfo?.responseId ?? "N/A"}');
              _safeNotifyListeners();
            } else {
              debugPrint('⚠️ NativeAd loaded but service is disposed or ad is null');
              _isLoaded = false;
              _safeNotifyListeners();
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ NativeAd failed to load: ${error.message}');
            debugPrint('❌ Error Code: ${error.code}');
            debugPrint('❌ Error Domain: ${error.domain}');
            if (!_disposed) {
              ad.dispose();
              _nativeAd = null;
              _isLoaded = false;
              _safeNotifyListeners();
              debugPrint('⚠️ NativeAdService: Marked as not loaded due to error');
            }
          },
        ),
      );

      debugPrint('🔄 NativeAdService: Calling _nativeAd.load()...');
      await _nativeAd!.load();
      debugPrint('🔄 NativeAdService: load() call completed');
    } catch (e, stackTrace) {
      debugPrint('❌ NativeAdService.load() exception: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (!_disposed) {
        _nativeAd?.dispose();
        _nativeAd = null;
        _isLoaded = false;
        _safeNotifyListeners();
      }
    }
  }

  void disposeAd() {
    _disposed = true;
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
  }
  
  @override
  void dispose() {
    disposeAd();
    super.dispose();
  }
}


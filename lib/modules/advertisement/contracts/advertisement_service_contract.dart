import 'package:flutter/material.dart';

/// Reklam servisi için abstract contract
/// SOLID - Interface Segregation Principle (ISP)
abstract class AdvertisementServiceContract {
  /// Reklam yüklenip yüklenmediğini kontrol et
  bool get isLoaded;
  
  /// Reklam yükleniyor mu?
  bool get isLoading;
  
  /// Reklam yükleme hatası var mı?
  String? get error;
  
  /// Reklam yükle
  Future<void> loadAd();
  
  /// Reklamı göster
  Future<void> showAd();
  
  /// Reklamı gizle
  Future<void> hideAd();
  
  /// Reklamı temizle
  Future<void> dispose();
}

/// Banner reklam servisi için contract
abstract class BannerAdvertisementServiceContract extends AdvertisementServiceContract {
  /// Banner reklam widget'ını döndür
  Widget? get bannerWidget;
  
  /// Banner reklam yüksekliği
  double get bannerHeight;
}

/// Interstitial reklam servisi için contract
abstract class InterstitialAdvertisementServiceContract extends AdvertisementServiceContract {
  /// Interstitial reklam göster
  Future<void> showInterstitialAd();
}

/// Rewarded reklam servisi için contract
abstract class RewardedAdvertisementServiceContract extends AdvertisementServiceContract {
  /// Rewarded reklam göster
  Future<void> showRewardedAd();
  
  /// Ödül callback'i
  void Function()? get onRewardEarned;
  set onRewardEarned(void Function()? callback);
}

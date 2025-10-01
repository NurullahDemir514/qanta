import 'advertisement_service_contract.dart';

/// Reklam yöneticisi için abstract contract
/// SOLID - Single Responsibility Principle (SRP)
abstract class AdvertisementManagerContract {
  /// Banner reklam servisi
  BannerAdvertisementServiceContract get bannerService;
  
  /// Interstitial reklam servisi
  InterstitialAdvertisementServiceContract get interstitialService;
  
  /// Rewarded reklam servisi
  RewardedAdvertisementServiceContract get rewardedService;
  
  /// Tüm reklam servislerini başlat
  Future<void> initializeAll();
  
  /// Reklam servislerini temizle
  Future<void> disposeAll();
  
  /// Reklam servisini başlat
  Future<void> initializeService(AdvertisementServiceContract service);
  
  /// Reklam servisini temizle
  Future<void> disposeService(AdvertisementServiceContract service);
}

/// Reklam konfigürasyonu için contract
abstract class AdvertisementConfigContract {
  /// Google Ads App ID
  String get googleAdsAppId;
  
  /// Banner Ad Unit ID
  String get bannerAdUnitId;
  
  /// Interstitial Ad Unit ID
  String get interstitialAdUnitId;
  
  /// Rewarded Ad Unit ID
  String get rewardedAdUnitId;
  
  /// Test modunda mı?
  bool get isTestMode;
  
  /// Reklam gösterim sıklığı (kaç işlemde bir)
  int get showFrequency;
}

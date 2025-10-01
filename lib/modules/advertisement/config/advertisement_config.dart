import '../contracts/advertisement_manager_contract.dart';

/// Reklam konfigürasyonu
/// SOLID - Single Responsibility Principle (SRP)
class AdvertisementConfig implements AdvertisementConfigContract {
  @override
  final String googleAdsAppId;
  
  @override
  final String bannerAdUnitId;
  
  @override
  final String interstitialAdUnitId;
  
  @override
  final String rewardedAdUnitId;
  
  @override
  final bool isTestMode;
  
  @override
  final int showFrequency;
  
  const AdvertisementConfig({
    required this.googleAdsAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.rewardedAdUnitId,
    this.isTestMode = false,
    this.showFrequency = 1,
  });
  
  /// Test konfigürasyonu
  static const AdvertisementConfig test = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    isTestMode: true,
    showFrequency: 1,
  );
  
  /// Production konfigürasyonu
  static const AdvertisementConfig production = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-1234567890123456~1234567890', // Gerçek App ID
    bannerAdUnitId: 'ca-app-pub-1234567890123456/1234567890', // Gerçek Banner Ad Unit ID
    interstitialAdUnitId: 'ca-app-pub-1234567890123456/0987654321', // Gerçek Interstitial Ad Unit ID
    rewardedAdUnitId: 'ca-app-pub-1234567890123456/1122334455', // Gerçek Rewarded Ad Unit ID
    isTestMode: false,
    showFrequency: 3, // Her 3 işlemde bir göster
  );
  
  /// Geliştirme ortamı için konfigürasyon
  static AdvertisementConfig get development {
    return const AdvertisementConfig(
      googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
      bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
      interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
      rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
      isTestMode: true,
      showFrequency: 1,
    );
  }
}

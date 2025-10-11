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

  /// Test Banner 1 konfigürasyonu
  static const AdvertisementConfig testBanner1 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner 1
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    isTestMode: true,
    showFrequency: 1,
  );

  /// Test Banner 2 konfigürasyonu
  static const AdvertisementConfig testBanner2 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner 2 (aynı ID)
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    isTestMode: true,
    showFrequency: 1,
  );

  /// Test Banner 3 konfigürasyonu (farklı test ID)
  static const AdvertisementConfig testBanner3 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner 3 (aynı ID)
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    isTestMode: true,
    showFrequency: 1,
  );

  /// Test Banner 4 konfigürasyonu (farklı test ID)
  static const AdvertisementConfig testBanner4 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner 4 (aynı ID)
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    isTestMode: true,
    showFrequency: 1,
  );

  /// Production konfigürasyonu
  static const AdvertisementConfig production = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Home Banner 1
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    isTestMode: false,
    showFrequency: 3, // Her 3 işlemde bir göster
  );

  /// Home Banner 2 konfigürasyonu
  static const AdvertisementConfig homeBanner2 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Home Banner 2 (aynı ID)
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
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

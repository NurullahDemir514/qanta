import '../contracts/advertisement_manager_contract.dart';
import '../contracts/advertisement_service_contract.dart';
import 'google_ads_banner_service.dart';
import 'google_ads_real_banner_service.dart';
import '../models/advertisement_models.dart';

/// Reklam yöneticisi implementasyonu
/// SOLID - Single Responsibility Principle (SRP)
class AdvertisementManager implements AdvertisementManagerContract {
  late final BannerAdvertisementServiceContract _bannerService;
  late final InterstitialAdvertisementServiceContract _interstitialService;
  late final RewardedAdvertisementServiceContract _rewardedService;
  
  final Map<String, AdvertisementServiceContract> _services = {};
  
  AdvertisementManager({
    required String bannerAdUnitId,
    required String interstitialAdUnitId,
    required String rewardedAdUnitId,
    bool isTestMode = false,
    bool useRealAds = true,
  }) {
    if (useRealAds) {
      _bannerService = GoogleAdsRealBannerService(
        adUnitId: bannerAdUnitId,
        size: AdvertisementSize.mobileBanner,
        isTestMode: isTestMode,
      );
    } else {
      _bannerService = GoogleAdsBannerService(
        adUnitId: bannerAdUnitId,
        size: AdvertisementSize.mobileBanner,
        isTestMode: isTestMode,
      );
    }
    
    // TODO: Diğer servisleri implement et
    // _interstitialService = GoogleAdsInterstitialService(...);
    // _rewardedService = GoogleAdsRewardedService(...);
    
    _services['banner'] = _bannerService;
    // _services['interstitial'] = _interstitialService;
    // _services['rewarded'] = _rewardedService;
  }
  
  @override
  BannerAdvertisementServiceContract get bannerService => _bannerService;
  
  @override
  InterstitialAdvertisementServiceContract get interstitialService => _interstitialService;
  
  @override
  RewardedAdvertisementServiceContract get rewardedService => _rewardedService;
  
  @override
  Future<void> initializeAll() async {
    final futures = _services.values.map((service) => service.loadAd());
    await Future.wait(futures);
  }
  
  @override
  Future<void> disposeAll() async {
    final futures = _services.values.map((service) => service.dispose());
    await Future.wait(futures);
  }
  
  @override
  Future<void> initializeService(AdvertisementServiceContract service) async {
    await service.loadAd();
  }
  
  @override
  Future<void> disposeService(AdvertisementServiceContract service) async {
    await service.dispose();
  }
  
  /// Belirli bir servisi al
  T? getService<T extends AdvertisementServiceContract>(String key) {
    return _services[key] as T?;
  }
  
  /// Servis durumunu kontrol et
  bool isServiceLoaded(String key) {
    final service = _services[key];
    return service?.isLoaded ?? false;
  }
  
  /// Servis hatasını al
  String? getServiceError(String key) {
    final service = _services[key];
    return service?.error;
  }
}

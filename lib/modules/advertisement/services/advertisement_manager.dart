import 'package:flutter/foundation.dart';
import '../contracts/advertisement_manager_contract.dart';
import '../contracts/advertisement_service_contract.dart';
import 'google_ads_banner_service.dart';
import 'google_ads_real_banner_service.dart';
import 'google_ads_interstitial_service.dart';
import 'google_ads_app_open_service.dart';
import '../models/advertisement_models.dart';

/// Reklam yöneticisi implementasyonu
/// SOLID - Single Responsibility Principle (SRP)
class AdvertisementManager implements AdvertisementManagerContract {
  late final BannerAdvertisementServiceContract _bannerService;
  late final InterstitialAdvertisementServiceContract _interstitialService;
  late final RewardedAdvertisementServiceContract _rewardedService;
  late final AppOpenAdvertisementServiceContract? _appOpenService;
  
  final Map<String, AdvertisementServiceContract> _services = {};
  
  AdvertisementManager({
    required String bannerAdUnitId,
    required String interstitialAdUnitId,
    required String rewardedAdUnitId,
    String? appOpenAdUnitId,
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
    
    // Interstitial (Geçiş) reklam servisi
    _interstitialService = GoogleAdsInterstitialService(
      adUnitId: interstitialAdUnitId,
      isTestMode: isTestMode,
    );
    
    // Rewarded (Ödüllü) reklam servisi
    // NOTE: Rewarded ads are handled by RewardedAdService in core/services
    // This is kept for contract compatibility but not actively used
    _rewardedService = _createStubRewardedService(rewardedAdUnitId, isTestMode);
    
    // App Open (Uygulama Açıkken) reklam servisi (optional)
    if (appOpenAdUnitId != null) {
      _appOpenService = GoogleAdsAppOpenService(
        adUnitId: appOpenAdUnitId,
        isTestMode: isTestMode,
        cooldownDuration: const Duration(minutes: 30), // 30 dakikalık cooldown
      );
      _services['appOpen'] = _appOpenService!;
    } else {
      _appOpenService = null;
    }
    
    _services['banner'] = _bannerService;
    _services['interstitial'] = _interstitialService;
    _services['rewarded'] = _rewardedService;
  }
  
  @override
  BannerAdvertisementServiceContract get bannerService => _bannerService;
  
  @override
  InterstitialAdvertisementServiceContract get interstitialService => _interstitialService;
  
  @override
  RewardedAdvertisementServiceContract get rewardedService => _rewardedService;
  
  /// App Open reklam servisi (nullable)
  AppOpenAdvertisementServiceContract? get appOpenService => _appOpenService;
  
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
  
  /// Stub rewarded service oluştur (contract compatibility için)
  /// NOTE: Gerçek rewarded ads RewardedAdService (core/services) tarafından yönetiliyor
  RewardedAdvertisementServiceContract _createStubRewardedService(
    String adUnitId,
    bool isTestMode,
  ) {
    return _StubRewardedService(adUnitId: adUnitId, isTestMode: isTestMode);
  }
}

/// Stub Rewarded Service - Contract compatibility için
/// Gerçek rewarded ads RewardedAdService (core/services) tarafından yönetiliyor
class _StubRewardedService implements RewardedAdvertisementServiceContract {
  final String adUnitId;
  final bool isTestMode;
  
  void Function()? _onRewardEarned;
  
  _StubRewardedService({
    required this.adUnitId,
    required this.isTestMode,
  });
  
  @override
  bool get isLoaded => false;
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  void Function()? get onRewardEarned => _onRewardEarned;
  
  @override
  set onRewardEarned(void Function()? callback) {
    _onRewardEarned = callback;
  }
  
  @override
  Future<void> loadAd() async {
    // Stub implementation
  }
  
  @override
  Future<void> showAd() async {
    // Stub implementation
  }
  
  @override
  Future<void> hideAd() async {
    // Stub implementation
  }
  
  @override
  Future<void> showRewardedAd() async {
    // Stub implementation
  }
  
  @override
  Future<void> dispose() async {
    // Nothing to dispose
  }
}

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
  final String? nativeAdUnitId;

  @override
  final String? appOpenAdUnitId;

  @override
  final bool isTestMode;

  @override
  final int showFrequency;

  const AdvertisementConfig({
    required this.googleAdsAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.rewardedAdUnitId,
    this.nativeAdUnitId,
    this.appOpenAdUnitId,
    this.isTestMode = false,
    this.showFrequency = 1,
  });

  /// Test konfigürasyonu
  static const AdvertisementConfig test = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-3940256099942544~3347511713',
    bannerAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
    interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712',
    rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
    appOpenAdUnitId: 'ca-app-pub-3940256099942544/9257395921', // Test App Open Ad
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
        'ca-app-pub-8222217303967306/8275910028', // Home Banner 1 - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/5895772234', // Insights Interstitial (Geçiş)
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    nativeAdUnitId: 'ca-app-pub-8222217303967306/2917760265', // Home Native (Yerel gelişmiş)
    appOpenAdUnitId: 'ca-app-pub-8222217303967306/5441863125', // App Open Ad (Uygulama açıkken) - YENİ
    isTestMode: false,
    showFrequency: 3, // Her 3 işlemde bir göster
  );

  /// Home Banner 2 konfigürasyonu
  static const AdvertisementConfig homeBanner2 = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/6446384303', // Home Banner 2 (ikinci gerçek ID)
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/6446384303', // Şimdilik banner ID kullan
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/6446384303', // Şimdilik banner ID kullan
    nativeAdUnitId: 'ca-app-pub-8222217303967306/2917760265',
    isTestMode: false,
    showFrequency: 3, // Her 3 işlemde bir göster
  );

  /// Expense Form Step 4 Banner konfigürasyonu
  static const AdvertisementConfig expenseFormBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1103057660', // Expense Form Banner (Step 4)
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/5895772234', // Insights Interstitial
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    nativeAdUnitId: 'ca-app-pub-8222217303967306/2917760265',
    isTestMode: false,
    showFrequency: 3,
  );

  /// Income & Transfer Form Banner konfigürasyonu
  static const AdvertisementConfig incomeTransferFormBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/9664073960', // Income/Transfer Form Banner (Yeni - Güncel)
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/5895772234', // Insights Interstitial
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    nativeAdUnitId: 'ca-app-pub-8222217303967306/2917760265',
    isTestMode: false,
    showFrequency: 3,
  );

  /// Transactions Interstitial konfigürasyonu
  static const AdvertisementConfig transactionsInterstitial = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011', // Transactions Interstitial
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    isTestMode: false,
    showFrequency: 1, // Her transactions açılışta göster
  );

  /// Stocks (Yatırım) Interstitial konfigürasyonu
  static const AdvertisementConfig stocksInterstitial = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011', // Stocks için aynı ID (tek geçiş reklamı)
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702', // Şimdilik banner ID kullan
    isTestMode: false,
    showFrequency: 1, // Her stocks açılışta göster
  );

  /// Cash Tab Banner konfigürasyonu
  static const AdvertisementConfig cashTabBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/6525261960', // Cash Tab Banner
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Debit Cards Tab Banner konfigürasyonu
  static const AdvertisementConfig debitCardsTabBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1031911066', // Debit Cards Tab Banner
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Credit Cards Tab Banner konfigürasyonu
  static const AdvertisementConfig creditCardsTabBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/5434066792', // Credit Cards Tab Banner
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Transaction Form Step 1 Banner konfigürasyonu (Calculator altı)
  static const AdvertisementConfig transactionFormStep1Banner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8601664927', // Transaction Form Step 1 Banner
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Savings Tab Banner konfigürasyonu
  static const AdvertisementConfig savingsTabBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Savings Tab Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Analytics/Statistics Banner konfigürasyonu
  static const AdvertisementConfig analyticsBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Analytics Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Calendar Banner konfigürasyonu
  static const AdvertisementConfig calendarBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Calendar Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Transactions List Banner konfigürasyonu
  static const AdvertisementConfig transactionsListBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Transactions List Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Stock Transaction Form Banner konfigürasyonu
  static const AdvertisementConfig stockTransactionFormBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Stock Form Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Budget Management Banner konfigürasyonu
  static const AdvertisementConfig budgetManagementBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Budget Management Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Savings Goal Detail Banner konfigürasyonu
  static const AdvertisementConfig savingsGoalDetailBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Savings Detail Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Add Card Forms Banner konfigürasyonu (Debit/Credit/Savings)
  static const AdvertisementConfig addCardFormBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Add Card Form Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Settings Screen Banner konfigürasyonu
  static const AdvertisementConfig settingsBanner = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/1219547082', // Settings Banner - YENİ
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011',
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 1,
  );

  /// Success Interstitial (Her 3 başarılı transaction'da bir gösterilir)
  static const AdvertisementConfig successInterstitial = AdvertisementConfig(
    googleAdsAppId: 'ca-app-pub-8222217303967306~5324874321', // Gerçek App ID
    bannerAdUnitId:
        'ca-app-pub-8222217303967306/8275910028',
    interstitialAdUnitId:
        'ca-app-pub-8222217303967306/4529654011', // Success Interstitial - Mevcut
    rewardedAdUnitId:
        'ca-app-pub-8222217303967306/8010623702',
    isTestMode: false,
    showFrequency: 3, // Her 3 transaction'da bir
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

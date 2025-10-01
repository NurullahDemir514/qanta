/// Reklam türleri enum'u
enum AdvertisementType {
  banner,
  interstitial,
  rewarded,
}

/// Reklam durumu enum'u
enum AdvertisementStatus {
  notLoaded,
  loading,
  loaded,
  showing,
  hidden,
  error,
  disposed,
}

/// Reklam pozisyonu enum'u
enum AdvertisementPosition {
  top,
  bottom,
  middle,
  betweenContent,
}

/// Reklam boyutu modeli
class AdvertisementSize {
  final double width;
  final double height;
  
  const AdvertisementSize({
    required this.width,
    required this.height,
  });
  
  // Standart banner boyutları
  static const AdvertisementSize banner320x50 = AdvertisementSize(width: 320, height: 50);
  static const AdvertisementSize banner320x100 = AdvertisementSize(width: 320, height: 100);
  static const AdvertisementSize banner300x250 = AdvertisementSize(width: 300, height: 250);
  static const AdvertisementSize banner728x90 = AdvertisementSize(width: 728, height: 90);
  
  // Mobil banner boyutları
  static const AdvertisementSize mobileBanner = AdvertisementSize(width: 320, height: 50);
  static const AdvertisementSize largeBanner = AdvertisementSize(width: 320, height: 100);
  static const AdvertisementSize mediumRectangle = AdvertisementSize(width: 300, height: 250);
}

/// Reklam konfigürasyonu modeli
class AdvertisementConfig {
  final String adUnitId;
  final AdvertisementType type;
  final AdvertisementPosition position;
  final AdvertisementSize size;
  final bool isTestMode;
  final int showFrequency;
  final Duration? timeout;
  
  const AdvertisementConfig({
    required this.adUnitId,
    required this.type,
    required this.position,
    required this.size,
    this.isTestMode = false,
    this.showFrequency = 1,
    this.timeout,
  });
}

/// Reklam sonucu modeli
class AdvertisementResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  const AdvertisementResult({
    required this.success,
    this.error,
    this.metadata,
    required this.timestamp,
  });
  
  factory AdvertisementResult.success({Map<String, dynamic>? metadata}) {
    return AdvertisementResult(
      success: true,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }
  
  factory AdvertisementResult.error(String error) {
    return AdvertisementResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

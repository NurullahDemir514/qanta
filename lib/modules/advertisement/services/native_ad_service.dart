import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Basit Native Ad servis/widget birleşimi
class NativeAdService with ChangeNotifier {
  final String adUnitId;
  final String factoryId;

  NativeAd? _nativeAd;
  bool _isLoaded = false;

  NativeAdService({required this.adUnitId, this.factoryId = 'listTile'});

  bool get isLoaded => _isLoaded;
  Widget? get adWidget => _nativeAd == null ? null : AdWidget(ad: _nativeAd!);

  Future<void> load() async {
    _nativeAd?.dispose();
    _isLoaded = false;
    notifyListeners();

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
          _isLoaded = false;
          notifyListeners();
        },
      ),
    );

    await _nativeAd!.load();
  }

  void disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
  }
}


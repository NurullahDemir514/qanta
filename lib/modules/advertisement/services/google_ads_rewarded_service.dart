import 'package:flutter/foundation.dart';
import '../contracts/advertisement_service_contract.dart';

/// Google Ads Rewarded (Ödüllü) reklam servisi
/// SOLID - Single Responsibility Principle (SRP)
/// TODO: Implement rewarded ad functionality
class GoogleAdsRewardedService implements RewardedAdvertisementServiceContract {
  final String _adUnitId;
  final bool _isTestMode;
  
  void Function()? _onRewardEarned;
  
  GoogleAdsRewardedService({
    required String adUnitId,
    bool isTestMode = false,
  })  : _adUnitId = adUnitId,
        _isTestMode = isTestMode;
  
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
    debugPrint('⚠️ Rewarded ad service not implemented yet');
  }
  
  @override
  Future<void> showAd() async {
    debugPrint('⚠️ Rewarded ad service not implemented yet');
  }
  
  @override
  Future<void> hideAd() async {
    debugPrint('⚠️ Rewarded ad service not implemented yet');
  }
  
  @override
  Future<void> showRewardedAd() async {
    debugPrint('⚠️ Rewarded ad service not implemented yet');
  }
  
  @override
  Future<void> dispose() async {
    debugPrint('⚠️ Rewarded ad service not implemented yet');
  }
}


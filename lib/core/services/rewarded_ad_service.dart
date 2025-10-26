import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Rewarded Ad Service - Ödüllü reklam yönetimi
/// 
/// Free kullanıcılar için AI limiti artırmak amacıyla
/// ödüllü reklam gösterir ve backend'e bildirir.
/// 
/// SOLID: Single Responsibility - Sadece rewarded ad yönetimi
class RewardedAdService extends ChangeNotifier {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // AdMob Rewarded Ad Unit IDs
  // TODO: Replace with your production ad unit IDs
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String _productionAdUnitId = 'ca-app-pub-8222173839673706/4477439276'; // Production ID
  
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;
  
  bool get isAdReady => _isAdReady;
  bool get isAdLoading => _isAdLoading;

  /// Servisi başlat - Reklam yükle
  Future<void> initialize() async {
    debugPrint('🎬 RewardedAdService: Initializing...');
    await _loadRewardedAd();
  }

  /// Ödüllü reklam yükle
  Future<void> _loadRewardedAd() async {
    if (_isAdLoading) {
      debugPrint('⏳ RewardedAdService: Ad already loading...');
      return;
    }

    _isAdLoading = true;
    notifyListeners();

    debugPrint('📺 RewardedAdService: Loading rewarded ad...');

    // Test mode check - Use test ad unit in debug mode
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    final String adUnitId = isDebugMode ? _testAdUnitId : _productionAdUnitId;
    
    debugPrint('🎯 Using Ad Unit: ${isDebugMode ? "TEST" : "PRODUCTION"}');

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('✅ RewardedAdService: Ad loaded successfully');
          _rewardedAd = ad;
          _isAdReady = true;
          _isAdLoading = false;
          
          // Ad event callbacks
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              debugPrint('📺 RewardedAdService: Ad showed full screen content');
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              debugPrint('🚪 RewardedAdService: Ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              _isAdReady = false;
              
              // Yeni reklam yükle
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('❌ RewardedAdService: Failed to show ad: ${error.message}');
              ad.dispose();
              _rewardedAd = null;
              _isAdReady = false;
              
              // Yeni reklam yükle
              _loadRewardedAd();
            },
          );
          
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ RewardedAdService: Failed to load ad: ${error.message}');
          debugPrint('   Code: ${error.code}');
          debugPrint('   Domain: ${error.domain}');
          _rewardedAd = null;
          _isAdReady = false;
          _isAdLoading = false;
          notifyListeners();
          
          // 30 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isAdReady && !_isAdLoading) {
              _loadRewardedAd();
            }
          });
        },
      ),
    );
  }

  /// Ödüllü reklam göster
  /// Returns: Reklam izlenip ödül kazanıldıysa true
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || !_isAdReady) {
      debugPrint('❌ RewardedAdService: Ad not ready');
      return false;
    }

    bool rewardEarned = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          debugPrint('🎁 RewardedAdService: User earned reward!');
          debugPrint('   Type: ${reward.type}');
          debugPrint('   Amount: ${reward.amount}');
          
          rewardEarned = true;
          
          // Backend'e bildir - AI bonus ekle
          final success = await _addAIBonusToBackend();
          if (success) {
            debugPrint('✅ RewardedAdService: AI bonus added successfully');
          } else {
            debugPrint('❌ RewardedAdService: Failed to add AI bonus');
            rewardEarned = false; // Bonus eklenemezse ödülü iptal et
          }
        },
      );
    } catch (e) {
      debugPrint('❌ RewardedAdService: Error showing ad: $e');
      return false;
    }

    return rewardEarned;
  }

  /// Backend'e AI bonus ekle
  Future<bool> _addAIBonusToBackend() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ RewardedAdService: No user logged in');
        return false;
      }

      debugPrint('📡 RewardedAdService: Calling addAIBonus function...');
      
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('addAIBonus');
      
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data);
      
      if (data['success'] == true) {
        debugPrint('✅ Bonus added: +${data['bonusAdded']} (Total: ${data['currentBonus']}/${data['maxBonus']})');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ RewardedAdService: Backend error: $e');
      return false;
    }
  }

  /// Servisi temizle
  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    super.dispose();
  }
}


import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'point_service.dart';
import '../../modules/profile/providers/point_provider.dart';
import '../../modules/profile/providers/amazon_reward_provider.dart';
import 'premium_service.dart';
import 'amazon_reward_service.dart';

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
  // Fallback sistem: Önce primary ID'yi dene, yüklenmezse fallback ID'yi kullan
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String _productionAdUnitId = 'ca-app-pub-8222217303967306/7521155571'; // Production ID - Primary (Amazon Ödüllü - Yeni)
  static const String _productionFallbackAdUnitId = 'ca-app-pub-8222217303967306/5244843269'; // Production ID - Fallback (Eski)
  
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;
  int _currentAdUnitIndex = 0; // 0 = primary, 1 = fallback
  bool _primaryAdFailed = false; // Primary ad başarısız oldu mu?
  
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool get isAdReady => _isAdReady;
  bool get isAdLoading => _isAdLoading;

  /// Servisi başlat - Reklam yükle
  Future<void> initialize() async {
    await _loadRewardedAd();
  }

  /// Ödüllü reklam yükle (Fallback destekli)
  /// Önce primary ID'yi dener, yüklenmezse fallback ID'yi kullanır
  Future<void> _loadRewardedAd() async {
    if (_isAdLoading) {
      return;
    }

    _isAdLoading = true;
    notifyListeners();

    // Test mode check - Use test ad unit in debug mode
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    
    // Production modda: Önce primary, başarısız olursa fallback
    String adUnitId;
    if (isDebugMode) {
      adUnitId = _testAdUnitId;
      _currentAdUnitIndex = 0; // Test modda sadece test ID kullan
      _primaryAdFailed = false;
    } else {
      // Production modda fallback sistemi
      if (_primaryAdFailed || _currentAdUnitIndex == 1) {
        // Primary başarısız olduysa veya zaten fallback kullanıyorsak
        adUnitId = _productionFallbackAdUnitId;
        _currentAdUnitIndex = 1;
      } else {
        // İlk deneme: Primary ID
        adUnitId = _productionAdUnitId;
        _currentAdUnitIndex = 0;
      }
    }

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          _isAdLoading = false;
          
          // Ad event callbacks
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              // Ad showed
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _rewardedAd = null;
              _isAdReady = false;
              
              // Yeni reklam yükle (aynı ID'yi kullan - hangi ID çalıştıysa onu kullan)
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              if (kDebugMode) debugPrint('❌ RewardedAdService: Failed to show ad: ${error.message}');
              ad.dispose();
              _rewardedAd = null;
              _isAdReady = false;
              
              // Primary ad gösterilemediyse fallback'e geç
              if (!_primaryAdFailed && _currentAdUnitIndex == 0 && !isDebugMode) {
                _primaryAdFailed = true;
              }
              
              // Yeni reklam yükle
              _loadRewardedAd();
            },
          );
          
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
          debugPrint('❌ RewardedAdService: Failed to load ad: ${error.message}');
          }
          
          // Production modda ve primary başarısız olduysa fallback'e geç
          if (!isDebugMode && !_primaryAdFailed && _currentAdUnitIndex == 0) {
            _primaryAdFailed = true;
            _isAdLoading = false; // Fallback'i denemeden önce loading state'i resetle
            notifyListeners();
            
            // Hemen fallback'i dene (30 saniye bekleme)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!_isAdReady && !_isAdLoading) {
                _loadRewardedAd();
              }
            });
            return;
          }
          
          // Fallback de başarısız olduysa veya test modda
          _rewardedAd = null;
          _isAdReady = false;
          _isAdLoading = false;
          notifyListeners();
          
          // 30 saniye sonra tekrar dene (aynı ID'yi - hangi ID çalıştıysa onu)
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
      return false;
    }

    bool rewardEarned = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          rewardEarned = true;
          
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final adUnitId = _currentAdUnitIndex == 0 
              ? _productionAdUnitId 
              : _productionFallbackAdUnitId;
          
          // Convert reward amount to int (it's num type)
          final rewardAmountInt = reward.amount.toInt();
          
          // Track ad watched event in Firebase Analytics
          // Note: ResponseInfo is not available in RewardedAd callback
          // We track ad_unit_id instead for analytics
          try {
            await _analytics.logEvent(
              name: 'rewarded_ad_watched',
              parameters: {
                'ad_unit_id': adUnitId,
                'reward_type': reward.type,
                'reward_amount': rewardAmountInt,
                'user_id': userId ?? 'anonymous',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ RewardedAdService: Analytics error: $e');
          }
          
          // Save detailed ad data to Firestore for admin analytics
          if (userId != null) {
            try {
              await _saveAdWatchData(
                userId: userId,
                adUnitId: adUnitId,
                rewardType: reward.type,
                rewardAmount: rewardAmountInt,
              );
            } catch (e) {
              if (kDebugMode) debugPrint('⚠️ RewardedAdService: Failed to save ad data: $e');
            }
          }
          
          // Backend'e bildir - AI bonus ekle
          final success = await _addAIBonusToBackend();
          if (!success) {
            rewardEarned = false; // Bonus eklenemezse ödülü iptal et
          }
          
          // NEW: Add points from rewarded ad
          if (userId != null && userId.isNotEmpty) {
            try {
              final pointService = PointService();
              final pointsEarned = await pointService.earnPointsFromAd(userId);
              if (pointsEarned > 0) {
                // Refresh PointProvider to update UI immediately
                try {
                  final pointProvider = PointProvider();
                  await pointProvider.refresh();
                } catch (e) {
                  if (kDebugMode) debugPrint('⚠️ RewardedAdService: Failed to refresh PointProvider: $e');
                }
              }
            } catch (e, stackTrace) {
              if (kDebugMode) {
              debugPrint('⚠️ RewardedAdService: Point reward error: $e');
              debugPrint('⚠️ Stack trace: $stackTrace');
              }
              // Don't fail the ad reward if point reward fails
            }
            
            // NEW: Add Amazon reward credit from rewarded ad
            try {
              final amazonRewardService = AmazonRewardService();
              final amazonRewardEarned = await amazonRewardService.earnRewardFromAd(userId);
              if (amazonRewardEarned) {
                // Refresh AmazonRewardProvider to update UI immediately
                try {
                  final amazonRewardProvider = AmazonRewardProvider();
                  await amazonRewardProvider.loadCredits();
                } catch (e) {
                  if (kDebugMode) debugPrint('⚠️ RewardedAdService: Failed to refresh AmazonRewardProvider: $e');
                }
              }
            } catch (e, stackTrace) {
              if (kDebugMode) {
                debugPrint('⚠️ RewardedAdService: Amazon reward error: $e');
                debugPrint('⚠️ Stack trace: $stackTrace');
              }
              // Don't fail the ad reward if Amazon reward fails
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RewardedAdService: Error showing ad: $e');
      return false;
    }

    return rewardEarned;
  }

  /// Backend'e AI bonus ekle
  Future<bool> _addAIBonusToBackend() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) debugPrint('❌ RewardedAdService: No user logged in');
        return false;
      }
      
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('addAIBonus');
      
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data);
      
      return data['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RewardedAdService: Backend error: $e');
      return false;
    }
  }

  /// Save detailed ad watch data to Firestore for admin analytics
  Future<void> _saveAdWatchData({
    required String userId,
    required String adUnitId,
    required String rewardType,
    required int rewardAmount,
  }) async {
    try {
      final adData = {
        'user_id': userId,
        'ad_unit_id': adUnitId,
        'reward_type': rewardType,
        'reward_amount': rewardAmount,
        'watched_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ad_watch_history')
          .add(adData);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RewardedAdService: Error saving ad watch data: $e');
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


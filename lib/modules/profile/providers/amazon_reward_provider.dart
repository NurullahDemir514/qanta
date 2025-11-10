import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/amazon_reward_service.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../shared/models/amazon_reward_stats_model.dart';
import '../../../shared/models/amazon_reward_credit_model.dart';
import '../../../shared/models/amazon_gift_card_model.dart';

/// Amazon Reward Provider
/// Manages Amazon reward state and UI updates
class AmazonRewardProvider extends ChangeNotifier {
  static final AmazonRewardProvider _instance =
      AmazonRewardProvider._internal();
  factory AmazonRewardProvider() => _instance;
  AmazonRewardProvider._internal();

  final AmazonRewardService _rewardService = AmazonRewardService();
  final CountryDetectionService _countryService = CountryDetectionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AmazonRewardStats? _stats;
  List<AmazonRewardCredit> _credits = [];
  List<AmazonGiftCard> _giftCards = [];
  bool _isLoading = false;
  bool _isEligible = false;
  
  StreamSubscription<DocumentSnapshot>? _statsSubscription;
  StreamSubscription<QuerySnapshot>? _creditsSubscription;

  AmazonRewardStats? get stats => _stats;
  List<AmazonRewardCredit> get credits => _credits;
  List<AmazonGiftCard> get giftCards => _giftCards;
  bool get isLoading => _isLoading;
  bool get isEligible => _isEligible;

  double get currentBalance => _stats?.currentBalance ?? 0.0;
  
  /// Progress to next gift card (0.0 to 1.0)
  /// Calculated from Remote Config threshold
  double get progressToNextGiftCard {
    if (_stats == null) return 0.0;
    final remoteConfig = RemoteConfigService();
    final threshold = remoteConfig.getAmazonRewardMinimumThreshold();
    if (_stats!.currentBalance >= threshold) return 1.0;
    return _stats!.currentBalance / threshold;
  }
  
  /// Remaining amount to next gift card
  /// Calculated from Remote Config threshold
  double get remainingToNextGiftCard {
    if (_stats == null) {
      final remoteConfig = RemoteConfigService();
      return remoteConfig.getAmazonRewardMinimumThreshold();
    }
    final remoteConfig = RemoteConfigService();
    final threshold = remoteConfig.getAmazonRewardMinimumThreshold();
    if (_stats!.currentBalance >= threshold) return 0.0;
    return threshold - _stats!.currentBalance;
  }
  
  /// Get minimum threshold from Remote Config
  double get minimumThreshold {
    final remoteConfig = RemoteConfigService();
    return remoteConfig.getAmazonRewardMinimumThreshold();
  }
  
  /// Get gift card amount from Remote Config
  double get giftCardAmount {
    final remoteConfig = RemoteConfigService();
    return remoteConfig.getAmazonRewardGiftCardAmount();
  }

  /// Initialize provider
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check eligibility
      _isEligible = await _countryService.shouldShowAmazonRewards();
      debugPrint('🔍 AmazonRewardProvider: isEligible = $_isEligible');

      if (_isEligible) {
        await loadStats();
        await loadCredits();
        await loadGiftCards();
        
        // Setup real-time listeners for automatic updates
        _setupStatsListener();
        _setupCreditsListener();
      } else {
        debugPrint('⚠️ AmazonRewardProvider: User not eligible, skipping data load');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AmazonRewardProvider: Error initializing: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load reward statistics
  Future<void> loadStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      _stats = await _rewardService.getRewardStats(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AmazonRewardProvider: Error loading stats: $e');
    }
  }

  /// Setup real-time listener for stats updates
  void _setupStatsListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cancel existing subscription if any
    _statsSubscription?.cancel();

    // Listen to real-time updates
    _statsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('amazon_reward_stats')
        .doc('stats')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            _stats = AmazonRewardStats.fromFirestore(snapshot);
            notifyListeners();
            debugPrint('✅ AmazonRewardProvider: Stats updated from listener');
          } catch (e) {
            debugPrint('❌ AmazonRewardProvider: Error parsing stats: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ AmazonRewardProvider: Listener error: $error');
      },
    );
  }

  /// Load reward credits
  Future<void> loadCredits() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_reward_credits')
          .orderBy('earned_at', descending: true)
          .limit(100)
          .get();

      _credits = snapshot.docs
          .map((doc) => AmazonRewardCredit.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ AmazonRewardProvider: Error loading credits: $e');
    }
  }

  /// Setup real-time listener for credits updates
  void _setupCreditsListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cancel existing subscription if any
    _creditsSubscription?.cancel();

    // Listen to real-time updates
    _creditsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('amazon_reward_credits')
        .orderBy('earned_at', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          _credits = snapshot.docs
              .map((doc) => AmazonRewardCredit.fromFirestore(doc))
              .toList();
          notifyListeners();
          debugPrint('✅ AmazonRewardProvider: Credits updated from listener (${_credits.length} credits)');
        } catch (e) {
          debugPrint('❌ AmazonRewardProvider: Error parsing credits: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ AmazonRewardProvider: Credits listener error: $error');
      },
    );
  }

  /// Load gift cards
  Future<void> loadGiftCards() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // TODO: Implement loadGiftCards in AmazonRewardService
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AmazonRewardProvider: Error loading gift cards: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _creditsSubscription?.cancel();
    super.dispose();
  }
}


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/point_service.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../shared/models/point_balance_model.dart';
import '../../../shared/models/point_transaction_model.dart';

/// Point Provider
/// Manages point balance and transactions state
class PointProvider extends ChangeNotifier {
  static final PointProvider _instance = PointProvider._internal();
  factory PointProvider() => _instance;
  PointProvider._internal();

  final PointService _pointService = PointService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isInitialized = false;
  PointBalance? _balance;
  List<PointTransaction> _transactions = [];

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  PointBalance? get balance => _balance;
  List<PointTransaction> get transactions => _transactions;
  int get currentPoints => _balance?.totalPoints ?? 0;
  /// Convert points to TL value for Amazon gift cards (200 points = 1 TL)
  double get pointsToTL => (_balance?.totalPoints ?? 0) / 200.0;

  /// Initialize provider and load data
  /// Note: Only loads data for Turkish users (points system is Turkey-only)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Check if user is from Turkey (points system is Turkey-only)
      final countryService = CountryDetectionService();
      final isTurkish = await countryService.isTurkishPlayStoreUser();
      if (!isTurkish) {
        // Not Turkish user, skip loading points data
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      await Future.wait([
        loadBalance(),
        loadTransactions(),
      ]);

      // Set up real-time listeners
      _setupBalanceListener(userId);
      _setupTransactionsListener(userId);

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ PointProvider: Error initializing: $e');
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Load balance from Firestore
  Future<void> loadBalance() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      _balance = await _pointService.getBalance(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ PointProvider: Error loading balance: $e');
    }
  }

  /// Load transactions from Firestore
  Future<void> loadTransactions() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('point_transactions')
          .orderBy('earned_at', descending: true)
          .limit(50)
          .get();

      _transactions = snapshot.docs
          .map((doc) => PointTransaction.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ PointProvider: Error loading transactions: $e');
    }
  }

  /// Set up real-time listener for balance
  void _setupBalanceListener(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('point_balance')
        .doc('balance')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        try {
          _balance = PointBalance.fromFirestore(snapshot);
          notifyListeners();
        } catch (e) {
          debugPrint('❌ PointProvider: Error parsing balance: $e');
        }
      }
    });
  }

  /// Set up real-time listener for transactions
  void _setupTransactionsListener(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('point_transactions')
        .orderBy('earned_at', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      try {
        _transactions = snapshot.docs
            .map((doc) => PointTransaction.fromFirestore(doc))
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint('❌ PointProvider: Error parsing transactions: $e');
      }
    });
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadBalance(),
      loadTransactions(),
    ]);
  }
}


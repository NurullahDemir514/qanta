import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity service
/// Monitors internet connection status
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  
  NetworkService._internal() {
    _checkInitialConnection();
    _startMonitoring();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Check initial connection status
  Future<void> _checkInitialConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Start monitoring connection changes
  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('❌ Connectivity subscription error: $error');
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  /// Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    
    // Check if any of the results indicate connectivity
    _isConnected = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    if (wasConnected != _isConnected) {
      debugPrint(_isConnected 
        ? '✅ Internet bağlantısı kuruldu' 
        : '❌ İnternet bağlantısı kesildi');
      notifyListeners();
    }
  }

  /// Check current connection status
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Error checking connection: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}


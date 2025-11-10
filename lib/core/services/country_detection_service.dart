import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

// Method Channel for Android native country detection
const MethodChannel _countryChannel = MethodChannel('com.qanta/country_detection');

/// Result of country detection with method used
class CountryDetectionResult {
  final String countryCode;
  final String method; // 'play_store' or 'device_locale'

  CountryDetectionResult(this.countryCode, this.method);
}

/// Country Detection Service
/// Detects if user is from Turkish Play Store
/// 
/// SECURITY: Smart detection with safe fallback
/// 1. Primary: Play Store country code via Google Play Billing Library
/// 2. Fallback: Device locale (ONLY if it indicates TR - prevents false positives)
/// 3. Stored country info (only if detected via Play Store or temporary TR fallback)
/// 
/// This ensures:
/// - Turkish users can see the system even if Play Store detection fails
/// - Non-Turkish users cannot see the system (device locale fallback only works for TR)
class CountryDetectionService {
  static final CountryDetectionService _instance =
      CountryDetectionService._internal();
  factory CountryDetectionService() => _instance;
  CountryDetectionService._internal();


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user should see Amazon rewards
  /// Returns true ONLY for Turkish Play Store users
  /// SECURITY: No fallback - only Play Store detection is trusted
  Future<bool> shouldShowAmazonRewards() async {
    try {
      final countryCode = await getUserCountry();
      debugPrint('🌍 CountryDetectionService: Play Store country code: $countryCode');
      final result = countryCode == 'TR';
      debugPrint('✅ CountryDetectionService: shouldShowAmazonRewards: $result (Play Store detection only)');
      return result;
    } catch (e) {
      debugPrint('❌ CountryDetectionService: Error checking country: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false; // Default to false for safety - deny access on error
    }
  }

  /// Get user's country code
  /// Returns 'TR' for Turkey, null if not detected
  /// CRITICAL: Only uses Play Store country detection for security
  /// Device locale fallback is NOT used to prevent false positives
  Future<String?> getUserCountry() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️ CountryDetectionService: No user ID available');
        return null;
      }

      // First check Firebase stored country info
      // IMPORTANT: Only trust country info if detected via Play Store (not device locale)
      final countryDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('country_info')
          .doc('info')
          .get();

      if (countryDoc.exists) {
        final data = countryDoc.data()!;
        final countryCode = data['country_code'] as String?;
        final detectionMethod = data['detection_method'] as String?;
        
        // Accept country code if detected via Play Store (permanent)
        if (countryCode != null && countryCode.isNotEmpty) {
          if (detectionMethod == 'play_store') {
            debugPrint('✅ CountryDetectionService: Using stored Play Store country: $countryCode');
            return countryCode;
          } else if (detectionMethod == 'device_locale_temporary' && countryCode == 'TR') {
            // Temporary fallback was used before - accept it for streak widget and other features
            // but try to re-detect Play Store in background for better accuracy
            debugPrint('✅ CountryDetectionService: Using stored temporary fallback country: $countryCode (for streak widget)');
            // Try to re-detect Play Store in background (don't wait for it)
            _detectCountryWithMethod().then((result) {
              if (result != null && result.method == 'play_store' && result.countryCode == 'TR') {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  _saveCountryInfoWithMethod(userId, result.countryCode, result.method);
                  debugPrint('✅ CountryDetectionService: Updated country detection to Play Store in background');
                }
              }
            }).catchError((e) {
              debugPrint('⚠️ CountryDetectionService: Background re-detection failed: $e');
            });
            return countryCode; // Return stored TR immediately
          } else if (detectionMethod == 'device_locale' && countryCode == 'TR') {
            // Old device_locale method - accept if TR, but try to upgrade to Play Store
            debugPrint('✅ CountryDetectionService: Using stored device_locale country: $countryCode (for streak widget)');
            // Try to re-detect Play Store in background
            _detectCountryWithMethod().then((result) {
              if (result != null && result.method == 'play_store' && result.countryCode == 'TR') {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  _saveCountryInfoWithMethod(userId, result.countryCode, result.method);
                  debugPrint('✅ CountryDetectionService: Updated country detection to Play Store in background');
                }
              }
            }).catchError((e) {
              debugPrint('⚠️ CountryDetectionService: Background re-detection failed: $e');
            });
            return countryCode; // Return stored TR immediately
          }
        }
      }

      // If not stored or stored method was device_locale, detect with smart fallback
      debugPrint('🔍 CountryDetectionService: Detecting country with smart fallback...');
      final detectionResult = await _detectCountryWithMethod();
      if (detectionResult != null) {
        // Save Play Store detection permanently
        if (detectionResult.method == 'play_store') {
          await _saveCountryInfoWithMethod(userId, detectionResult.countryCode, detectionResult.method);
          debugPrint('✅ CountryDetectionService: Detected and saved country: ${detectionResult.countryCode} (method: ${detectionResult.method})');
          return detectionResult.countryCode;
        } else if (detectionResult.method == 'device_locale_temporary') {
          // Device locale fallback (TR only) - use but don't save permanently
          // This allows Turkish users to see the system when Play Store detection fails
          // But we don't save it to prevent false positives from persisting
          debugPrint('✅ CountryDetectionService: Using temporary device locale fallback: ${detectionResult.countryCode} (not saved to Firebase)');
          return detectionResult.countryCode;
        } else {
          // Unknown method - reject
          debugPrint('⚠️ CountryDetectionService: Unknown detection method: ${detectionResult.method}');
          return null;
        }
      } else {
        debugPrint('⚠️ CountryDetectionService: Could not detect country');
        return null;
      }
    } catch (e) {
      debugPrint('❌ CountryDetectionService: Error getting country: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }


  /// Detect country using Play Store country code
  /// SECURITY: Smart fallback - only accepts device locale if it's TR (Turkey)
  /// This prevents false positives while allowing Turkish users to see the system
  /// Returns: CountryDetectionResult with country code and detection method
  Future<CountryDetectionResult?> _detectCountryWithMethod() async {
    debugPrint('🔍 CountryDetectionService: Starting Play Store country detection...');
    
    // PRIMARY METHOD: Check Play Store country (Android only)
    if (Platform.isAndroid) {
      final playStoreCountry = await _getPlayStoreCountry();
      if (playStoreCountry != null && playStoreCountry.isNotEmpty) {
        debugPrint(
          '✅ CountryDetectionService: Detected $playStoreCountry from Play Store',
        );
        return CountryDetectionResult(playStoreCountry, 'play_store');
      }
    }

    // SMART FALLBACK: Only use device locale if it indicates Turkey
    // This allows Turkish users to see the system even if Play Store detection fails
    // But prevents non-Turkish users from seeing it
    debugPrint('⚠️ CountryDetectionService: Play Store detection failed, checking device locale as fallback...');
    final deviceLocaleCountry = await _getDeviceLocale();
    
    if (deviceLocaleCountry == 'TR') {
      // Device locale indicates Turkey - accept as temporary fallback
      // This helps Turkish users when Play Store detection fails
      debugPrint('✅ CountryDetectionService: Device locale indicates TR, accepting as temporary fallback');
      return CountryDetectionResult('TR', 'device_locale_temporary');
    } else if (deviceLocaleCountry != null) {
      // Device locale indicates non-Turkey country - reject for security
      debugPrint('🔒 CountryDetectionService: Device locale indicates $deviceLocaleCountry (not TR), rejecting for security');
      return null;
    } else {
      // Could not determine device locale - reject for security
      debugPrint('⚠️ CountryDetectionService: Could not determine device locale, rejecting for security');
      return null;
    }
  }

  /// Get device locale as smart fallback
  /// Only returns 'TR' if device locale indicates Turkey
  /// Returns null for all other countries to prevent false positives
  Future<String?> _getDeviceLocale() async {
    try {
      // Check Platform locale (device's actual locale)
      try {
        final platformLocale = Platform.localeName; // e.g., "tr_TR", "en_US"
        debugPrint('🔍 CountryDetectionService: Platform locale: $platformLocale');
        if (platformLocale.toLowerCase().startsWith('tr')) {
          debugPrint('✅ CountryDetectionService: Platform locale indicates TR');
          return 'TR';
        }
      } catch (e) {
        debugPrint('⚠️ CountryDetectionService: Error getting Platform locale: $e');
      }
      
      // Check SharedPreferences (user's selected locale in app)
      try {
        final prefs = await SharedPreferences.getInstance();
        final localeCode = prefs.getString('locale');
        debugPrint('🔍 CountryDetectionService: SharedPreferences locale: $localeCode');
        if (localeCode != null && localeCode.startsWith('tr')) {
          debugPrint('✅ CountryDetectionService: SharedPreferences locale indicates TR');
          return 'TR';
        }
      } catch (e) {
        debugPrint('⚠️ CountryDetectionService: Error getting SharedPreferences locale: $e');
      }
      
      // Check WidgetsBinding locale (if available)
      try {
        final binding = WidgetsBinding.instance;
        if (binding.platformDispatcher.locales.isNotEmpty) {
          final systemLocale = binding.platformDispatcher.locales.first.languageCode;
          debugPrint('🔍 CountryDetectionService: WidgetsBinding locale: $systemLocale');
          if (systemLocale.toLowerCase() == 'tr') {
            debugPrint('✅ CountryDetectionService: WidgetsBinding locale indicates TR');
            return 'TR';
          }
        }
      } catch (e) {
        debugPrint('⚠️ CountryDetectionService: Error getting WidgetsBinding locale: $e');
      }
      
      // Return null if not TR (prevents false positives)
      debugPrint('⚠️ CountryDetectionService: Device locale does not indicate TR');
      return null;
    } catch (e) {
      debugPrint('❌ CountryDetectionService: Error in _getDeviceLocale: $e');
      return null;
    }
  }


  /// Get Play Store country (Android)
  /// Uses Android native code to get SIM card, network, or locale country code
  /// Priority: SIM card > Network > Locale
  Future<String?> _getPlayStoreCountry() async {
    if (!Platform.isAndroid) {
    return null;
  }

    try {
      debugPrint('🔍 CountryDetectionService: Getting Play Store country from Android native...');
      
      // Call Android native method to get country code
      final countryCode = await _countryChannel.invokeMethod<String>('getPlayStoreCountry');
      
      if (countryCode != null && countryCode.isNotEmpty) {
        debugPrint('✅ CountryDetectionService: Play Store country detected: $countryCode');
        return countryCode;
      }
      
      debugPrint('⚠️ CountryDetectionService: Play Store country not available');
      return null;
    } catch (e) {
      debugPrint('❌ CountryDetectionService: Error getting Play Store country: $e');
      return null;
    }
  }


  /// Save country info to Firebase
  Future<void> _saveCountryInfo(String userId, String countryCode) async {
    // This method is deprecated, use _saveCountryInfoWithMethod directly
    // Default to 'play_store' if method is not known
    await _saveCountryInfoWithMethod(userId, countryCode, 'play_store');
  }

  /// Save country info to Firebase with specified method
  Future<void> _saveCountryInfoWithMethod(String userId, String countryCode, String detectionMethod) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('country_info')
          .doc('info')
          .set({
        'user_id': userId,
        'country_code': countryCode,
        'detection_method': detectionMethod,
        'detected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '✅ CountryDetectionService: Saved country info: $countryCode ($detectionMethod)',
      );
    } catch (e) {
      debugPrint('❌ CountryDetectionService: Error saving country: $e');
    }
  }


  /// Check if user is Turkish Play Store user
  /// SECURITY: Only returns true if country was detected via Play Store
  /// Returns false if Play Store detection fails (no fallback)
  Future<bool> isTurkishPlayStoreUser() async {
    final country = await getUserCountry();
    final isTurkish = country == 'TR';
    debugPrint('🔒 CountryDetectionService: isTurkishPlayStoreUser: $isTurkish (Play Store detection only, no fallback)');
    return isTurkish;
  }
}


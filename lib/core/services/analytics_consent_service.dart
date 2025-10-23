import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/analytics_consent_model.dart';

/// Kullanıcı veri toplama izin yönetimi servisi
/// Single Responsibility: Sadece izin durumunu yönetir
class AnalyticsConsentService {
  static const String _consentKey = 'analytics_consent';
  static const String _consentDateKey = 'analytics_consent_date';
  static const String _consentAskedKey = 'analytics_consent_asked';
  
  /// İzin verilmiş mi kontrol et
  static Future<bool> isConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool(_consentKey) ?? false;
    debugPrint('🔍 Analytics Consent Check: $consent');
    return consent;
  }
  
  /// İzin durumunu kaydet
  static Future<void> saveConsent(bool isGiven) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, isGiven);
    await prefs.setString(_consentDateKey, DateTime.now().toIso8601String());
    await prefs.setBool(_consentAskedKey, true);
  }
  
  /// Kullanıcıya daha önce sorulmuş mu?
  static Future<bool> hasBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentAskedKey) ?? false;
  }
  
  /// İzin verilme tarihini al
  static Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_consentDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }
  
  /// İzin modelini al
  static Future<AnalyticsConsent?> getConsent() async {
    final isGiven = await isConsentGiven();
    final date = await getConsentDate();
    
    if (date == null) return null;
    
    return AnalyticsConsent(
      isConsentGiven: isGiven,
      consentDate: date,
    );
  }
  
  /// Tüm izin verilerini temizle (logout için)
  static Future<void> clearConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
    await prefs.remove(_consentDateKey);
    await prefs.remove(_consentAskedKey);
  }
}


import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config Service
/// Uzaktan yapılandırma ve dinamik içerik yönetimi
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Remote Config'i başlat
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Fetch ayarları
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1), // Prod: 1 saat
        ),
      );

      // Default değerler
      await _remoteConfig!.setDefaults({
        // Bildirim Mesajları - Türkçe
        'notification_messages_tr': _getDefaultNotificationMessagesTR(),
        
        // Bildirim Mesajları - İngilizce
        'notification_messages_en': _getDefaultNotificationMessagesEN(),
        
        // Bildirim Zamanları (saat formatında: 9,12,15,18,21)
        'notification_hours': '9,12,15,18,21',
        
        // Bildirim aktif mi?
        'notifications_enabled': true,
        
        // Bildirim sıklığı (dakika) - Workmanager çalışma sıklığı
        'notification_interval_minutes': 15,
        
        // Akıllı zamanlama ayarları
        'smart_scheduling_enabled': true, // Akıllı zamanlama aktif mi?
        'min_hours_between_notifications': 2, // Bildirimler arası minimum saat
        'max_daily_notifications': 4, // Günlük maksimum bildirim sayısı
        'notification_start_hour': 9, // İlk bildirim saati (09:00)
        'notification_end_hour': 21, // Son bildirim saati (21:00)
      });

      // İlk fetch
      await fetchAndActivate();

      _initialized = true;
      debugPrint('✅ RemoteConfigService initialized');
    } catch (e) {
      debugPrint('❌ RemoteConfigService initialization failed: $e');
    }
  }

  /// Remote Config'den veri çek ve aktive et
  Future<bool> fetchAndActivate() async {
    try {
      if (_remoteConfig == null) return false;
      
      final activated = await _remoteConfig!.fetchAndActivate();
      if (activated) {
        debugPrint('🔄 Remote Config updated and activated');
      } else {
        debugPrint('ℹ️ Remote Config already up to date');
      }
      return activated;
    } catch (e) {
      debugPrint('❌ Remote Config fetch failed: $e');
      return false;
    }
  }

  /// Bildirim mesajlarını al (kullanıcının diline göre)
  /// Format: key|title|body
  Map<String, Map<String, String>> getNotificationMessages(String languageCode) {
    try {
      if (_remoteConfig == null) return _parseDefaultMessages(languageCode);

      // Dil koduna göre parametre seç
      final paramKey = languageCode == 'tr' 
          ? 'notification_messages_tr' 
          : 'notification_messages_en';
      
      final messagesJson = _remoteConfig!.getString(paramKey);
      
      if (messagesJson.isEmpty) return _parseDefaultMessages(languageCode);

      // JSON parse - key|title|body formatı
      final messages = <String, Map<String, String>>{};
      final lines = messagesJson.split('\n');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length == 3) {
          final key = parts[0].trim();
          messages[key] = {
            'title': parts[1].trim(),
            'body': parts[2].trim(),
          };
        }
      }

      return messages.isEmpty ? _parseDefaultMessages(languageCode) : messages;
    } catch (e) {
      debugPrint('❌ Error parsing notification messages: $e');
      return _parseDefaultMessages(languageCode);
    }
  }

  /// Bildirim saatlerini al
  List<int> getNotificationHours() {
    try {
      if (_remoteConfig == null) return [12, 18, 21];

      final hoursString = _remoteConfig!.getString('notification_hours');
      if (hoursString.isEmpty) return [12, 18, 21];

      return hoursString
          .split(',')
          .map((h) => int.tryParse(h.trim()) ?? -1)
          .where((h) => h >= 0 && h <= 23)
          .toList();
    } catch (e) {
      debugPrint('❌ Error parsing notification hours: $e');
      return [12, 18, 21];
    }
  }

  /// Bildirimler aktif mi?
  bool areNotificationsEnabled() {
    try {
      return _remoteConfig?.getBool('notifications_enabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Bildirim sıklığını al (dakika)
  int getNotificationIntervalMinutes() {
    try {
      return _remoteConfig?.getInt('notification_interval_minutes') ?? 15;
    } catch (e) {
      return 15;
    }
  }

  /// Akıllı zamanlama aktif mi?
  bool isSmartSchedulingEnabled() {
    try {
      return _remoteConfig?.getBool('smart_scheduling_enabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Bildirimler arası minimum saat
  int getMinHoursBetweenNotifications() {
    try {
      return _remoteConfig?.getInt('min_hours_between_notifications') ?? 2;
    } catch (e) {
      return 2;
    }
  }

  /// Günlük maksimum bildirim sayısı
  int getMaxDailyNotifications() {
    try {
      return _remoteConfig?.getInt('max_daily_notifications') ?? 4;
    } catch (e) {
      return 4;
    }
  }

  /// İlk bildirim saati
  int getNotificationStartHour() {
    try {
      return _remoteConfig?.getInt('notification_start_hour') ?? 9;
    } catch (e) {
      return 9;
    }
  }

  /// Son bildirim saati
  int getNotificationEndHour() {
    try {
      return _remoteConfig?.getInt('notification_end_hour') ?? 21;
    } catch (e) {
      return 21;
    }
  }

  /// Default mesajlar - Türkçe (fallback)
  /// Zamanlama: Hafta içi 09:00, 12:30, 15:30, 19:00, 21:00 | Hafta sonu 11:00, 20:00
  String _getDefaultNotificationMessagesTR() {
    return '''
morning|Günaydın! 🌅|Bugünkü bütçenizi kontrol edin
lunch|Öğle Arası 🍽️|Öğle yemeği harcamanızı eklediniz mi?
afternoon|Öğleden Sonra ☕|Küçük harcamalarınızı kaydetmeyi unutmayın
evening|Akşam Saati 🌆|Alışverişlerinizi kaydetme zamanı
night|Gün Sonu 🌙|Bugünkü işlemlerinizi gözden geçirin
weekend_morning|Hafta Sonu 🎯|Haftalık harcamalarınızı inceleyin
weekend_evening|Hafta Sonu Özeti 📊|Gelecek hafta için planınızı yapın
general|Qanta Hatırlatıcı|Finanslarınızı düzenli tutun''';
  }

  /// Default mesajlar - İngilizce (fallback)
  /// Timing: Weekday 09:00, 12:30, 15:30, 19:00, 21:00 | Weekend 11:00, 20:00
  String _getDefaultNotificationMessagesEN() {
    return '''
morning|Good Morning! 🌅|Check your budget for today
lunch|Lunch Time 🍽️|Have you tracked your lunch expenses?
afternoon|Afternoon Break ☕|Don't forget to track small expenses
evening|Evening Time 🌆|Time to record your shopping
night|Day End 🌙|Review your today's transactions
weekend_morning|Weekend 🎯|Review your weekly spending
weekend_evening|Weekend Summary 📊|Plan for next week
general|Qanta Reminder|Keep your finances organized''';
  }

  /// Default mesajları parse et (dile göre)
  Map<String, Map<String, String>> _parseDefaultMessages(String languageCode) {
    if (languageCode == 'tr') {
      return {
        'morning': {'title': 'Günaydın! 🌅', 'body': 'Bugünkü bütçenizi kontrol edin'},
        'lunch': {'title': 'Öğle Arası 🍽️', 'body': 'Öğle yemeği harcamanızı eklediniz mi?'},
        'afternoon': {'title': 'Öğleden Sonra ☕', 'body': 'Küçük harcamalarınızı kaydetmeyi unutmayın'},
        'evening': {'title': 'Akşam Saati 🌆', 'body': 'Alışverişlerinizi kaydetme zamanı'},
        'night': {'title': 'Gün Sonu 🌙', 'body': 'Bugünkü işlemlerinizi gözden geçirin'},
        'weekend_morning': {'title': 'Hafta Sonu 🎯', 'body': 'Haftalık harcamalarınızı inceleyin'},
        'weekend_evening': {'title': 'Hafta Sonu Özeti 📊', 'body': 'Gelecek hafta için planınızı yapın'},
        'general': {'title': 'Qanta Hatırlatıcı', 'body': 'Finanslarınızı düzenli tutun'},
      };
    } else {
      return {
        'morning': {'title': 'Good Morning! 🌅', 'body': 'Check your budget for today'},
        'lunch': {'title': 'Lunch Time 🍽️', 'body': 'Have you tracked your lunch expenses?'},
        'afternoon': {'title': 'Afternoon Break ☕', 'body': 'Don\'t forget to track small expenses'},
        'evening': {'title': 'Evening Time 🌆', 'body': 'Time to record your shopping'},
        'night': {'title': 'Day End 🌙', 'body': 'Review your today\'s transactions'},
        'weekend_morning': {'title': 'Weekend 🎯', 'body': 'Review your weekly spending'},
        'weekend_evening': {'title': 'Weekend Summary 📊', 'body': 'Plan for next week'},
        'general': {'title': 'Qanta Reminder', 'body': 'Keep your finances organized'},
      };
    }
  }
}


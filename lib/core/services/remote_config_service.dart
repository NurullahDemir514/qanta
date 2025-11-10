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
        
        // ========== AMAZON REWARD SYSTEM ==========
        // Amazon reward ödül miktarları (TL)
        'amazon_reward_rewarded_ad_amount': 0.20, // Reklam izleme ödülü
        'amazon_reward_transaction_amount': 0.03, // Harcama ekleme ödülü
        
        // Amazon reward eşik ve limitler
        'amazon_reward_minimum_threshold': 100.0, // Minimum hediye kartı eşiği (TL)
        'amazon_reward_gift_card_amount': 100.0, // Hediye kartı tutarı (TL)
        'amazon_reward_max_daily_ads': 10, // Günlük maksimum reklam sayısı
        'amazon_reward_max_daily_transactions': 20, // Günlük maksimum harcama ödülü
        
        // ========== POINT SYSTEM ==========
        // Puan değerleri
        'point_rewarded_ad': 50, // Reklam izleme puanı
        'point_transaction': 15, // Harcama ekleme puanı
        'point_daily_login': 25, // Günlük giriş puanı
        'point_weekly_streak': 1000, // Haftalık seri puanı
        'point_monthly_goal': 50, // Aylık hedef puanı
        'point_referral': 500, // Referans puanı (her arkadaş getirene 500 puan)
        'point_budget_goal': 15, // Bütçe hedefi puanı
        'point_savings_milestone': 12, // Birikim kilometre taşı puanı
        'point_premium_bonus': 50, // Premium bonus puanı
        'point_special_event': 25, // Özel etkinlik puanı
        'point_first_card': 250, // İlk kart puanı
        'point_first_budget': 250, // İlk bütçe puanı
        'point_first_stock_purchase': 250, // İlk hisse alımı puanı
        'point_first_subscription': 250, // İlk abonelik puanı
        
        // Puan sistemi limitler
        'point_max_daily_ads': 10, // Günlük maksimum reklam
        'point_max_daily_transactions': 20, // Günlük maksimum harcama
        'point_max_daily_login': 1, // Günlük maksimum giriş
        
        // Puan dönüşüm oranları
        'point_to_tl_rate': 200, // 200 puan = 1 TL (Amazon hediye kartı)
        'point_minimum_redemption': 20000, // Minimum çekilebilir puan (20,000 = 100 TL)
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

  // ========== AMAZON REWARD SYSTEM GETTERS ==========

  /// Amazon reward - Reklam izleme ödülü (TL)
  double getAmazonRewardRewardedAdAmount() {
    try {
      return _remoteConfig?.getDouble('amazon_reward_rewarded_ad_amount') ?? 0.20;
    } catch (e) {
      return 0.20;
    }
  }

  /// Amazon reward - Harcama ekleme ödülü (TL)
  double getAmazonRewardTransactionAmount() {
    try {
      return _remoteConfig?.getDouble('amazon_reward_transaction_amount') ?? 0.03;
    } catch (e) {
      return 0.03;
    }
  }

  /// Amazon reward - Minimum hediye kartı eşiği (TL)
  double getAmazonRewardMinimumThreshold() {
    try {
      return _remoteConfig?.getDouble('amazon_reward_minimum_threshold') ?? 100.0;
    } catch (e) {
      return 100.0;
    }
  }

  /// Amazon reward - Hediye kartı tutarı (TL)
  double getAmazonRewardGiftCardAmount() {
    try {
      return _remoteConfig?.getDouble('amazon_reward_gift_card_amount') ?? 100.0;
    } catch (e) {
      return 100.0;
    }
  }

  /// Amazon reward - Günlük maksimum reklam sayısı
  int getAmazonRewardMaxDailyAds() {
    try {
      return _remoteConfig?.getInt('amazon_reward_max_daily_ads') ?? 10;
    } catch (e) {
      return 10;
    }
  }

  /// Amazon reward - Günlük maksimum harcama ödülü
  int getAmazonRewardMaxDailyTransactions() {
    try {
      return _remoteConfig?.getInt('amazon_reward_max_daily_transactions') ?? 20;
    } catch (e) {
      return 20;
    }
  }

  // ========== POINT SYSTEM GETTERS ==========

  /// Point - Reklam izleme puanı
  int getPointRewardedAd() {
    try {
      return _remoteConfig?.getInt('point_rewarded_ad') ?? 50;
    } catch (e) {
      return 50;
    }
  }

  /// Point - Harcama ekleme puanı
  int getPointTransaction() {
    try {
      return _remoteConfig?.getInt('point_transaction') ?? 15;
    } catch (e) {
      return 15;
    }
  }

  /// Point - Günlük giriş puanı
  int getPointDailyLogin() {
    try {
      return _remoteConfig?.getInt('point_daily_login') ?? 25;
    } catch (e) {
      return 25;
    }
  }

  /// Point - Haftalık seri puanı
  int getPointWeeklyStreak() {
    try {
      return _remoteConfig?.getInt('point_weekly_streak') ?? 1000;
    } catch (e) {
      return 1000;
    }
  }

  /// Point - Aylık hedef puanı
  int getPointMonthlyGoal() {
    try {
      return _remoteConfig?.getInt('point_monthly_goal') ?? 50;
    } catch (e) {
      return 50;
    }
  }

  /// Point - Referans puanı
  int getPointReferral() {
    try {
      return _remoteConfig?.getInt('point_referral') ?? 500;
    } catch (e) {
      return 500;
    }
  }

  /// Point - Bütçe hedefi puanı
  int getPointBudgetGoal() {
    try {
      return _remoteConfig?.getInt('point_budget_goal') ?? 15;
    } catch (e) {
      return 15;
    }
  }

  /// Point - Birikim kilometre taşı puanı
  int getPointSavingsMilestone() {
    try {
      return _remoteConfig?.getInt('point_savings_milestone') ?? 12;
    } catch (e) {
      return 12;
    }
  }

  /// Point - Premium bonus puanı
  int getPointPremiumBonus() {
    try {
      return _remoteConfig?.getInt('point_premium_bonus') ?? 50;
    } catch (e) {
      return 50;
    }
  }

  /// Point - Özel etkinlik puanı
  int getPointSpecialEvent() {
    try {
      return _remoteConfig?.getInt('point_special_event') ?? 25;
    } catch (e) {
      return 25;
    }
  }

  /// Point - İlk kart puanı
  int getPointFirstCard() {
    try {
      return _remoteConfig?.getInt('point_first_card') ?? 250;
    } catch (e) {
      return 250;
    }
  }

  /// Point - İlk bütçe puanı
  int getPointFirstBudget() {
    try {
      return _remoteConfig?.getInt('point_first_budget') ?? 250;
    } catch (e) {
      return 250;
    }
  }

  /// Point - İlk hisse alımı puanı
  int getPointFirstStockPurchase() {
    try {
      return _remoteConfig?.getInt('point_first_stock_purchase') ?? 250;
    } catch (e) {
      return 250;
    }
  }

  /// Point - İlk abonelik puanı
  int getPointFirstSubscription() {
    try {
      return _remoteConfig?.getInt('point_first_subscription') ?? 250;
    } catch (e) {
      return 250;
    }
  }

  /// Point - Günlük maksimum reklam
  int getPointMaxDailyAds() {
    try {
      return _remoteConfig?.getInt('point_max_daily_ads') ?? 10;
    } catch (e) {
      return 10;
    }
  }

  /// Point - Günlük maksimum harcama
  int getPointMaxDailyTransactions() {
    try {
      return _remoteConfig?.getInt('point_max_daily_transactions') ?? 20;
    } catch (e) {
      return 20;
    }
  }

  /// Point - Günlük maksimum giriş
  int getPointMaxDailyLogin() {
    try {
      return _remoteConfig?.getInt('point_max_daily_login') ?? 1;
    } catch (e) {
      return 1;
    }
  }

  /// Point - Puan to TL dönüşüm oranı (200 puan = 1 TL for Amazon gift cards)
  int getPointToTLRate() {
    try {
      return _remoteConfig?.getInt('point_to_tl_rate') ?? 200;
    } catch (e) {
      return 200;
    }
  }

  /// Point - Minimum çekilebilir puan
  int getPointMinimumRedemption() {
    try {
      return _remoteConfig?.getInt('point_minimum_redemption') ?? 20000;
    } catch (e) {
      return 20000;
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


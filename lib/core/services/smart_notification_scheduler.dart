import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Akıllı bildirim zamanlayıcı
/// Kullanıcıyı rahatsız etmeden optimal zamanlarda bildirim gönderir
/// 
/// Bildirim Planı:
/// Hafta İçi: 09:00, 12:30, 15:30, 19:00, 21:00
/// Hafta Sonu: 11:00, 20:00
class SmartNotificationScheduler {
  static const String _lastNotificationKey = 'last_notification_time';
  static const String _dailyNotificationCountKey = 'daily_notification_count';
  static const String _lastNotificationDateKey = 'last_notification_date';
  static const String _lastNotificationMessageKey = 'last_notification_message';
  static const String _lastNotificationSlotKey = 'last_notification_slot';

  /// Bildirim zaman dilimlerini tanımla
  static const Map<String, List<int>> _notificationSlots = {
    'weekday': [9, 12, 15, 19, 21], // Hafta içi: 5 zaman dilimi
    'weekend': [11, 20], // Hafta sonu: 2 zaman dilimi
  };

  /// Bildirim gönderilmeli mi kontrol et
  static Future<bool> shouldSendNotification() async {
    try {
      final now = DateTime.now();
      
      // 1️⃣ Hafta içi / hafta sonu kontrolü
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      final slots = isWeekend ? _notificationSlots['weekend']! : _notificationSlots['weekday']!;
      
      // 2️⃣ Şu anki zaman dilimini bul
      final currentSlot = _findCurrentSlot(now.hour, now.minute, slots);
      if (currentSlot == null) {
        debugPrint('⏰ Not in notification time slot (${now.hour}:${now.minute.toString().padLeft(2, '0')})');
        return false;
      }
      
      // 3️⃣ Bu zaman diliminde bildirim gönderildi mi kontrol et
      final lastSlot = await _getLastNotificationSlot();
      final lastDate = await _getLastNotificationDate();
      final today = _getTodayString();
      
      if (lastDate == today && lastSlot == currentSlot) {
        debugPrint('📭 Notification already sent for slot $currentSlot today');
        return false;
      }
      
      // 4️⃣ Günlük limit kontrolü
      final dailyCount = await _getDailyNotificationCount();
      final maxDailyNotifications = isWeekend ? 2 : 5; // Hafta sonu 2, hafta içi 5
      
      if (dailyCount >= maxDailyNotifications) {
        debugPrint('📊 Daily notification limit reached ($dailyCount/$maxDailyNotifications)');
        return false;
      }
      
      // 5️⃣ Son bildirimden geçen süre kontrolü (minimum 2 saat)
      final lastNotificationTime = await _getLastNotificationTime();
      if (lastNotificationTime != null) {
        final hoursSinceLastNotification = now.difference(lastNotificationTime).inHours;
        const minHoursBetweenNotifications = 2;
        
        if (hoursSinceLastNotification < minHoursBetweenNotifications) {
          debugPrint('⏱️ Too soon since last notification ($hoursSinceLastNotification hours)');
          return false;
        }
      }
      
      debugPrint('✅ Notification approved - Slot: $currentSlot, Day: ${isWeekend ? 'Weekend' : 'Weekday'}');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking notification conditions: $e');
      return false;
    }
  }

  /// Şu anki saatin hangi zaman dilimine düştüğünü bul
  /// Örnek: 09:15 -> slot 9, 12:45 -> slot 12
  static int? _findCurrentSlot(int hour, int minute, List<int> slots) {
    // Her slot için ±30 dakika tolerans
    for (final slot in slots) {
      // Slot başlangıcı: slot:00 - 30 dakika
      // Slot bitişi: slot:00 + 45 dakika
      final slotStart = slot * 60 - 30; // Dakikaya çevir
      final slotEnd = slot * 60 + 45;
      final currentMinutes = hour * 60 + minute;
      
      if (currentMinutes >= slotStart && currentMinutes <= slotEnd) {
        return slot;
      }
    }
    return null;
  }

  /// Bildirim gönderildiğini kaydet
  static Future<void> markNotificationSent(String messageTitle, int slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Son bildirim zamanını kaydet
      await prefs.setString(_lastNotificationKey, now.toIso8601String());
      
      // Son mesajı kaydet (tekrar göndermeyi önlemek için)
      await prefs.setString(_lastNotificationMessageKey, messageTitle);
      
      // Son slot'u kaydet
      await prefs.setInt(_lastNotificationSlotKey, slot);
      
      // Günlük sayacı artır
      final today = _getTodayString();
      final lastDate = prefs.getString(_lastNotificationDateKey);
      
      if (lastDate != today) {
        // Yeni gün - sayacı sıfırla
        await prefs.setInt(_dailyNotificationCountKey, 1);
        await prefs.setString(_lastNotificationDateKey, today);
      } else {
        // Aynı gün - sayacı artır
        final currentCount = prefs.getInt(_dailyNotificationCountKey) ?? 0;
        await prefs.setInt(_dailyNotificationCountKey, currentCount + 1);
      }
      
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      debugPrint('📝 Notification logged: $messageTitle at ${now.hour}:${now.minute} (Slot: $slot, ${isWeekend ? 'Weekend' : 'Weekday'})');
    } catch (e) {
      debugPrint('❌ Error logging notification: $e');
    }
  }

  /// Zaman dilimine göre doğru mesajı seç
  static String getMessageIndexForSlot(int slot, bool isWeekend) {
    if (isWeekend) {
      // Hafta sonu: 2 mesaj
      // 11:00 -> 0 (sabah), 20:00 -> 1 (akşam)
      return slot == 11 ? 'weekend_morning' : 'weekend_evening';
    } else {
      // Hafta içi: 5 mesaj
      switch (slot) {
        case 9: return 'morning';        // Sabah
        case 12: return 'lunch';         // Öğle
        case 15: return 'afternoon';     // Öğleden sonra
        case 19: return 'evening';       // Akşam
        case 21: return 'night';         // Gece
        default: return 'general';
      }
    }
  }

  /// Son bildirim zamanını al
  static Future<DateTime?> _getLastNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastNotificationKey);
      
      if (timeString == null) return null;
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  /// Günlük bildirim sayısını al
  static Future<int> _getDailyNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();
      final lastDate = prefs.getString(_lastNotificationDateKey);
      
      // Yeni gün başladıysa sayacı sıfırla
      if (lastDate != today) {
        return 0;
      }
      
      return prefs.getInt(_dailyNotificationCountKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Son bildirim slot'unu al
  static Future<int?> _getLastNotificationSlot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastNotificationSlotKey);
    } catch (e) {
      return null;
    }
  }

  /// Son bildirim tarihini al
  static Future<String?> _getLastNotificationDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastNotificationDateKey);
    } catch (e) {
      return null;
    }
  }

  /// Bugünün tarihini string olarak al (YYYY-MM-DD)
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Son gönderilen mesajı al (tekrar önlemek için)
  static Future<String?> getLastNotificationMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastNotificationMessageKey);
    } catch (e) {
      return null;
    }
  }

  /// Bildirim istatistiklerini al (debug için)
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTime = await _getLastNotificationTime();
      final dailyCount = await _getDailyNotificationCount();
      final lastMessage = await getLastNotificationMessage();
      
      return {
        'last_notification_time': lastTime?.toString() ?? 'Never',
        'daily_count': dailyCount,
        'last_message': lastMessage ?? 'None',
        'today': _getTodayString(),
      };
    } catch (e) {
      return {};
    }
  }

  /// Tüm bildirim verilerini temizle (test için)
  static Future<void> resetNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_dailyNotificationCountKey);
      await prefs.remove(_lastNotificationDateKey);
      await prefs.remove(_lastNotificationMessageKey);
      debugPrint('🔄 Notification data reset');
    } catch (e) {
      debugPrint('❌ Error resetting notification data: $e');
    }
  }
}


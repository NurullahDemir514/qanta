import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'statement_service.dart';
import 'firebase_auth_service.dart';
import '../../shared/models/statement_period.dart';

/// Hatırlatıcı servisi - Ekstre ödeme hatırlatıcıları yönetir
class ReminderService {
  /// Hatırlatıcı kur
  static Future<bool> setStatementReminder({
    required String cardId,
    required String cardName,
    required StatementPeriod period,
    required double amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Hatırlatıcı tarihlerini hesapla
      final reminderDates = _calculateReminderDates(period.dueDate);

      // Her hatırlatıcı için kayıt oluştur
      for (int i = 0; i < reminderDates.length; i++) {
        final reminderDate = reminderDates[i];
        final reminderKey =
            'reminder_${userId}_${cardId}_${period.statementDate.toIso8601String()}_$i';

        final reminderData = {
          'userId': userId,
          'cardId': cardId,
          'cardName': cardName,
          'amount': amount,
          'dueDate': period.dueDate.toIso8601String(),
          'reminderDate': reminderDate.toIso8601String(),
          'periodText': period.periodText,
          'dueDateText': period.dueDateText,
          'type': _getReminderType(i),
          'isShown': false,
        };

        await prefs.setString(reminderKey, jsonEncode(reminderData));
      }

      return true;
    } catch (e) {
      debugPrint('Error setting reminder: $e');
      return false;
    }
  }

  /// Hatırlatıcı tarihlerini hesapla
  static List<DateTime> _calculateReminderDates(DateTime dueDate) {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final reminders = <DateTime>[];

    // 7 gün önceden hatırlat (eğer yeterli zaman varsa)
    if (daysUntilDue > 7) {
      final reminder7Days = dueDate.subtract(const Duration(days: 7));
      reminders.add(
        DateTime(
          reminder7Days.year,
          reminder7Days.month,
          reminder7Days.day,
          10,
          0,
        ),
      ); // 10:00
    }

    // 3 gün önceden hatırlat (eğer yeterli zaman varsa)
    if (daysUntilDue > 3) {
      final reminder3Days = dueDate.subtract(const Duration(days: 3));
      reminders.add(
        DateTime(
          reminder3Days.year,
          reminder3Days.month,
          reminder3Days.day,
          14,
          0,
        ),
      ); // 14:00
    }

    // 1 gün önceden hatırlat (eğer yeterli zaman varsa)
    if (daysUntilDue > 1) {
      final reminder1Day = dueDate.subtract(const Duration(days: 1));
      reminders.add(
        DateTime(
          reminder1Day.year,
          reminder1Day.month,
          reminder1Day.day,
          18,
          0,
        ),
      ); // 18:00
    }

    // Son gün hatırlatıcısı (her zaman ekle)
    final lastDayReminder = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
      0,
    ); // 09:00
    if (lastDayReminder.isAfter(now)) {
      reminders.add(lastDayReminder);
    }

    return reminders;
  }

  /// Hatırlatıcı tipini belirle
  static String _getReminderType(int index) {
    switch (index) {
      case 0:
        return '7_days_before';
      case 1:
        return '3_days_before';
      case 2:
        return '1_day_before';
      case 3:
        return 'due_date';
      default:
        return 'unknown';
    }
  }

  /// Hatırlatıcı mesajını oluştur
  static String getReminderMessage(
    String type,
    String cardName,
    double amount,
    String dueDateText,
  ) {
    switch (type) {
      case '7_days_before':
        return '$cardName kredi kartınızın ekstre ödemesi 7 gün sonra vadesi doluyor. Ödeme tutarı: ${amount.toStringAsFixed(2)} TL';
      case '3_days_before':
        return '$cardName kredi kartınızın ekstre ödemesi 3 gün sonra vadesi doluyor. Ödeme tutarı: ${amount.toStringAsFixed(2)} TL';
      case '1_day_before':
        return '$cardName kredi kartınızın ekstre ödemesi yarın vadesi doluyor! Ödeme tutarı: ${amount.toStringAsFixed(2)} TL';
      case 'due_date':
        return '🚨 SON GÜN! $cardName kredi kartınızın ekstre ödemesi bugün vadesi doluyor! Ödeme tutarı: ${amount.toStringAsFixed(2)} TL';
      default:
        return '$cardName kredi kartı ekstre ödemesi hatırlatıcısı';
    }
  }

  /// Bekleyen hatırlatıcıları kontrol et ve göster
  static Future<List<Map<String, dynamic>>> checkPendingReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final pendingReminders = <Map<String, dynamic>>[];
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) return [];

      // Tüm anahtarları tara
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('reminder_${userId}_'))
          .toList();
      debugPrint(
        '🔔 ReminderService: Found \\${keys.length} reminder keys for user $userId',
      );

      for (final key in keys) {
        final reminderDataString = prefs.getString(key);
        if (reminderDataString != null) {
          try {
            // JSON parsing
            final reminderData =
                jsonDecode(reminderDataString) as Map<String, dynamic>;

            if (reminderData != null && !reminderData['isShown']) {
              final reminderDate = DateTime.parse(reminderData['reminderDate']);
              final dueDate = DateTime.parse(reminderData['dueDate']);

              debugPrint(
                '🔔 Checking reminder: cardId=${reminderData['cardId']}, type=${reminderData['type']}, reminderDate=$reminderDate, dueDate=$dueDate, now=$now',
              );

              // Hatırlatıcı zamanı geldi mi?
              if (now.isAfter(reminderDate) ||
                  now.isAtSameMomentAs(reminderDate)) {
                debugPrint(
                  '🔔 Adding pending reminder: ${reminderData['cardId']} - ${reminderData['type']}',
                );
                pendingReminders.add({
                  'key': key,
                  'data': reminderData,
                  'message': getReminderMessage(
                    reminderData['type'],
                    reminderData['cardName'],
                    reminderData['amount'],
                    reminderData['dueDateText'],
                  ),
                });
              } else {
                debugPrint(
                  '🔔 Reminder not yet due: reminderDate=$reminderDate > now=$now',
                );
              }
            } else {
              debugPrint(
                '🔔 Skipping reminder: isShown=${reminderData?['isShown']}, data exists=${reminderData != null}',
              );
            }
          } catch (e) {
            debugPrint('Error parsing reminder data: $e');
          }
        }
      }

      return pendingReminders;
    } catch (e) {
      debugPrint('Error checking pending reminders: $e');
      return [];
    }
  }

  /// Hatırlatıcıyı gösterildi olarak işaretle
  static Future<void> markReminderAsShown(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderDataString = prefs.getString(key);

      if (reminderDataString != null) {
        final reminderData =
            jsonDecode(reminderDataString) as Map<String, dynamic>;
        reminderData['isShown'] = true;
        await prefs.setString(key, jsonEncode(reminderData));
      }
    } catch (e) {
      debugPrint('Error marking reminder as shown: $e');
    }
  }

  /// Eski hatırlatıcıları temizle
  static Future<void> cleanupOldReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('reminder_'))
          .toList();

      for (final key in keys) {
        final reminderDataString = prefs.getString(key);
        if (reminderDataString != null) {
          final reminderData =
              jsonDecode(reminderDataString) as Map<String, dynamic>;
          final dueDate = DateTime.parse(reminderData['dueDate']);

          // 30 gün önceki hatırlatıcıları sil
          if (now.difference(dueDate).inDays > 30) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old reminders: $e');
    }
  }

  /// Kullanıcı değişiminde o kullanıcıya ait tüm reminder anahtarlarını temizle
  static Future<void> clearAllRemindersForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) return;
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('reminder_${userId}_'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing reminders for user: $e');
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';

/// Service for managing push notifications
///
/// Features:
/// - Periodic notifications every 15 seconds
/// - Expense/Income reminder notifications
/// - Tap to open home screen
/// - Permission handling
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _notificationTimer;
  final int _notificationId = 0;

  /// Initialize notification service
  Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification_q',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    print('Requesting notification permissions for scheduled notifications...');

    // Android 13+ notification permission
    final androidStatus = await Permission.notification.status;
    print('Android notification permission status: $androidStatus');

    if (androidStatus.isDenied) {
      final requestResult = await Permission.notification.request();
      print('Android permission request result: $requestResult');
    }

    // iOS notification permission
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final iosResult = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS permission request result: $iosResult');
    }
  }

  /// Start scheduled notifications (12:00, 18:00, 22:00)
  void startScheduledNotifications() {
    stopScheduledNotifications(); // Stop any existing timers

    _scheduleDailyNotifications();
  }

  /// Stop scheduled notifications
  void stopScheduledNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  /// Schedule daily notifications at specific times
  void _scheduleDailyNotifications() {
    // Schedule for 12:00
    _scheduleNotificationAt(
      14,
      35,
      'Öğle Molası',
      'Günün yarısı geçti, bugünkü harcamalarını kontrol et',
    );

    // Schedule for 18:00
    _scheduleNotificationAt(
      18,
      0,
      'Akşam Kontrolü',
      'Günün harcamalarını kaydetmeyi unutma',
    );

    // Schedule for 22:00
    _scheduleNotificationAt(
      22,
      0,
      'Gün Sonu',
      'Bugünün gelir ve giderlerini not al',
    );
  }

  /// Schedule notification at specific hour and minute
  void _scheduleNotificationAt(
    int hour,
    int minute,
    String title,
    String body,
  ) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final duration = scheduledTime.difference(now);

    Timer(duration, () {
      _showNotification(title: title, body: body, payload: 'home_screen');

      // Schedule next day's notification
      _scheduleNotificationAt(hour, minute, title, body);
    });
  }

  /// Show notification
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check permissions first
    final hasPermission = await Permission.notification.isGranted;
    print('Showing scheduled notification. Has permission: $hasPermission');

    if (!hasPermission) {
      print('No notification permission. Cannot show scheduled notification.');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'qanta_reminders',
      'Qanta Hatırlatmaları',
      channelDescription: 'Harcama ve gelir hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification_q',
      ongoing: false, // Not persistent, can be dismissed
      autoCancel: true, // Can be dismissed by user
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        _notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      print('Scheduled notification shown successfully');
    } catch (e) {
      print('Error showing scheduled notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;

    if (payload == 'home_screen') {
      // Navigate to home screen
      _navigateToHome();
    }
  }

  /// Navigate to home screen
  void _navigateToHome() {
    // Use the global router to navigate
    AppRouter.router.go('/home');
  }

  /// Dispose resources
  void dispose() {
    stopScheduledNotifications();
  }
}

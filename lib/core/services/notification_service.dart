import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';

/// Service for managing push notifications
///
/// Features:
/// - Periodic notifications every 15 minutes
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
  BuildContext? _context;
  int _notificationCounter = 0;

  /// Initialize notification service
  Future<void> initialize() async {
    // Android initialization settings with notification channel
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

    // Create Android notification channel (Android 8+)
    await _createNotificationChannel();

    // Request permissions
    await _requestPermissions();
  }

  /// Create notification channel for Android 8+
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'qanta_reminders', // Channel ID
      'Qanta Reminders', // Channel name
      description: 'Expense and income reminders', // Channel description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
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
      
      if (requestResult.isPermanentlyDenied) {
        print('Notification permission permanently denied. User needs to enable from settings.');
      }
    } else if (androidStatus.isPermanentlyDenied) {
      print('Notification permission permanently denied. Opening app settings...');
      // Optionally open settings
      // await openAppSettings();
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
  
  /// Check if notifications are enabled
  Future<bool> get hasNotificationPermission async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Start scheduled notifications (every 15 minutes)
  void startScheduledNotifications() {
    stopScheduledNotifications(); // Stop any existing timers

    _schedulePeriodicNotifications();
  }

  /// Stop scheduled notifications
  void stopScheduledNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  /// Schedule periodic notifications every 15 minutes
  void _schedulePeriodicNotifications() {
    // Get localization
    final context = _context ?? _getDefaultContext();
    if (context == null) return;
    
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // Array of notification messages
    final notificationMessages = [
      {'title': l10n.lunchBreak, 'body': l10n.lunchBreakMessage},
      {'title': l10n.eveningCheck, 'body': l10n.eveningCheckMessage},
      {'title': l10n.dayEnd, 'body': l10n.dayEndMessage},
      {'title': l10n.qantaReminders, 'body': l10n.reminderChannelDescription},
    ];

    // Start periodic timer for 15 minutes (900 seconds)
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 15),
      (timer) {
        // Get current message (cycle through messages)
        final message = notificationMessages[_notificationCounter % notificationMessages.length];
        
        _showNotification(
          title: message['title']!,
          body: message['body']!,
          payload: 'home_screen',
        );

        // Increment counter
        _notificationCounter++;
      },
    );

    // Show first notification immediately
    final firstMessage = notificationMessages[0];
    _showNotification(
      title: firstMessage['title']!,
      body: firstMessage['body']!,
      payload: 'home_screen',
    );
    _notificationCounter++;
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
      print('No notification permission. Requesting permission...');
      // İzin yoksa iste
      final requestResult = await Permission.notification.request();
      print('Permission request result: $requestResult');
      
      // İzin verilmezse bildirim gönderme
      if (!requestResult.isGranted) {
        print('Permission denied. Cannot show scheduled notification.');
        return;
      }
    }

    // Get localization for notification details
    final context = _context ?? _getDefaultContext();
    final l10n = context != null ? AppLocalizations.of(context) : null;
    
    final androidDetails = AndroidNotificationDetails(
      'qanta_reminders',
      l10n?.qantaReminders ?? 'Qanta Reminders',
      channelDescription: l10n?.reminderChannelDescription ?? 'Expense and income reminders',
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

    final details = NotificationDetails(
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

  /// Set context for localization
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Get default context for fallback
  BuildContext? _getDefaultContext() {
    // Try to get context from router
    try {
      return AppRouter.router.routerDelegate.navigatorKey.currentContext;
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopScheduledNotifications();
  }
}

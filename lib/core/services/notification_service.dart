import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:workmanager/workmanager.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';
import 'remote_config_service.dart';

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

  static const String notificationTaskName = 'qanta_notification_task';
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final int _notificationId = 0;
  BuildContext? _context;

  /// Initialize notification service
  /// 
  /// [requestPermission] - If true, requests notification permission immediately.
  /// If false, only initializes the service without requesting permission.
  /// Default is false (2025 best practice: request permission when user needs it)
  Future<void> initialize({bool requestPermission = false}) async {
    // Android initialization settings with notification channel
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification_q',
    );

    // iOS initialization settings (can't be const because requestPermission is variable)
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: requestPermission, // Only request if explicitly asked
      requestBadgePermission: requestPermission,
      requestSoundPermission: requestPermission,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel (Android 8+)
    await _createNotificationChannel();

    // Request permissions only if explicitly requested
    if (requestPermission) {
      await _requestPermissions();
    }
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
  
  /// Request notification permission with context (2025 best practice)
  /// This should be called when user explicitly needs notifications (e.g., adding subscription)
  Future<bool> requestNotificationPermission(BuildContext? context) async {
    try {
      // Check current status
      final status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        // Open settings if permanently denied
        if (context != null) {
          await openAppSettings();
        }
        return false;
      }
      
      // Request permission
      final result = await Permission.notification.request();
      
      if (result.isGranted) {
        debugPrint('✅ Notification permission granted');
        return true;
      } else {
        debugPrint('❌ Notification permission denied: $result');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Start scheduled notifications using Workmanager (dynamic interval from Remote Config)
  Future<void> startScheduledNotifications() async {
    await stopScheduledNotifications(); // Stop any existing tasks
    
    // Check if notifications are enabled in Remote Config
    bool notificationsEnabled = true;
    int intervalMinutes = 15; // Default fallback
    
    try {
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      
      // Check if notifications are enabled
      notificationsEnabled = remoteConfig.areNotificationsEnabled();
      if (!notificationsEnabled) {
        print('🔕 Notifications disabled in Remote Config - skipping registration');
        return;
      }
      
      // Get interval
      intervalMinutes = remoteConfig.getNotificationIntervalMinutes();
      
      // Android minimum is 15 minutes
      if (intervalMinutes < 15) {
        print('⚠️ Interval $intervalMinutes minutes is too low, using Android minimum: 15 minutes');
        intervalMinutes = 15;
      }
    } catch (e) {
      print('⚠️ Failed to get config from Remote Config, using defaults');
    }
    
    // Register periodic task with Workmanager
    await Workmanager().registerPeriodicTask(
      notificationTaskName,
      notificationTaskName,
      frequency: Duration(minutes: intervalMinutes),
      initialDelay: const Duration(seconds: 10), // Start after 10 seconds
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    
    print('✅ Workmanager notification task registered (every $intervalMinutes minutes)');
  }

  /// Stop scheduled notifications
  Future<void> stopScheduledNotifications() async {
    await Workmanager().cancelByUniqueName(notificationTaskName);
    print('🛑 Workmanager notification task cancelled');
  }

  /// Show notification (callable from background)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Create notification plugin instance
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Initialize notification plugin for background
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification_q');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await notifications.initialize(initSettings);
      
      // Note: Permission check is skipped in background as it may not work
      // Permission should be granted when app is first opened

      const androidDetails = AndroidNotificationDetails(
        'qanta_reminders',
        'Qanta Reminders',
        channelDescription: 'Expense and income reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification_q',
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
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

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      // Silently fail - notification service should not crash the app
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
  Future<void> dispose() async {
    await stopScheduledNotifications();
  }
  
  /// Get notification messages for background task (from Remote Config)
  /// Kullanıcının uygulama diline göre mesajları getirir
  static Future<Map<String, Map<String, String>>> getNotificationMessages() async {
    try {
      // Sistem dilini al (background isolate'de çalışır)
      final systemLocale = _getSystemLocale();
      final languageCode = systemLocale.startsWith('tr') ? 'tr' : 'en';
      
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      await remoteConfig.fetchAndActivate();
      
      final messages = remoteConfig.getNotificationMessages(languageCode);
      
      if (messages.isEmpty) {
        return _getDefaultMessages(languageCode);
      }
      
      return messages;
    } catch (e) {
      print('❌ Error fetching notification messages from Remote Config: $e');
      return _getDefaultMessages('tr'); // Fallback to Turkish
    }
  }
  
  /// Sistem dilini al
  static String _getSystemLocale() {
    try {
      // Platform locale'i al
      return PlatformDispatcher.instance.locale.languageCode;
    } catch (e) {
      return 'tr'; // Default to Turkish
    }
  }
  
  /// Default notification messages (fallback - dile göre)
  static Map<String, Map<String, String>> _getDefaultMessages(String languageCode) {
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

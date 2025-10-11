import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

/// Hızlı not için persistent notification service
class QuickNoteNotificationService {
  static const String _enabledKey = 'quick_note_notification_enabled';
  static const String _noteKey = 'quick_note_content';
  static const int _notificationId = 1001;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Global context for showing dialogs
  static BuildContext? _context;

  /// Set global context for dialog opening
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification_q',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Set up iOS notification categories
    await _setupIOSCategories();
  }

  /// Create Android notification channel
  static Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Main quick note channel
      const quickNoteChannel = AndroidNotificationChannel(
        'quick_note',
        'Hızlı Notlar',
        description: 'Anında not alma için kalıcı bildirim',
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
      );

      await androidPlugin.createNotificationChannel(quickNoteChannel);
    }
  }

  /// Setup iOS notification categories for inline reply
  static Future<void> _setupIOSCategories() async {
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: false,
        sound: false,
      );
    }
  }

  /// Check notification permissions
  static Future<bool> hasPermissions() async {
    // Android 13+ requires notification permission
    final androidStatus = await Permission.notification.status;
    print('Android notification permission status: $androidStatus');

    if (androidStatus.isGranted) {
      return true;
    }

    // For iOS, check with the plugin
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final result = await iosPlugin.checkPermissions();
      print('iOS notification permission status: $result');
      return result?.isEnabled ?? false;
    }

    return false;
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    print('Requesting notification permissions...');

    // Request Android notification permission
    final androidStatus = await Permission.notification.request();
    print('Android permission request result: $androidStatus');

    // Request iOS permissions
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool iosResult = false;
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: false,
        sound: false,
      );
      iosResult = result ?? false;
      print('iOS permission request result: $iosResult');
    }

    final hasPermission = androidStatus.isGranted || iosResult;
    print('Final permission status: $hasPermission');

    return hasPermission;
  }

  /// Handle notification tap and actions
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap (open QuickNotes page)
    if (response.payload == 'open_quick_notes' && _context != null) {
      GoRouter.of(_context!).go('/quick-notes');
    }

    // Handle notification actions
    if (response.actionId == 'add_note' && _context != null) {
      GoRouter.of(_context!).go('/quick-notes');
    }
  }

  /// Save a quick note
  static Future<void> _saveQuickNote(String note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_noteKey, note);

      // Update notification with the new note
      await _showQuickNoteNotification();
    } catch (e) {}
  }

  /// Check if quick note notification is enabled
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable/disable quick note notification
  static Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      // Check and request permissions first
      bool hasPermission = await hasPermissions();
      if (!hasPermission) {
        hasPermission = await requestPermissions();
        if (!hasPermission) {
          // Permission denied
          return false;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await _showQuickNoteNotification();
    } else {
      await _cancelNotification();
    }

    return true;
  }

  /// Get current note content
  static Future<String> getNoteContent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_noteKey) ?? '';
  }

  /// Update note content and notification
  static Future<void> updateNote(String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteKey, content);

    final enabled = await isEnabled();
    if (enabled) {
      await _showQuickNoteNotification();
    }
  }

  /// Show persistent quick note notification
  static Future<void> _showQuickNoteNotification() async {
    // Check permissions first
    final hasPermission = await hasPermissions();
    print('Showing quick note notification. Has permission: $hasPermission');

    if (!hasPermission) {
      print('No notification permission. Cannot show notification.');
      return;
    }

    // Persistent notification - works even when app is closed
    const androidDetails = AndroidNotificationDetails(
      'quick_note',
      'Hızlı Notlar',
      channelDescription: 'Anında not alma için kalıcı bildirim',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Persistent notification
      autoCancel: false,
      showWhen: false,
      usesChronometer: false,
      icon: '@drawable/ic_notification_q',
      actions: [
        AndroidNotificationAction(
          'add_note',
          'Not Ekle',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_notification_q'),
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      const notificationBody = 'Hızlı işlem eklemek için dokunun';

      print('Showing quick note notification:');
      print('Title: Hızlı Notlar');
      print('Body: $notificationBody');

      await _notifications.show(
        _notificationId,
        'Hızlı Notlar',
        notificationBody,
        details,
        payload: 'open_quick_notes',
      );
      print('Quick note notification shown successfully');
    } catch (e) {
      print('Error showing quick note notification: $e');
    }
  }

  /// Update notification when a new note is added
  static Future<void> updateNotificationWithNewNote(String newNote) async {
    // Save the new note
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteKey, newNote);

    // Check if notifications are enabled
    final enabled = await isEnabled();
    if (enabled) {
      // Update the notification
      await _showQuickNoteNotification();
    }
  }

  /// Cancel notification
  static Future<void> _cancelNotification() async {
    await _notifications.cancel(_notificationId);
  }

  /// Clear saved note from SharedPreferences
  static Future<void> _clearSavedNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_noteKey);
    print('Cleared saved note from SharedPreferences');
  }

  /// Start quick note notification if enabled
  static Future<void> startIfEnabled() async {
    final enabled = await isEnabled();
    print('Quick note notification enabled: $enabled');

    if (enabled) {
      // Double check permissions before showing
      final hasPermission = await hasPermissions();
      print('Starting quick note notification. Has permission: $hasPermission');

      if (hasPermission) {
        // Önce mevcut bildirimi temizle
        await _notifications.cancel(_notificationId);
        // Eski not verisini temizle
        await _clearSavedNote();
        await _showQuickNoteNotification();
      } else {
        print('Cannot start quick note notification - no permission');
        // Try to request permission again
        final permissionGranted = await requestPermissions();
        if (permissionGranted) {
          // Önce mevcut bildirimi temizle
          await _notifications.cancel(_notificationId);
          // Eski not verisini temizle
          await _clearSavedNote();
          await _showQuickNoteNotification();
        }
      }
    }
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../services/services_v2.dart';
import '../../shared/models/models_v2.dart';
import '../../shared/widgets/quick_note_dialog.dart';

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
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification_q');
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
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
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
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
    if (await Permission.notification.isGranted) {
      return true;
    }
    
    // For iOS, check with the plugin
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        );
    
    return result ?? false;
  }
  
  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    // Request Android notification permission
    final androidStatus = await Permission.notification.request();
    
    // Request iOS permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        );
    
    return androidStatus.isGranted || (iosResult ?? false);
  }
  
  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap (open QuickNotes page)
    if (response.payload == 'open_quick_notes' && _context != null) {
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
    } catch (e) {
    }
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
    final prefs = await SharedPreferences.getInstance();
    final savedNote = prefs.getString(_noteKey) ?? '';
    
    // Simple notification - tap to open QuickNotes page
    const androidDetails = AndroidNotificationDetails(
      'quick_note',
      'Hızlı Notlar',
      channelDescription: 'Anında not alma için kalıcı bildirim',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Persistent notification
      autoCancel: false,
      icon: '@drawable/ic_notification_q',
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
    
    await _notifications.show(
      _notificationId,
      'Hızlı Notlar',
      savedNote.isEmpty 
        ? 'Dokunarak not ekleyin' 
        : 'Son not: $savedNote',
      details,
      payload: 'open_quick_notes',
    );
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
  
  /// Start quick note notification if enabled
  static Future<void> startIfEnabled() async {
    final enabled = await isEnabled();
    if (enabled) {
      await _showQuickNoteNotification();
    }
  }
} 
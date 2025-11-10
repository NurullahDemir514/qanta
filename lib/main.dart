import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme_provider.dart';
import 'core/providers/unified_provider_v2.dart';
import 'core/providers/profile_provider.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/services/reminder_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'routes/app_router.dart';
import 'modules/insights/providers/statistics_provider.dart';
import 'modules/insights/providers/ai_insights_provider.dart';
import 'modules/stocks/providers/stock_provider.dart';
import 'modules/stocks/repositories/firebase_stock_repository.dart';
import 'modules/stocks/services/yandex_finance_api_service.dart';
import 'modules/stocks/services/stock_transaction_service.dart';
import 'modules/advertisement/providers/advertisement_provider.dart';
import 'core/providers/statement_provider.dart';
import 'core/providers/savings_provider.dart';
import 'core/providers/recurring_transaction_provider.dart';
import 'modules/profile/providers/amazon_reward_provider.dart';
import 'modules/profile/providers/point_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/firebase_client.dart';
import 'core/services/network_service.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'core/services/premium_service.dart';
import 'core/services/rewarded_ad_service.dart';
import 'core/services/consent_service.dart';
import 'core/services/bank_service.dart';
import 'core/services/recurring_transaction_service.dart';
import 'core/services/cache_cleanup_service.dart';
import 'shared/widgets/no_internet_screen.dart';

/// Background callback for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Handle recurring transaction execution
    if (task == 'execute_recurring_transactions') {
      try {
        // Import services at top level or use full paths
        await RecurringTransactionService.executeRecurringTransactions();
        debugPrint('✅ Recurring transaction task completed');
        return Future.value(true);
      } catch (e) {
        debugPrint('❌ Error in recurring transaction task: $e');
        return Future.value(false);
      }
    }
    
    // Handle notification task
    try {
      final now = DateTime.now();
      
      // 1️⃣ Akıllı zamanlama kontrolü - shouldSendNotification içinde tüm kontroller var
      // SmartNotificationScheduler'ı import etmeliyiz
      final prefs = await SharedPreferences.getInstance();
      
      // Hafta içi / hafta sonu kontrolü
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      final slots = isWeekend ? [11, 20] : [9, 12, 15, 19, 21];
      
      // Şu anki zaman dilimini bul
      final currentSlot = _findCurrentSlot(now.hour, now.minute, slots);
      if (currentSlot == null) {
        debugPrint('⏰ Not in notification time slot (${now.hour}:${now.minute.toString().padLeft(2, '0')})');
        return Future.value(true);
      }
      
      // Bu zaman diliminde bildirim gönderildi mi kontrol et
      final lastSlot = prefs.getInt('last_notification_slot');
      final lastDate = prefs.getString('last_notification_date');
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      if (lastDate == today && lastSlot == currentSlot) {
        debugPrint('📭 Notification already sent for slot $currentSlot today');
        return Future.value(true);
      }
      
      // Günlük limit kontrolü
      int dailyCount = 0;
      if (lastDate == today) {
        dailyCount = prefs.getInt('daily_notification_count') ?? 0;
        final maxDailyNotifications = isWeekend ? 2 : 5;
        if (dailyCount >= maxDailyNotifications) {
          debugPrint('📊 Daily notification limit reached ($dailyCount/$maxDailyNotifications)');
          return Future.value(true);
        }
      }
      
      // Son bildirimden geçen süre kontrolü (minimum 2 saat)
      final lastNotificationStr = prefs.getString('last_notification_time');
      if (lastNotificationStr != null) {
        final lastNotification = DateTime.parse(lastNotificationStr);
        final hoursSince = now.difference(lastNotification).inHours;
        if (hoursSince < 2) {
          debugPrint('⏱️ Too soon since last notification ($hoursSince hours)');
          return Future.value(true);
        }
      }
      
      // 2️⃣ Slot'a göre mesaj anahtarını belirle
      String messageKey;
      if (isWeekend) {
        messageKey = currentSlot == 11 ? 'weekend_morning' : 'weekend_evening';
      } else {
        switch (currentSlot) {
          case 9: messageKey = 'morning'; break;
          case 12: messageKey = 'lunch'; break;
          case 15: messageKey = 'afternoon'; break;
          case 19: messageKey = 'evening'; break;
          case 21: messageKey = 'night'; break;
          default: messageKey = 'general';
        }
      }
      
      // 3️⃣ Mesajları al
      final messages = await NotificationService.getNotificationMessages();
      final selectedMessage = messages[messageKey] ?? messages['general']!;
      
      // 4️⃣ Bildirim göster
      await NotificationService.showNotification(
        title: selectedMessage['title']!,
        body: selectedMessage['body']!,
        payload: 'home_screen',
      );
      
      // 5️⃣ İstatistikleri kaydet
      await prefs.setString('last_notification_time', now.toIso8601String());
      await prefs.setString('last_notification_message', selectedMessage['title']!);
      await prefs.setInt('last_notification_slot', currentSlot);
      
      if (lastDate != today) {
        await prefs.setString('last_notification_date', today);
        await prefs.setInt('daily_notification_count', 1);
      } else {
        await prefs.setInt('daily_notification_count', dailyCount + 1);
      }
      
      debugPrint('✅ Notification sent: ${selectedMessage['title']} at ${now.hour}:${now.minute} (Slot: $currentSlot, ${isWeekend ? 'Weekend' : 'Weekday'})');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Error in notification task: $e');
      return Future.value(false);
    }
  });
}

/// Şu anki saatin hangi zaman dilimine düştüğünü bul
int? _findCurrentSlot(int hour, int minute, List<int> slots) {
  for (final slot in slots) {
    final slotStart = slot * 60 - 30; // 30 dakika önce
    final slotEnd = slot * 60 + 45;   // 45 dakika sonra
    final currentMinutes = hour * 60 + minute;
    
    if (currentMinutes >= slotStart && currentMinutes <= slotEnd) {
      return slot;
    }
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI Overlay ayarları - Android 12+ için
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Edge-to-edge mode with better compatibility
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Set preferred orientations for better screen compatibility
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  try {
    await FirebaseManager.init();
  } catch (e) {
    // Continue without Firebase for now
  }

  // 🧹 Cache Cleanup: Prevent app size growth by cleaning caches on startup
  // This runs in the background to avoid slowing app launch
  try {
    final cacheCleanup = CacheCleanupService.instance;
    // Run cleanup asynchronously without blocking app startup
    cacheCleanup.performStartupCleanup().catchError((e) {
      debugPrint('⚠️ Cache cleanup error (non-blocking): $e');
    });
  } catch (e) {
    debugPrint('⚠️ Cache cleanup service not available: $e');
  }

  // 🔐 STEP 1: Initialize Consent (UMP SDK) - MUST be before AdMob
  try {
    await ConsentService().initialize();
    debugPrint('✅ Consent Service initialized');
  } catch (e) {
    debugPrint('❌ Consent Service initialization failed: $e');
  }

  // 🎯 STEP 2: Initialize Google Mobile Ads - AFTER Consent
  try {
    await MobileAds.instance.initialize();

    // PRODUCTION: No test devices (uncomment below for testing)
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['189BB15FEA642FC3E45EED2AFB6E499B']),
    // );
    debugPrint('✅ Google Mobile Ads initialized');
  } catch (e) {
    debugPrint('❌ Google Mobile Ads initialization failed: $e');
    // Continue without ads for now
  }


  // Initialize Reminder Service
  try {
    await ReminderService.cleanupOldReminders();
  } catch (e) {}

  // Initialize Remote Config for dynamic notification messages
  try {
    final remoteConfig = RemoteConfigService();
    await remoteConfig.initialize();
    await remoteConfig.fetchAndActivate();
    debugPrint('✅ Remote Config initialized');
  } catch (e) {
    debugPrint('❌ Remote Config initialization failed: $e');
  }

  // Initialize Bank Service for dynamic bank management
  try {
    final bankService = BankService();
    await bankService.initialize();
    debugPrint('✅ Bank Service initialized');
  } catch (e) {
    debugPrint('❌ Bank Service initialization failed: $e');
  }

  // Initialize Workmanager for background notifications
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // Debug mode for testing
    );
    
    // Register recurring transaction execution task (runs daily)
    await Workmanager().registerPeriodicTask(
      'execute_recurring_transactions',
      'execute_recurring_transactions',
      frequency: const Duration(hours: 24), // Check once per day
      constraints: Constraints(
        networkType: NetworkType.notRequired, // Can run offline
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    
    // 🧪 TEST: Immediate task for testing (only in debug mode)
    if (kDebugMode) {
      await Workmanager().registerOneOffTask(
        'test_recurring_transactions',
        'execute_recurring_transactions',
        initialDelay: const Duration(seconds: 5), // Run after 5 seconds
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
      debugPrint('🧪 Test task registered - will run in 5 seconds');
    }
    
    debugPrint('✅ Workmanager initialized with recurring transaction task');
  } catch (e) {
    debugPrint('❌ Workmanager initialization failed: $e');
  }

  // Initialize Notification Service (without requesting permission - 2025 best practice)
  // Permission will be requested when user adds subscription (context-aware)
  try {
    await NotificationService().initialize(requestPermission: false);
    await NotificationService().startScheduledNotifications();
    debugPrint('✅ Notification service initialized (permission will be requested on-demand)');
  } catch (e) {
    debugPrint('❌ Notification service initialization failed: $e');
  }

  // Initialize Premium Service
  try {
    await PremiumService().initialize();
    
    // 🔔 Setup Premium Status Change Listener
    // When user subscribes/unsubscribes, reload AI limits immediately
    PremiumService().onPremiumStatusChanged = () async {
      debugPrint('🔔 main.dart: Premium status changed, reloading AI limits...');
      try {
        await UnifiedProviderV2.instance.loadAIUsage();
        debugPrint('✅ main.dart: AI limits reloaded successfully');
      } catch (e) {
        debugPrint('❌ main.dart: Failed to reload AI limits: $e');
      }
    };
  } catch (e) {
    debugPrint('Premium service initialization failed: $e');
  }

  // Initialize Rewarded Ad Service
  try {
    await RewardedAdService().initialize();
  } catch (e) {
    debugPrint('Rewarded Ad service initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NetworkService()),
        ChangeNotifierProvider(create: (context) => StatementProvider.instance),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider.value(value: PremiumService()),
        ChangeNotifierProvider.value(value: RewardedAdService()),

        // QANTA v2 provider (main provider)
        ChangeNotifierProvider(
          create: (context) {
            final provider = UnifiedProviderV2.instance;
            // ✅ GEREKSIZ YÜKLEME ENGELLEME: Veriler splash'te yüklenecek
            // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   provider.loadAllData();
            // });
            return provider;
          },
        ),

        // Statistics provider
        ChangeNotifierProxyProvider<UnifiedProviderV2, StatisticsProvider>(
          create: (context) => StatisticsProvider(UnifiedProviderV2.instance),
          update: (context, unifiedProvider, statisticsProvider) =>
              statisticsProvider ?? StatisticsProvider(unifiedProvider),
        ),

        // AI Insights provider
        ChangeNotifierProxyProvider<UnifiedProviderV2, AIInsightsProvider>(
          create: (context) => AIInsightsProvider(UnifiedProviderV2.instance),
          update: (context, unifiedProvider, aiProvider) =>
              aiProvider ?? AIInsightsProvider(unifiedProvider),
        ),

        // Stock provider
        ChangeNotifierProvider(
          create: (context) {
            final stockProvider = StockProvider(
              stockRepository: FirebaseStockRepository(),
              stockApiService: YandexFinanceApiService(),
              transactionService: StockTransactionService(),
            );

            // StockProvider'ı UnifiedProviderV2'ye set et
            UnifiedProviderV2.instance.setStockProvider(stockProvider);

            // StockProvider'ı UnifiedProviderV2'ye set et (loadAllData içinde kullanılacak)

            return stockProvider;
          },
        ),

        // Advertisement provider
        ChangeNotifierProvider(create: (context) => AdvertisementProvider()),

        // Savings provider
        ChangeNotifierProvider(create: (context) => SavingsProvider()),
        ChangeNotifierProvider.value(value: RecurringTransactionProvider()),
        
        // Amazon Reward Provider
        ChangeNotifierProvider.value(value: AmazonRewardProvider()),
        ChangeNotifierProvider.value(value: PointProvider()),

        // Legacy providers disabled to prevent duplicate balance updates
        // TODO: Remove these completely after full migration to V2
        // ChangeNotifierProvider(create: (context) => CashAccountProvider.instance),
        // ChangeNotifierProvider(create: (context) => DebitCardProvider.instance),
        // ChangeNotifierProvider(create: (context) => CreditCardProvider.instance),
        // ChangeNotifierProvider(create: (context) => UnifiedCardProvider()),
      ],
      child: Consumer2<ThemeProvider, NetworkService>(
        builder: (context, themeProvider, networkService, child) {
          return ScreenUtilInit(
            designSize: const Size(375, 812), // iPhone X design size
            minTextAdapt: true,
            splitScreenMode: true,
            useInheritedMediaQuery: true,
            builder: (context, child) {
              return AppLifecycleManager(
                child: MaterialApp.router(
                  title: 'Qanta',
                  debugShowCheckedModeBanner: false,

                  // Theme configuration
                  theme: LightTheme.theme,
                  darkTheme: DarkTheme.theme,
                  themeMode: themeProvider.themeMode,

                  // Localization configuration
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('tr'), // Turkish (default)
                    Locale('en'), // English
                    Locale('de'), // German
                    Locale('hi'), // Hindi
                  ],
                  locale: themeProvider.locale, // Use locale from provider
                  
                  // Router configuration
                  routerConfig: AppRouter.router,
                  
                  // Network check builder
                  builder: (context, child) {
                    if (!networkService.isConnected) {
                      return const NoInternetScreen();
                    }
                    return child ?? const SizedBox.shrink();
                  },
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

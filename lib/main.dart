import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme_provider.dart';
import 'core/providers/unified_provider_v2.dart';
import 'core/providers/profile_provider.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/services/reminder_service.dart';
import 'core/services/notification_service.dart';
import 'routes/app_router.dart';
import 'modules/insights/providers/statistics_provider.dart';
import 'modules/stocks/providers/stock_provider.dart';
import 'modules/stocks/repositories/firebase_stock_repository.dart';
import 'modules/stocks/services/yandex_finance_api_service.dart';
import 'modules/stocks/services/stock_transaction_service.dart';
import 'modules/advertisement/providers/advertisement_provider.dart';
import 'core/providers/statement_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/firebase_client.dart';
import 'core/services/network_service.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'core/services/premium_service.dart';
import 'shared/widgets/no_internet_screen.dart';

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

  // Initialize Google Mobile Ads
  try {
    await MobileAds.instance.initialize();

    // Test device ID'sini ayarla
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['189BB15FEA642FC3E45EED2AFB6E499B']),
    );
  } catch (e) {
    // Continue without ads for now
  }


  // Initialize Reminder Service
  try {
    await ReminderService.cleanupOldReminders();
  } catch (e) {}

  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    NotificationService().startScheduledNotifications();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  // Initialize Premium Service
  try {
    await PremiumService().initialize();
  } catch (e) {
    debugPrint('Premium service initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NetworkService()),
        ChangeNotifierProvider(create: (context) => StatementProvider.instance),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider.value(value: PremiumService()),

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

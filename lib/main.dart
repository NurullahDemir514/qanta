import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme_provider.dart';
import 'core/providers/cash_account_provider.dart';
import 'core/providers/debit_card_provider.dart';
import 'core/providers/credit_card_provider.dart';
import 'core/providers/unified_card_provider.dart';
import 'core/providers/unified_provider_v2.dart';
import 'core/providers/profile_provider.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/services/quick_note_notification_service.dart';
import 'core/services/reminder_service.dart';
import 'routes/app_router.dart';
import 'modules/insights/providers/statistics_provider.dart';
import 'modules/stocks/providers/stock_provider.dart';
import 'modules/stocks/repositories/firebase_stock_repository.dart';
import 'modules/stocks/services/yandex_finance_api_service.dart';
import 'modules/stocks/services/stock_transaction_service.dart';
import 'modules/advertisement/providers/advertisement_provider.dart';
import 'core/providers/statement_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/firebase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      RequestConfiguration(
        testDeviceIds: ['189BB15FEA642FC3E45EED2AFB6E499B'],
      ),
    );
  } catch (e) {
    // Continue without ads for now
  }

  // Initialize Quick Note Notification Service
  try {
    await QuickNoteNotificationService.initialize();
    await QuickNoteNotificationService.startIfEnabled();
  } catch (e) {
  }

  // Initialize Reminder Service
  try {
    await ReminderService.cleanupOldReminders();
  } catch (e) {
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StatementProvider.instance),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),

        // QANTA v2 provider (main provider)
        ChangeNotifierProvider(
          create: (context) {
            final provider = UnifiedProviderV2.instance;
            // Uygulama açılırken tüm verileri yükle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.loadAllData();
            });
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
        ChangeNotifierProvider(
          create: (context) => AdvertisementProvider(),
        ),

        // Legacy providers disabled to prevent duplicate balance updates
        // TODO: Remove these completely after full migration to V2
        // ChangeNotifierProvider(create: (context) => CashAccountProvider.instance),
        // ChangeNotifierProvider(create: (context) => DebitCardProvider.instance),
        // ChangeNotifierProvider(create: (context) => CreditCardProvider.instance),
        // ChangeNotifierProvider(create: (context) => UnifiedCardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
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
          );
        },
      ),
    ),
  );
}

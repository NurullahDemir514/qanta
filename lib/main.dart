import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
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
import 'core/supabase_client.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseManager.init();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    // Continue without Supabase for now
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        
        // Legacy providers (for backward compatibility)
        ChangeNotifierProvider(create: (context) => CashAccountProvider.instance),
        ChangeNotifierProvider(create: (context) => DebitCardProvider.instance),
        ChangeNotifierProvider(create: (context) => CreditCardProvider.instance),
        ChangeNotifierProvider(create: (context) => UnifiedCardProvider()),
        
        // QANTA v2 provider
        ChangeNotifierProvider(create: (context) => UnifiedProviderV2.instance),
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
    );
  }
}

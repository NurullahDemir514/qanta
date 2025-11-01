import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/utils/currency_utils.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _currencyKey = 'currency';
  
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en'); // Default to English for global audience
  bool _onboardingCompleted = false;
  Currency _currency = Currency.TRY; // Default to Turkish Lira
  
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get onboardingCompleted => _onboardingCompleted;
  Currency get currency => _currency;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isTurkish => _locale.languageCode == 'tr';
  bool get isGerman => _locale.languageCode == 'de';

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    
    // Load locale
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(localeCode);
    
    // Load currency
    final currencyCode = prefs.getString(_currencyKey) ?? 'TRY';
    _currency = Currency.fromCode(currencyCode);
    
    // Load onboarding completion
    _onboardingCompleted = prefs.getBool(_onboardingKey) ?? false;
    
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    
    notifyListeners();
  }

  Future<void> setCurrency(Currency currency) async {
    if (_currency == currency) return;
    
    _currency = currency;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
    
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'tr' 
        ? const Locale('en') 
        : const Locale('tr');
    
    await setLocale(newLocale);
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    
    notifyListeners();
  }

  // Helper method to format amounts
  String formatAmount(double amount) {
    return CurrencyUtils.formatAmount(amount, _currency);
  }

  String formatAmountCompact(double amount) {
    return CurrencyUtils.formatAmountCompact(amount, _currency);
  }
} 
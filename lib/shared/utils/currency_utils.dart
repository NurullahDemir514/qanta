import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum Currency {
  TRY('TRY', '₺', 'tr_TR'),
  USD('USD', '\$', 'en_US'),
  EUR('EUR', '€', 'de_DE'),
  GBP('GBP', '£', 'en_GB'),
  JPY('JPY', '¥', 'ja_JP'),
  CHF('CHF', 'CHF', 'de_CH'),
  CAD('CAD', 'CA\$', 'en_CA'),
  AUD('AUD', 'A\$', 'en_AU'),
  INR('INR', '₹', 'en_IN'),
  AED('AED', 'AED', 'en_AE'),
  SAR('SAR', 'SAR', 'en_SA'),
  BDT('BDT', '৳', 'bn_BD'),
  PKR('PKR', '₨', 'ur_PK'),
  SDG('SDG', 'SDG', 'ar_SD');

  const Currency(this.code, this.symbol, this.locale);

  final String code;
  final String symbol;
  final String locale;

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => Currency.TRY,
    );
  }
}

class CurrencyUtils {
  // Para birimi sembolleri için font fallback desteği
  static const List<String> _currencyFontFallbacks = [
    'Roboto',
    'SF Pro Text',
    'SF Pro Display', 
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static String formatAmount(double amount, Currency currency) {
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatAmountWithoutSymbol(double amount, Currency currency) {
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  static String formatAmountCompact(double amount, Currency currency) {
    final formatter = NumberFormat.compactCurrency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  /// Format amount with letter format after 6 digits (1.000.000+)
  /// Examples: 999.999 -> ₺999.999,00 | 1.000.000 -> ₺1M | 1.500.000 -> ₺1,5M | 1.000.000.000 -> ₺1B
  static String formatAmountWithLetterFormat(double amount, Currency currency) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final sign = isNegative ? '-' : '';
    final symbol = currency.symbol;
    
    // 6 basamaktan az ise normal format kullan
    if (absAmount < 1000000) {
      return formatAmount(amount, currency);
    }
    
    // 1.000.000.000 ve üstü (B - Milyar / Billion)
    if (absAmount >= 1000000000) {
      final billions = absAmount / 1000000000;
      // 1 ondalık basamak, gereksiz sıfırları kaldır
      final formatted = billions.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      // Locale'e göre ondalık ayracı
      final decimalSep = getDecimalSeparator(currency.locale);
      final normalized = formatted.replaceAll('.', decimalSep);
      // Türkçe'de Milyar için B kullan (M ile karışmasın)
      return '$sign$symbol$normalized B';
    }
    
    // 1.000.000 ve üstü (M - Milyon / Million)
    if (absAmount >= 1000000) {
      final millions = absAmount / 1000000;
      // 1 ondalık basamak, gereksiz sıfırları kaldır
      final formatted = millions.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      // Locale'e göre ondalık ayracı
      final decimalSep = getDecimalSeparator(currency.locale);
      final normalized = formatted.replaceAll('.', decimalSep);
      return '$sign$symbol$normalized M';
    }
    
    // Fallback (olmayacak ama yine de)
    return formatAmount(amount, currency);
  }

  static String getSymbolForCurrency(Currency currency) {
    return currency.symbol;
  }

  // Para birimi sembolü için güvenli TextStyle oluşturur
  static TextStyle getCurrencyTextStyle({
    required TextStyle baseStyle,
    Currency? currency,
  }) {
    return baseStyle.copyWith(
      fontFamilyFallback: _currencyFontFallbacks,
      // Para birimi sembolleri için özel karakter desteği
      fontFeatures: const [
        FontFeature.tabularFigures(),
        FontFeature.liningFigures(),
      ],
    );
  }

  // Para birimi ile birlikte güvenli Text widget'ı oluşturur
  static Widget buildCurrencyText(
    String text, {
    required TextStyle style,
    Currency? currency,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: getCurrencyTextStyle(
        baseStyle: style,
        currency: currency,
      ),
      textAlign: textAlign,
      // Para birimi sembolleri için overflow koruması
      overflow: TextOverflow.ellipsis,
    );
  }

  // Para birimi miktarı için özel formatlama
  static Widget buildAmountText(
    double amount, {
    required Currency currency,
    required TextStyle style,
    bool showSymbol = true,
    TextAlign? textAlign,
  }) {
    final formattedAmount = showSymbol 
        ? formatAmount(amount, currency)
        : formatAmountWithoutSymbol(amount, currency);
    
    return buildCurrencyText(
      formattedAmount,
      style: style,
      currency: currency,
      textAlign: textAlign,
    );
  }

  static String getDisplayName(Currency currency, String languageCode) {
    switch (currency) {
      case Currency.TRY:
        return languageCode == 'tr' ? 'Türk Lirası (₺)' : 'Turkish Lira (₺)';
      case Currency.USD:
        return languageCode == 'tr' ? 'Amerikan Doları (\$)' : 'US Dollar (\$)';
      case Currency.EUR:
        return 'Euro (€)';
      case Currency.GBP:
        return languageCode == 'tr' ? 'İngiliz Sterlini (£)' : 'British Pound (£)';
      case Currency.JPY:
        return languageCode == 'tr' ? 'Japon Yeni (¥)' : 'Japanese Yen (¥)';
      case Currency.CHF:
        return languageCode == 'tr' ? 'İsviçre Frangı (CHF)' : 'Swiss Franc (CHF)';
      case Currency.CAD:
        return languageCode == 'tr' ? 'Kanada Doları (CA\$)' : 'Canadian Dollar (CA\$)';
      case Currency.AUD:
        return languageCode == 'tr' ? 'Avustralya Doları (A\$)' : 'Australian Dollar (A\$)';
      case Currency.INR:
        return languageCode == 'tr' ? 'Hindistan Rupisi (₹)' : 'Indian Rupee (₹)';
      case Currency.AED:
        return languageCode == 'tr' ? 'BAE Dirhemi (AED)' : 'UAE Dirham (AED)';
      case Currency.SAR:
        return languageCode == 'tr' ? 'Suudi Riyali (SAR)' : 'Saudi Riyal (SAR)';
      case Currency.BDT:
        return languageCode == 'tr' ? 'Bangladeş Takası (৳)' : 'Bangladeshi Taka (৳)';
      case Currency.PKR:
        return languageCode == 'tr' ? 'Pakistan Rupisi (₨)' : 'Pakistani Rupee (₨)';
      case Currency.SDG:
        return languageCode == 'tr' ? 'Sudan Lirası (SDG)' : 'Sudanese Pound (SDG)';
    }
  }

  // Para birimi sembolünün doğru görüntülenip görüntülenmediğini kontrol eder
  static bool isCurrencySymbolSupported(Currency currency) {
    // Bu metod gelecekte font desteği kontrolü için kullanılabilir
    return true; // Şimdilik tüm semboller destekleniyor varsayılıyor
  }

  /// Para biriminden ilgili ülke kodlarını getir
  /// Bu kodlar bankaların supportedCountries ile eşleşmesi için kullanılır
  static List<String> getCountryCodesForCurrency(Currency currency) {
    switch (currency) {
      case Currency.TRY:
        return ['TR']; // Türkiye
      case Currency.USD:
        return ['US']; // Amerika
      case Currency.EUR:
        return ['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'PT', 'FI', 'GR', 'IE', 'LU']; // Eurozone
      case Currency.GBP:
        return ['GB']; // İngiltere
      case Currency.JPY:
        return ['JP']; // Japonya
      case Currency.CHF:
        return ['CH']; // İsviçre
      case Currency.CAD:
        return ['CA']; // Kanada
      case Currency.AUD:
        return ['AU']; // Avustralya
      case Currency.INR:
        return ['IN']; // Hindistan
      case Currency.AED:
        return ['AE']; // BAE
      case Currency.SAR:
        return ['SA']; // Suudi Arabistan
      case Currency.BDT:
        return ['BD']; // Bangladeş
      case Currency.PKR:
        return ['PK']; // Pakistan
      case Currency.SDG:
        return ['SD']; // Sudan
    }
  }

  // Alternatif para birimi gösterimi (sembol desteklenmiyorsa)
  static String getFallbackCurrencyDisplay(Currency currency) {
    switch (currency) {
      case Currency.TRY:
        return '₺';
      case Currency.USD:
        return 'USD';
      case Currency.EUR:
        return 'EUR';
      case Currency.GBP:
        return 'GBP';
      case Currency.JPY:
        return 'JPY';
      case Currency.CHF:
        return 'CHF';
      case Currency.CAD:
        return 'CAD';
      case Currency.AUD:
        return 'AUD';
      case Currency.INR:
        return 'INR';
      case Currency.AED:
        return 'AED';
      case Currency.SAR:
        return 'SAR';
      case Currency.BDT:
        return 'BDT';
      case Currency.PKR:
        return 'PKR';
      case Currency.SDG:
        return 'SDG';
    }
  }

  /// Get thousands separator for a locale
  static String getThousandsSeparator(String locale) {
    // Turkish and most European locales use dot for thousands
    if (locale.startsWith('tr') || 
        locale.startsWith('de') || 
        locale.startsWith('es') || 
        locale.startsWith('it') ||
        locale.startsWith('fr')) {
      return '.';
    }
    // US and UK use comma
    return ',';
  }

  /// Get decimal separator for a locale
  static String getDecimalSeparator(String locale) {
    // Turkish and most European locales use comma for decimals
    if (locale.startsWith('tr') || 
        locale.startsWith('de') || 
        locale.startsWith('es') || 
        locale.startsWith('it') ||
        locale.startsWith('fr')) {
      return ',';
    }
    // US and UK use dot
    return '.';
  }

  /// Add thousands separators to an integer part string based on locale
  /// Only formats the integer part (no decimal separator handling)
  static String addThousandsSeparators(String integerPart, String locale) {
    if (integerPart.isEmpty) return integerPart;
    
    final thousandsSeparator = getThousandsSeparator(locale);
    
    // Reverse the string, add separators every 3 digits from right to left
    final reversed = integerPart.split('').reversed.join('');
    String withSeparators = '';
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withSeparators += thousandsSeparator;
      }
      withSeparators += reversed[i];
    }
    return withSeparators.split('').reversed.join('');
  }
} 
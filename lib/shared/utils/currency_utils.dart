import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum Currency {
  TRY('TRY', '₺', 'tr_TR'),
  USD('USD', '\$', 'en_US'),
  EUR('EUR', '€', 'de_DE'),
  GBP('GBP', '£', 'en_GB');

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
    }
  }

  // Para birimi sembolünün doğru görüntülenip görüntülenmediğini kontrol eder
  static bool isCurrencySymbolSupported(Currency currency) {
    // Bu metod gelecekte font desteği kontrolü için kullanılabilir
    return true; // Şimdilik tüm semboller destekleniyor varsayılıyor
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
    }
  }
} 
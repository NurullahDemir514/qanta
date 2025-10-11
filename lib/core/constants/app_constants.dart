import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Qanta';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Personal Finance Management App';

  // Colors
  static const Color primaryColor = Color(0xFF6D6D70);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color primaryLightColor = Color(0xFFF7F8FA);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC300);
  static const Color errorColor = Color(0xFFFF4C4C);
  static const Color infoColor = Color(0xFF00C2FF);
  static const Color neutralColor = Color(0xFFA0A0A0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 50.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Financial Constants
  static const List<String> supportedCurrencies = [
    'TRY',
    'USD',
    'EUR',
    'GBP',
    'JPY',
  ];

  static const Map<String, String> currencySymbols = {
    'TRY': '₺',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };

  static const List<String> supportedLanguages = ['tr', 'en'];

  // Transaction Limits
  static const double maxTransactionAmount = 1000000.0;
  static const double minTransactionAmount = 0.01;

  // UI Constants
  static const double maxContentWidth = 600.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Card Dimensions
  static const double cardWidth = 320.0;
  static const double cardHeight = 180.0;
  static const double cardAspectRatio = 16 / 9; // 16:9 ratio
  static const double miniCardWidth = 200.0;
  static const double miniCardHeight = 125.0;
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 18.0;
  
  // Card Section
  static const double cardSectionHeight = cardHeight;
  static const double cardViewportFraction = 0.85;
  static const double cardMarginHorizontal = 8.0;
  
  // Card Elements
  static const double cardChipSize = 32.0;
  static const double cardChipRadius = 6.0;
  static const double cardIconSize = 16.0;
  static const double cardContactlessIconSize = 20.0;

  // Card Design Templates
  static const Map<String, Map<String, dynamic>> cardDesigns = {
    'debit': {
      'gradientColors': [
        Color(0xFF1a1a1a),
        Color(0xFF2d2d2d),
        Color(0xFF1a1a1a),
      ],
      'accentColor': Color(0xFF6D6D70),
    },
    'credit': {
      'gradientColors': [
        Color(0xFF7C2D12),
        Color(0xFFDC2626),
        Color(0xFF7C2D12),
      ],
      'accentColor': Color(0xFFEF4444),
    },
    'cash': {
      'gradientColors': [
        Color(0xFF064E3B),
        Color(0xFF059669),
        Color(0xFF6D6D70),
        Color(0xFF4CAF50),
      ],
      'accentColor': Color(0xFF6D6D70),
    },
  };

  static const Map<String, Map<String, dynamic>> bankDesigns = {
  // Garanti BBVA - Koyu mavi & yeşilimsi geçiş
  'garanti': {
    'name': 'Garanti BBVA',
    'gradientColors': [
      Color(0xFF006A4D), // koyu yeşil
      Color(0xFF00A79D), // açık camgöbeği
      Color(0xFF50C878), // zümrüt yeşili
    ],
    'accentColor': Color(0xFF00A79D),
  },

  // İş Bankası - Lacivert tonları
  'isbank': {
    'name': 'İş Bankası',
    'gradientColors': [
      Color(0xFF0B3C61), // lacivert
      Color(0xFF1565C0), // mavi
      Color(0xFF2196F3), // açık mavi
    ],
    'accentColor': Color(0xFF1565C0),
  },

  // Akbank - Kırmızı tonlar
  'akbank': {
    'name': 'Akbank',
    'gradientColors': [
      Color(0xFFB71C1C), // koyu kırmızı
      Color(0xFFD32F2F), // klasik kırmızı
      Color(0xFFEF5350), // açık kırmızı
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  // Ziraat Bankası - Kırmızıya yakın yeşil/mercan karışımı
  'ziraat': {
    'name': 'Ziraat Bankası',
    'gradientColors': [
      Color(0xFFBA0C2F), // ziraat kırmızısı
      Color(0xFFD32F2F),
      Color(0xFFF44336),
    ],
    'accentColor': Color(0xFFBA0C2F),
  },

  // VakıfBank - Sarı-siyah teması
  'vakifbank': {
    'name': 'VakıfBank',
    'gradientColors': [
      Color(0xFFFFC107), // amber sarısı
      Color(0xFFFFA000), // koyu sarı
      Color(0xFFF57C00), // turuncumsu
    ],
    'accentColor': Color(0xFFFFA000),
  },

  // Yapı Kredi - Gri-mavi geçiş
  'yapikredi': {
    'name': 'Yapı Kredi',
    'gradientColors': [
      Color(0xFF232D4B), // koyu lacivert
      Color(0xFF2E3C66), // morumsu lacivert
      Color(0xFF3C4A85), // mavi-gri
    ],
    'accentColor': Color(0xFF2E3C66),
  },

  // Kuveyt Türk - Yeşil-İslami tonlar
  'kuveytturk': {
    'name': 'Kuveyt Türk',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C), // standart yeşil
      Color(0xFF81C784), // açık yeşil
    ],
    'accentColor': Color(0xFF388E3C),
  },

  // Albaraka Türk - Turuncu ağırlıklı İslami banka
  'albaraka': {
    'name': 'Albaraka Türk',
    'gradientColors': [
      Color(0xFFFF6F00), // turuncu
      Color(0xFFFFA000), // amber turuncu
      Color(0xFFFFCC80), // krem-turuncu
    ],
    'accentColor': Color(0xFFFFA000),
  },

  // QNB Finansbank - Mor-lacivert
  'qnb': {
    'name': 'QNB Finansbank',
    'gradientColors': [
      Color(0xFF2C2A4A), // koyu mor
      Color(0xFF5C4D7D), // mor
      Color(0xFF9B59B6), // açık mor
    ],
    'accentColor': Color(0xFF5C4D7D),
  },

  // Enpara - Parlak, gradient pastel renkler
  'enpara': {
    'name': 'Enpara.com',
    'gradientColors': [
      Color(0xFFE91E63), // fuşya
      Color(0xFF9C27B0), // mor
      Color(0xFF03A9F4), // mavi
    ],
    'accentColor': Color(0xFFE91E63),
  },

  // Papara - Koyu mor/pembe
  'papara': {
    'name': 'Papara',
    'gradientColors': [
      Color(0xFF6A1B9A), // koyu mor
      Color(0xFF9C27B0), // mor
      Color(0xFFCE93D8), // açık mor
    ],
    'accentColor': Color(0xFF9C27B0),
  },

  // Türkiye Finans - Koyu yeşil
  'turkiyefinans': {
    'name': 'Türkiye Finans',
    'gradientColors': [
      Color(0xFF00695C), // koyu teal
      Color(0xFF00897B),
      Color(0xFF26A69A),
    ],
    'accentColor': Color(0xFF00897B),
  },

  // TEB - Canlı yeşil
  'teb': {
    'name': 'TEB',
    'gradientColors': [
      Color(0xFF004D40), // koyu yeşil
      Color(0xFF00796B),
      Color(0xFF009688), // teal
    ],
    'accentColor': Color(0xFF00796B),
  },

  // HSBC Türkiye - Siyah-kırmızı
  'hsbcturkiye': {
    'name': 'HSBC Türkiye',
    'gradientColors': [
      Color(0xFF000000), // siyah
      Color(0xFF880000), // koyu kırmızı
      Color(0xFFB71C1C),
    ],
    'accentColor': Color(0xFF880000),
  },

  // ING - Turuncu ağırlıklı
  'ing': {
    'name': 'ING Türkiye',
    'gradientColors': [
      Color(0xFFFF6F00), // ING turuncusu
      Color(0xFFFF8F00),
      Color(0xFFFFA726),
    ],
    'accentColor': Color(0xFFFF6F00),
  },

  // Denizbank - Mavi denizci teması
  'denizbank': {
    'name': 'DenizBank',
    'gradientColors': [
      Color(0xFF0D47A1), // koyu mavi
      Color(0xFF1976D2),
      Color(0xFF64B5F6),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  // Anadolubank - Açık mavi gri
  'anadolubank': {
    'name': 'AnadoluBank',
    'gradientColors': [
      Color(0xFF546E7A), // gri mavi
      Color(0xFF78909C),
      Color(0xFFB0BEC5),
    ],
    'accentColor': Color(0xFF78909C),
  },

  // Türkiye Halk Bankası - Klasik mavi
  'halkbank': {
    'name': 'Halkbank',
    'gradientColors': [
      Color(0xFF0D47A1), // koyu mavi
      Color(0xFF1976D2),
      Color(0xFF42A5F5),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  // Türk bankaları - Ek bankalar
  'turkishbank': {
    'name': 'TurkishBank',
    'gradientColors': [
      Color(0xFF1A237E), // koyu indigo
      Color(0xFF3F51B5),
      Color(0xFF7986CB),
    ],
    'accentColor': Color(0xFF3F51B5),
  },

  'fibabank': {
    'name': 'FibaBank',
    'gradientColors': [
      Color(0xFFE65100), // koyu turuncu
      Color(0xFFFF9800),
      Color(0xFFFFB74D),
    ],
    'accentColor': Color(0xFFFF9800),
  },

  'osmanli': {
    'name': 'Osmanlı Bankası',
    'gradientColors': [
      Color(0xFF4A148C), // koyu mor
      Color(0xFF7B1FA2),
      Color(0xFFBA68C8),
    ],
    'accentColor': Color(0xFF7B1FA2),
  },

  'icbc': {
    'name': 'ICBC Türkiye',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE57373),
      Color(0xFFFFCDD2),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'citibank': {
    'name': 'Citibank Türkiye',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF42A5F5),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'deutsche': {
    'name': 'Deutsche Bank',
    'gradientColors': [
      Color(0xFF424242), // gri
      Color(0xFF616161),
      Color(0xFF9E9E9E),
    ],
    'accentColor': Color(0xFF616161),
  },

  'jpmorgan': {
    'name': 'JPMorgan Chase',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'wellsfargo': {
    'name': 'Wells Fargo',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'bankofamerica': {
    'name': 'Bank of America',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF64B5F6),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'chase': {
    'name': 'Chase Bank',
    'gradientColors': [
      Color(0xFF0D47A1), // koyu mavi
      Color(0xFF1565C0),
      Color(0xFF42A5F5),
    ],
    'accentColor': Color(0xFF1565C0),
  },

  'goldmansachs': {
    'name': 'Goldman Sachs',
    'gradientColors': [
      Color(0xFF000000), // siyah
      Color(0xFF424242),
      Color(0xFF757575),
    ],
    'accentColor': Color(0xFF424242),
  },

  'morganstanley': {
    'name': 'Morgan Stanley',
    'gradientColors': [
      Color(0xFF1A237E), // koyu indigo
      Color(0xFF303F9F),
      Color(0xFF5C6BC0),
    ],
    'accentColor': Color(0xFF303F9F),
  },

  'barclays': {
    'name': 'Barclays',
    'gradientColors': [
      Color(0xFF000000), // siyah
      Color(0xFF424242),
      Color(0xFF9E9E9E),
    ],
    'accentColor': Color(0xFF424242),
  },

  'lloyds': {
    'name': 'Lloyds Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'hsbc': {
    'name': 'HSBC',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFFFCDD2),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'santander': {
    'name': 'Santander',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'bnpparibas': {
    'name': 'BNP Paribas',
    'gradientColors': [
      Color(0xFF1A237E), // koyu indigo
      Color(0xFF3F51B5),
      Color(0xFF7986CB),
    ],
    'accentColor': Color(0xFF3F51B5),
  },

  'societegenerale': {
    'name': 'Société Générale',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'creditagricole': {
    'name': 'Crédit Agricole',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'ubs': {
    'name': 'UBS',
    'gradientColors': [
      Color(0xFF000000), // siyah
      Color(0xFF424242),
      Color(0xFF9E9E9E),
    ],
    'accentColor': Color(0xFF424242),
  },

  'creditSuisse': {
    'name': 'Credit Suisse',
    'gradientColors': [
      Color(0xFF1A237E), // koyu indigo
      Color(0xFF303F9F),
      Color(0xFF5C6BC0),
    ],
    'accentColor': Color(0xFF303F9F),
  },

  'deutschebank': {
    'name': 'Deutsche Bank',
    'gradientColors': [
      Color(0xFF000000), // siyah
      Color(0xFF424242),
      Color(0xFF9E9E9E),
    ],
    'accentColor': Color(0xFF424242),
  },

  'commerzbank': {
    'name': 'Commerzbank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'unicredit': {
    'name': 'UniCredit',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'intesa': {
    'name': 'Intesa Sanpaolo',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'mizuho': {
    'name': 'Mizuho Bank',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'mufg': {
    'name': 'MUFG Bank',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'sumitomo': {
    'name': 'Sumitomo Mitsui',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'standardchartered': {
    'name': 'Standard Chartered',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'dbs': {
    'name': 'DBS Bank',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'ocbc': {
    'name': 'OCBC Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'uob': {
    'name': 'UOB Bank',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'commonwealth': {
    'name': 'Commonwealth Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'anz': {
    'name': 'ANZ Bank',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'westpac': {
    'name': 'Westpac',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'nab': {
    'name': 'NAB Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'td': {
    'name': 'TD Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'rbc': {
    'name': 'RBC Bank',
    'gradientColors': [
      Color(0xFFD32F2F), // kırmızı
      Color(0xFFE53935),
      Color(0xFFEF5350),
    ],
    'accentColor': Color(0xFFD32F2F),
  },

  'scotiabank': {
    'name': 'Scotiabank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },

  'bmo': {
    'name': 'BMO Bank',
    'gradientColors': [
      Color(0xFF1B5E20), // koyu yeşil
      Color(0xFF388E3C),
      Color(0xFF81C784),
    ],
    'accentColor': Color(0xFF388E3C),
  },

  'cibc': {
    'name': 'CIBC Bank',
    'gradientColors': [
      Color(0xFF1976D2), // mavi
      Color(0xFF2196F3),
      Color(0xFF90CAF9),
    ],
    'accentColor': Color(0xFF1976D2),
  },
};

  // Card Design Helper Methods
  static List<Color> getCardGradientColors(String cardType) {
    final design = cardDesigns[cardType.toLowerCase()];
    return design?['gradientColors'] ?? cardDesigns['debit']!['gradientColors'];
  }

  static Color getCardAccentColor(String cardType) {
    final design = cardDesigns[cardType.toLowerCase()];
    return design?['accentColor'] ?? cardDesigns['debit']!['accentColor'];
  }

  // Bank Design Helper Methods
  static List<Color> getBankGradientColors(String bankCode) {
    final design = bankDesigns[bankCode.toLowerCase()];
    return design?['gradientColors'] ?? bankDesigns['garanti']!['gradientColors'];
  }

  static Color getBankAccentColor(String bankCode) {
    final design = bankDesigns[bankCode.toLowerCase()];
    return design?['accentColor'] ?? bankDesigns['garanti']!['accentColor'];
  }

  static String getBankName(String bankCode) {
    final design = bankDesigns[bankCode.toLowerCase()];
    return design?['name'] ?? 'Qanta Bank';
  }

  /// Get localized bank name
  static String getLocalizedBankName(String bankCode, dynamic l10n) {
    switch (bankCode.toLowerCase()) {
      case 'garanti':
        return l10n.garantiBBVA;
      case 'isbank':
        return l10n.isBankasi;
      case 'akbank':
        return l10n.akbank;
      case 'ziraat':
        return l10n.ziraatBankasi;
      case 'vakifbank':
        return l10n.vakifBank;
      case 'yapikredi':
        return l10n.yapiKredi;
      case 'kuveytturk':
        return l10n.kuveytTurk;
      case 'albaraka':
        return l10n.albarakaTurk;
      case 'qnb':
        return l10n.qnbFinansbank;
      case 'enpara':
        return l10n.enpara;
      case 'papara':
        return l10n.papara;
      case 'turkiyefinans':
        return l10n.turkiyeFinans;
      case 'teb':
        return l10n.teb;
      case 'hsbcturkiye':
        return l10n.hsbcTurkiye;
      case 'ing':
        return l10n.ingTurkiye;
      case 'denizbank':
        return l10n.denizBank;
      case 'anadolubank':
        return l10n.anadoluBank;
      case 'halkbank':
        return l10n.halkBank;
      default:
        return l10n.qantaBank;
    }
  }

  // Get all available banks
  static List<String> getAvailableBanks() {
    return bankDesigns.keys.toList();
  }

  // Card Shadow Configuration
  static List<BoxShadow> getCardShadows(Color accentColor) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: accentColor.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 0),
      ),
    ];
  }

  // Holographic Effect Gradient
  static LinearGradient getHolographicGradient(Color accentColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.1),
        Colors.transparent,
        accentColor.withValues(alpha: 0.05),
      ],
    );
  }

  // Asset Paths
  static const String iconPath = 'assets/icons/';
  static const String imagePath = 'assets/images/';
  static const String logoPath = '${imagePath}logo.png';
  static const String logoWhitePath = '${imagePath}logo_white.png';
  static const String logoSmallPath = '${imagePath}logo_small.png';

  // API Constants
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String currencyKey = 'preferred_currency';
  static const String onboardingKey = 'onboarding_completed';
  static const String biometricKey = 'biometric_enabled';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // Categories with Icons
  static const Map<String, IconData> categoryIcons = {
    'salary': Icons.work,
    'freelance': Icons.laptop,
    'investment': Icons.trending_up_rounded,
    'business': Icons.business,
    'gift': Icons.card_giftcard,
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_bag,
    'entertainment': Icons.movie,
    'bills': Icons.receipt_long_rounded,
    'healthcare': Icons.local_hospital,
    'education': Icons.school,
    'travel': Icons.flight,
    'housing': Icons.home,
    'insurance': Icons.security,
    'other': Icons.category,
  };

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'salary': Color(0xFF4CAF50),
    'freelance': Color(0xFF2196F3),
    'investment': Color(0xFF9C27B0),
    'business': Color(0xFF607D8B),
    'gift': Color(0xFFE91E63),
    'food': Color(0xFFFF5722),
    'transport': Color(0xFF3F51B5),
    'shopping': Color(0xFFFF9800),
    'entertainment': Color(0xFF795548),
    'bills': Color(0xFFF44336),
    'healthcare': Color(0xFF009688),
    'education': Color(0xFF8BC34A),
    'travel': Color(0xFF00BCD4),
    'housing': Color(0xFF673AB7),
    'insurance': Color(0xFF9E9E9E),
    'other': Color(0xFF607D8B),
  };

  // Breakpoints for Responsive Design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Helper Methods
  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['other']!;
  }

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? categoryIcons['other']!;
  }

  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) => 
      width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isDesktop(double width) => width >= tabletBreakpoint;
} 
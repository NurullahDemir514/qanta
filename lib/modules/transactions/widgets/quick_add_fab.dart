import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ai/firebase_ai_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../stocks/providers/stock_provider.dart';
import '../../stocks/screens/stock_transaction_form_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:async';

/// Quick Add FAB - AI ile Hızlı İşlem Ekleme
/// 
/// Örnek: "50 tl kahve ziraat" yazınca AI parse edip transaction oluşturur

/// Custom Exceptions
class NoAmountException implements Exception {
  final String message;
  NoAmountException(this.message);
}

class NoAccountFoundException implements Exception {
  final String searchedName;
  final List<dynamic> availableAccounts;
  NoAccountFoundException(this.searchedName, this.availableAccounts);
}

class MultipleAccountsException implements Exception {
  final String searchedName;
  final List<dynamic> matchingAccounts;
  MultipleAccountsException(this.searchedName, this.matchingAccounts);
}

class StockAccountException implements Exception {
  final String searchedName;
  final List<dynamic> availableAccounts;
  final String stockSymbol;
  final double quantity;
  final double? price;
  final bool isBuy;
  final bool isSell;
  
  StockAccountException(
    this.searchedName,
    this.availableAccounts, {
    required this.stockSymbol,
    required this.quantity,
    required this.price,
    required this.isBuy,
    required this.isSell,
  });
}

class QuickAddFAB extends StatefulWidget {
  const QuickAddFAB({super.key});

  @override
  State<QuickAddFAB> createState() => _QuickAddFABState();
}

class _QuickAddFABState extends State<QuickAddFAB> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FirebaseAIService _aiService = FirebaseAIService();
  bool _isExpanded = false;
  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  // Chat mode için
  final List<Map<String, dynamic>> _chatMessages = []; // {role: 'user'/'ai', content: '...'}
  final List<Map<String, String>> _conversationHistory = []; // Backend için history
  
  // Hata durumu için
  String? _errorMessage;
  List<dynamic>? _accountOptions;
  String? _selectedAccountId;
  Map<String, dynamic>? _pendingTransaction;
  Map<String, dynamic>? _pendingStockData; // Hisse işlemi için pending data
  bool _showStockSummary = false; // Hisse özeti göster
  bool _showTransactionSummary = false; // Normal transaction özeti göster
  AccountModel? _selectedStockAccount; // Seçilen hesap
  AccountModel? _selectedTransactionAccount; // Normal transaction için seçilen hesap

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
        // İlk açılışta karşılama mesajı ekle
        if (_chatMessages.isEmpty) {
          _chatMessages.add({
            'role': 'ai',
            'content': '👋 Merhaba! Size nasıl yardımcı olabilirim?\n\nİşlem eklemek için söyleyin, ben hallederim! 😊',
          });
        }
      } else {
        _animController.reverse();
        _controller.clear();
        _errorMessage = null;
        _accountOptions = null;
        _pendingTransaction = null;
        _pendingStockData = null;
        _selectedAccountId = null;
        _showStockSummary = false;
        _showTransactionSummary = false;
        _selectedStockAccount = null;
        _selectedTransactionAccount = null;
        _chatMessages.clear(); // Chat temizle
        _conversationHistory.clear(); // History temizle
      }
    });
  }

  Future<void> _processQuickAdd() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Özet gösteriliyorsa yeni işlem başlatma
    if (_showStockSummary || _showTransactionSummary) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _accountOptions = null;
      _selectedAccountId = null;
      _pendingTransaction = null;
      _pendingStockData = null;
    });

    Map<String, dynamic>? parsed;

    try {
      // AI ile parse et
      parsed = await _parseTransaction(text);
      
      if (!mounted) return;

      // Transaction oluştur
      final shouldClose = await _createTransaction(parsed);

      // Başarılı ve kapatılmalı - sessizce kapat (hisse özeti gösterilmediyse)
      if (mounted) {
        if (shouldClose) {
          _controller.clear();
          setState(() {
            _isExpanded = false;
            _isProcessing = false;
          });
          _animController.reverse();
        } else {
          // Özet gösteriliyor, FAB açık kalsın ama processing bitsin
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } on NoAmountException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isProcessing = false;
      });
    } on NoAccountFoundException catch (e) {
      setState(() {
        _errorMessage = 'Hesap bulunamadı: "${e.searchedName}"';
        _accountOptions = e.availableAccounts;
        _pendingTransaction = parsed;
        _isProcessing = false;
      });
    } on MultipleAccountsException catch (e) {
      setState(() {
        _errorMessage = '${e.matchingAccounts.length} hesap bulundu: "${e.searchedName}"';
        _accountOptions = e.matchingAccounts;
        _pendingTransaction = parsed;
        _isProcessing = false;
      });
    } on StockAccountException catch (e) {
      setState(() {
        final isBuy = e.isBuy;
        final isSell = e.isSell;
        final action = isSell ? 'satış' : (isBuy ? 'alım' : 'işlem');
        _errorMessage = e.searchedName.isEmpty
            ? '📈 ${e.stockSymbol} $action için hesap seçin:'
            : '📈 "${e.searchedName}" için ${e.availableAccounts.length} hesap bulundu:';
        _accountOptions = e.availableAccounts;
        _pendingStockData = {
          'stockSymbol': e.stockSymbol,
          'quantity': e.quantity,
          'price': e.price,
          'isBuy': e.isBuy,
          'isSell': e.isSell,
        };
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '❌ Hata: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _retryWithAccount(String accountId) async {
    // Hisse işlemi mi, normal transaction mı?
    if (_pendingStockData != null) {
      // Hisse işlemi için hesap seçildi - özet göster
      final provider = context.read<UnifiedProviderV2>();
      final account = provider.accounts.firstWhere((a) => a.id == accountId);
      
      setState(() {
        _selectedStockAccount = account;
        _showStockSummary = true;
        _errorMessage = null;
        _accountOptions = null;
        _selectedAccountId = accountId;
      });
      return;
    }
    
    // Normal transaction için
    if (_pendingTransaction == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _accountOptions = null;
    });

    try {
      // Override hesap ID
      _pendingTransaction!['accountId'] = accountId;
      _selectedAccountId = accountId;

      final shouldClose = await _createTransaction(_pendingTransaction!);

      // Özet gösteriliyorsa FAB açık kalsın, değilse kapat
      if (mounted && shouldClose) {
        _controller.clear();
        setState(() {
          _isExpanded = false;
          _isProcessing = false;
          _pendingTransaction = null;
          _selectedAccountId = null;
        });
        _animController.reverse();
      } else if (mounted) {
        // Özet gösteriliyor, sadece processing'i durdur
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '❌ Hata: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _parseTransaction(String text) async {
    try {
      // AI ile parse et
      debugPrint('🤖 AI ile parsing başlatılıyor: "$text"');
      final aiResult = await _aiService.parseQuickAddText(text);
      
      if (aiResult != null) {
        debugPrint('✅ AI parse başarılı');
        
        // Hisse işlemi mi kontrol et
        if (aiResult['isStock'] == true) {
          debugPrint('📊 Hisse işlemi tespit edildi');
          return aiResult;
        }
        
        // Normal transaction
        final transactionTypeStr = aiResult['transactionType'] as String?;
        final transactionType = transactionTypeStr == 'income' 
            ? TransactionType.income 
            : TransactionType.expense;
            
        return {
          'amount': aiResult['amount'] ?? 0.0,
          'description': aiResult['description'] ?? '',
          'categoryName': aiResult['categoryName'] ?? 'Diğer',
          'accountName': aiResult['accountName'],
          'transactionDate': aiResult['transactionDate'] ?? DateTime.now(),
          'transactionType': transactionType,
          'isStock': false,
        };
      }
      
      debugPrint('⚠️ AI parse başarısız, fallback yok - hata fırlatılıyor');
      throw Exception('AI parsing failed');
    } catch (e) {
      debugPrint('❌ AI parsing hatası: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> _parseTransactionWithRegex(String text) async {
    // 0. Hisse işlemi kontrolü (öncelikli)
    final stockResult = _detectStockTransaction(text);
    if (stockResult['isStock'] == true) {
      return stockResult; // Hisse işlemi tespit edildi
    }

    // 1. Tarih bul ve temizle
    final dateResult = _extractDate(text);
    String cleanedText = dateResult['cleanedText']!;
    DateTime transactionDate = dateResult['date'] as DateTime;
    
    // 2. Hesap adını bul ve temizle
    final accountResult = _extractAccountName(cleanedText);
    cleanedText = accountResult['cleanedText']!;
    String? accountName = accountResult['accountName']!.isNotEmpty
        ? accountResult['accountName']
        : null;
    
    // 3. Miktar bul ve temizle
    final amountRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:tl|₺|lira)?', 
      caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(cleanedText);
    
    double amount = 0;
    String description = cleanedText;
    
    if (amountMatch != null) {
      amount = double.parse(amountMatch.group(1)!.replaceAll(',', '.'));
      description = cleanedText.replaceFirst(amountMatch.group(0)!, '').trim();
    }

    // Miktar kontrolü
    if (amount <= 0) {
      throw NoAmountException('⚠️ Miktar girilmedi! Örnek: "50 tl çay"');
    }

    // "banka kartı", "kredi kartı" gibi gereksiz kelimeleri temizle
    description = description
        .replaceAll(RegExp(r'\b(banka\s*kartı|kredi\s*kartı|kart)\b', caseSensitive: false), '')
        .trim();

    // 4. Gelir mi gider mi tespit et
    final transactionType = _detectTransactionType(description);

    // 5. Kategori olarak description'ın ilk kelimesini kullan (ilk harf büyük)
    // Örnek: "çay" → "Çay", "kahve içtim" → "Kahve"
    String categoryName = description.isEmpty 
        ? 'Diğer' 
        : () {
            final firstWord = description.split(' ').first.trim();
            return firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
          }();

    debugPrint('📝 Parse Sonucu:');
    debugPrint('   💰 Miktar: $amount TL');
    debugPrint('   📄 Açıklama: "$description"');
    debugPrint('   🏦 Hesap: ${accountName ?? "Belirtilmedi"}');
    debugPrint('   📂 Kategori: "$categoryName" (description\'dan)');
    debugPrint('   📅 Tarih: ${transactionDate.toString().split(' ')[0]}');
    debugPrint('   💸 Tip: ${transactionType == TransactionType.income ? "Gelir" : "Gider"}');

    return {
      'amount': amount,
      'description': description,
      'categoryId': null, // Yeni kategori oluşturulacak
      'categoryName': categoryName,
      'accountName': accountName,
      'transactionDate': transactionDate,
      'transactionType': transactionType,
    };
  }

  /// Hisse işlemi tespit et
  Map<String, dynamic> _detectStockTransaction(String text) {
    final lower = text.toLowerCase();
    
    // Alım/Satım kelimeleri (daha geniş)
    final buyKeywords = ['al', 'alım', 'buy', 'satın al', 'aldım'];
    final sellKeywords = ['sat', 'satış', 'sell', 'satıl', 'sattım', 'bozdurdum'];
    
    bool isBuy = false;
    bool isSell = false;
    
    for (final keyword in buyKeywords) {
      if (lower.contains(keyword)) {
        isBuy = true;
        break;
      }
    }
    
    for (final keyword in sellKeywords) {
      if (lower.contains(keyword)) {
        isSell = true;
        break;
      }
    }
    
    // Hesap bilgisini parse et
    final accountResult = _extractAccountName(text);
    final cleanedTextForStock = accountResult['cleanedText']!;
    final accountName = accountResult['accountName']!.isNotEmpty 
        ? accountResult['accountName'] 
        : null;
    
    // Bilinen BIST ve global hisse isimleri (küçük harf)
    final knownStocks = {
      // BIST Hisseleri
      'thyao': 'THYAO',
      'türk hava yolları': 'THYAO',
      'akbnk': 'AKBNK',
      'akbank': 'AKBNK',
      'asels': 'ASELS',
      'aselsan': 'ASELS',
      'tuprs': 'TUPRS',
      'tüpraş': 'TUPRS',
      'eregl': 'EREGL',
      'ereğli': 'EREGL',
      'sahol': 'SAHOL',
      'sabanc': 'SAHOL',
      'sabancı': 'SAHOL',
      'bimas': 'BIMAS',
      'bim': 'BIMAS',
      'kchol': 'KCHOL',
      'koç': 'KCHOL',
      'garan': 'GARAN',
      'garanti': 'GARAN',
      'isctr': 'ISCTR',
      'iş bankası': 'ISCTR',
      'vakbn': 'VAKBN',
      'vakıf': 'VAKBN',
      'sise': 'SISE',
      'şişe': 'SISE',
      'kozal': 'KOZAL',
      'koza': 'KOZAL',
      'froto': 'FROTO',
      'ford': 'FROTO',
      'toaso': 'TOASO',
      'tofaş': 'TOASO',
      'petkm': 'PETKM',
      'petkim': 'PETKM',
      // Global Stocks (US)
      'aapl': 'AAPL',
      'apple': 'AAPL',
      'googl': 'GOOGL',
      'google': 'GOOGL',
      'msft': 'MSFT',
      'microsoft': 'MSFT',
      'amzn': 'AMZN',
      'amazon': 'AMZN',
      'tsla': 'TSLA',
      'tesla': 'TSLA',
      'meta': 'META',
      'facebook': 'META',
      'nvda': 'NVDA',
      'nvidia': 'NVDA',
    };
    
    // 1. Büyük harf sembol ara (THYAO, AKBNK gibi) - orijinal text'te
    final symbolPattern = RegExp(r'\b([A-Z]{3,5})\b');
    final symbolMatch = symbolPattern.firstMatch(text);
    String? detectedSymbol = symbolMatch?.group(1);
    
    // 2. Bilinen hisse ismi ara (küçük harfle) - cleanedTextForStock'ta
    if (detectedSymbol == null) {
      for (final entry in knownStocks.entries) {
        if (cleanedTextForStock.toLowerCase().contains(entry.key)) {
          detectedSymbol = entry.value;
          break;
        }
      }
    }
    
    // "adet", "lot", "shares" kelimesi varsa büyük ihtimalle hisse
    final hasQuantityIndicator = lower.contains('adet') || lower.contains('lot') || lower.contains('shares');
    
    // Hisse sembolü veya miktar göstergesi varsa hisse işlemi
    if (detectedSymbol != null || hasQuantityIndicator) {
      // Hisse işlemi tespit edildi!
      
      // Miktar bul (başta gelen sayıyı tercih et)
      final quantityPattern = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(?:adet|lot|shares)?', caseSensitive: false);
      var quantityMatch = quantityPattern.firstMatch(cleanedTextForStock.trim());
      
      // Başta yoksa metinde ara
      if (quantityMatch == null) {
        final anyQuantityPattern = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:adet|lot|shares)?', caseSensitive: false);
        quantityMatch = anyQuantityPattern.firstMatch(cleanedTextForStock);
      }
      
      final quantity = quantityMatch != null 
          ? double.parse(quantityMatch.group(1)!.replaceAll(',', '.'))
          : 0.0;
      
      // Fiyat bul (TL, ₺ ile - "tlden", "tl'den" gibi varyasyonları da yakala)
      final pricePattern = RegExp(r"(\d+(?:[.,]\d+)?)\s*(?:tl|₺|lira)(?:den|dan|'den|'dan)?", caseSensitive: false);
      final priceMatch = pricePattern.firstMatch(cleanedTextForStock);
      final price = priceMatch != null 
          ? double.parse(priceMatch.group(1)!.replaceAll(',', '.'))
          : null;
      
      debugPrint('📊 Hisse tespit: Symbol=$detectedSymbol, Qty=$quantity, Price=$price, Buy=$isBuy, Sell=$isSell, Account=$accountName');
      
      return {
        'isStock': true,
        'stockSymbol': detectedSymbol,
        'quantity': quantity,
        'price': price,
        'isBuy': isBuy,
        'isSell': isSell,
        'accountName': accountName, // Hesap bilgisi eklendi
      };
    }
    
    return {'isStock': false};
  }

  /// Tarih bilgisini metinden çıkart
  Map<String, dynamic> _extractDate(String text) {
    final lower = text.toLowerCase();
    DateTime date = DateTime.now(); // Varsayılan: bugün
    String cleanedText = text;

    // Bugün, dün, yarın
    if (lower.contains('bugün')) {
      date = DateTime.now();
      cleanedText = text.replaceAll(RegExp(r'\bbugün\b', caseSensitive: false), '').trim();
    } else if (lower.contains('dün')) {
      date = DateTime.now().subtract(const Duration(days: 1));
      cleanedText = text.replaceAll(RegExp(r'\bdün\b', caseSensitive: false), '').trim();
    } else if (lower.contains('evvelsi gün') || lower.contains('evvelsi')) {
      date = DateTime.now().subtract(const Duration(days: 2));
      cleanedText = text.replaceAll(RegExp(r'\bevvelsi\s*gün\b|\bevvelsi\b', caseSensitive: false), '').trim();
    } else if (lower.contains('yarın')) {
      date = DateTime.now().add(const Duration(days: 1));
      cleanedText = text.replaceAll(RegExp(r'\byarın\b', caseSensitive: false), '').trim();
    } 
    // Geçen hafta, bu hafta
    else if (lower.contains('geçen hafta')) {
      date = DateTime.now().subtract(const Duration(days: 7));
      cleanedText = text.replaceAll(RegExp(r'\bgeçen\s*hafta\b', caseSensitive: false), '').trim();
    }
    // Geçen ay
    else if (lower.contains('geçen ay')) {
      date = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
      cleanedText = text.replaceAll(RegExp(r'\bgeçen\s*ay\b', caseSensitive: false), '').trim();
    }
    // Tarih formatı: 15 ekim, 23 ocak, vb.
    else {
      final datePattern = RegExp(
        r'(\d{1,2})\s*(ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık)',
        caseSensitive: false,
      );
      final match = datePattern.firstMatch(lower);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthName = match.group(2)!.toLowerCase();
        final monthMap = {
          'ocak': 1, 'şubat': 2, 'mart': 3, 'nisan': 4,
          'mayıs': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8,
          'eylül': 9, 'ekim': 10, 'kasım': 11, 'aralık': 12,
        };
        final month = monthMap[monthName] ?? DateTime.now().month;
        final year = DateTime.now().year;
        date = DateTime(year, month, day);
        cleanedText = text.replaceFirst(match.group(0)!, '').trim();
      }
    }

    return {
      'date': date,
      'cleanedText': cleanedText,
    };
  }

  /// Gelir mi gider mi tespit et
  TransactionType _detectTransactionType(String description) {
    final lower = description.toLowerCase();
    
    // Gelir anahtar kelimeleri
    final incomeKeywords = [
      'maaş', 'maas', 'maaşım', 'ücret', 'ucret',
      'gelir', 'kazanç', 'kazanc', 'ödeme aldım', 'odeme aldim',
      'yattı', 'yatti', 'para geldi', 'transfer geldi',
      'satış', 'satis', 'sattım', 'sattim',
      'freelance', 'danışmanlık', 'danismanlik',
      'kira geliri', 'temettü', 'temettu', 'faiz',
      'bonus', 'prim', 'ikramiye',
    ];

    for (final keyword in incomeKeywords) {
      if (lower.contains(keyword)) {
        return TransactionType.income;
      }
    }

    // Varsayılan: gider
    return TransactionType.expense;
  }

  Map<String, String> _extractAccountName(String text) {
    final lower = text.toLowerCase();
    
    // Banka/kart isimleri (sık kullanılanlar önce)
    final banks = {
      'kuveyttürk': 'KuveytTürk',
      'kuveyt türk': 'KuveytTürk',
      'kuveyt': 'KuveytTürk',
      'ziraat': 'Ziraat Bankası',
      'garanti': 'Garanti BBVA',
      'yapı kredi': 'Yapı Kredi',
      'yapıkredi': 'Yapı Kredi',
      'işbank': 'İş Bankası',
      'iş bankası': 'İş Bankası',
      'iban': 'İş Bankası',
      'akbank': 'Akbank',
      'qnb': 'QNB Finansbank',
      'deniz': 'Denizbank',
      'halk': 'Halkbank',
      'vakıf': 'Vakıfbank',
      'nakit': 'Nakit',
      'cash': 'Nakit',
    };

    for (final entry in banks.entries) {
      if (lower.contains(entry.key)) {
        // Hesap adını ve temizlenmiş metni döndür
        final cleanedText = text.replaceAll(RegExp(entry.key, caseSensitive: false), '').trim();
        return {
          'accountName': entry.value,
          'cleanedText': cleanedText,
        };
      }
    }

    return {'accountName': '', 'cleanedText': text};
  }

  Future<bool> _createTransaction(Map<String, dynamic> parsed) async {
    // Hisse işlemi mi kontrol et
    if (parsed['isStock'] == true) {
      await _handleStockTransaction(parsed);
      return false; // Özet gösterildi, FAB kapatılmamalı
    }

    final provider = context.read<UnifiedProviderV2>();
    
    // Transaction type'ı al
    final transactionType = parsed['transactionType'] as TransactionType? ?? TransactionType.expense;
    
    // Tarih bilgisini al
    final transactionDate = parsed['transactionDate'] as DateTime? ?? DateTime.now();
    
    // Hesap bul
    String? accountId = parsed['accountId'] as String?; // Override varsa kullan
    
    if (accountId == null) {
      if (parsed['accountName'] != null) {
        // İsme göre hesap ara
        final accountName = parsed['accountName'] as String;
        final matches = _findMatchingAccounts(accountName, provider);
        
        if (matches.isEmpty) {
          // Hiç eşleşme yok - kullanıcıya seçenekleri göster
          throw NoAccountFoundException(accountName, provider.accounts);
        } else if (matches.length > 1) {
          // Birden fazla eşleşme var - kullanıcıya hangisi olduğunu sor
          throw MultipleAccountsException(accountName, matches);
        } else {
          // Tek eşleşme - kullan
          accountId = matches.first.id;
        }
      } else {
        // Hesap adı belirtilmemiş - ilk hesabı kullan
        if (provider.accounts.isNotEmpty) {
          accountId = provider.accounts.first.id;
        }
      }
    }

    // Hesap kontrolü
    if (accountId == null) {
      throw NoAccountFoundException('', provider.accounts);
    }

    // Kategori bul veya oluştur
    String? categoryId;
    final categoryName = parsed['categoryName'] as String?;
    
    if (categoryName != null && categoryName.isNotEmpty) {
      try {
        // Transaction tipine göre kategori tipi belirle
        final categoryType = transactionType == TransactionType.income 
            ? CategoryType.income 
            : CategoryType.expense;
        
        // Önce mevcut kategorilerde ara (display name ile eşleştir)
        final existingCategories = provider.categories.where(
          (cat) =>
              cat.displayName.toLowerCase() == categoryName.toLowerCase() &&
              cat.categoryType == categoryType,
        ).toList();

        if (existingCategories.isNotEmpty) {
          // Mevcut kategoriyi kullan
          categoryId = existingCategories.first.id;
          debugPrint('✅ Mevcut kategori kullanıldı: $categoryName');
        } else {
          // Yeni kategori oluştur
          debugPrint('🆕 Yeni kategori oluşturuluyor: $categoryName ($categoryType)');
          // Transaction type'a göre renk
          final categoryColor = transactionType == TransactionType.income 
              ? '#34D399'  // Yeşil (gelir)
              : '#FF3B30'; // Kırmızı (gider)
          final newCategory = await provider.createCategory(
            type: categoryType,
            name: categoryName,
            iconName: categoryName.toLowerCase(), // Kategori adına göre ikon
            colorHex: categoryColor,
          );
          categoryId = newCategory.id;
          debugPrint('✅ Yeni kategori oluşturuldu: $categoryName (${newCategory.id})');
        }
      } catch (e) {
        debugPrint('⚠️ Kategori oluşturulamadı: $e');
        // Hata durumunda varsayılan kategori kullan
        final defaultCategories = transactionType == TransactionType.income 
            ? provider.incomeCategories 
            : provider.expenseCategories;
        if (defaultCategories.isNotEmpty) {
          categoryId = defaultCategories.first.id;
        }
      }
    } else {
      // Kategori adı yoksa varsayılan kategori
      final defaultCategories = transactionType == TransactionType.income 
          ? provider.incomeCategories 
          : provider.expenseCategories;
      if (defaultCategories.isNotEmpty) {
        categoryId = defaultCategories.first.id;
      }
    }

    // Hesap modelini al
    final account = provider.accounts.firstWhere((a) => a.id == accountId);
    
    // Özet göster (direkt transaction oluşturma yerine)
    setState(() {
      _selectedTransactionAccount = account;
      _showTransactionSummary = true;
      _pendingTransaction = {
        ...parsed,
        'accountId': accountId,
        'categoryId': categoryId,
        'transactionType': transactionType,
        'transactionDate': transactionDate,
      };
      _isProcessing = false;
    });
    
    return false; // Özet gösteriliyor, FAB kapatılmamalı
  }

  /// Hisse işlemini handle et
  Future<void> _handleStockTransaction(Map<String, dynamic> parsed) async {
    final stockSymbol = parsed['stockSymbol'] as String?;
    final quantity = parsed['quantity'] as double? ?? 0.0;
    final price = parsed['price'] as double?;
    final isBuy = parsed['isBuy'] as bool? ?? false;
    final isSell = parsed['isSell'] as bool? ?? false;
    final accountName = parsed['accountName'] as String?;
    
    if (stockSymbol == null || stockSymbol.isEmpty) {
      throw Exception('⚠️ Hisse sembolü belirtilmedi! Örnek: "15 aselsan sattım"');
    }
    
    if (quantity <= 0) {
      throw Exception('⚠️ Miktar belirtilmedi! Örnek: "15 aselsan 205₺den sattım"');
    }
    
    final provider = context.read<UnifiedProviderV2>();
    
    // Hesap kontrolü - tıpkı normal transaction gibi
    AccountModel? selectedAccount;
    if (accountName != null && accountName.isNotEmpty) {
      final matches = _findMatchingAccounts(accountName, provider);
      
      if (matches.isEmpty) {
        // Hiç eşleşme yok - kullanıcıya tüm hesapları göster
        throw StockAccountException(
          accountName, 
          provider.accounts,
          stockSymbol: stockSymbol,
          quantity: quantity,
          price: price,
          isBuy: isBuy,
          isSell: isSell,
        );
      } else if (matches.length > 1) {
        // Birden fazla eşleşme var - hangisini kullanacağını sor
        throw StockAccountException(
          accountName,
          matches,
          stockSymbol: stockSymbol,
          quantity: quantity,
          price: price,
          isBuy: isBuy,
          isSell: isSell,
        );
      } else {
        // Tek eşleşme - kullan
        selectedAccount = matches.first;
      }
    } else {
      // Hesap adı belirtilmemiş - tüm hesapları göster
      throw StockAccountException(
        '', 
        provider.accounts,
        stockSymbol: stockSymbol,
        quantity: quantity,
        price: price,
        isBuy: isBuy,
        isSell: isSell,
      );
    }
    
    // Hesap seçildi - özet göster
    setState(() {
      _selectedStockAccount = selectedAccount;
      _showStockSummary = true;
      _pendingStockData = {
        'stockSymbol': stockSymbol,
        'quantity': quantity,
        'price': price,
        'isBuy': isBuy,
        'isSell': isSell,
      };
      _isProcessing = false;
    });
  }
  
  /// Hisse işlemini onayla ve kaydet
  Future<void> _confirmStockTransaction() async {
    if (_pendingStockData == null || _selectedStockAccount == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final stockProvider = context.read<StockProvider>();
      final userId = FirebaseAuthService.currentUserId;
      
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      final stockSymbol = _pendingStockData!['stockSymbol'] as String;
      final quantity = _pendingStockData!['quantity'] as double;
      final price = _pendingStockData!['price'] as double?;
      final isSell = _pendingStockData!['isSell'] as bool;
      
      // Hisse bilgilerini al (API'den veya cache'den)
      Stock? stockDetails;
      try {
        stockDetails = await stockProvider.getStockDetails(stockSymbol);
      } catch (e) {
        debugPrint('⚠️ Hisse detayları alınamadı, sembol kullanılıyor: $e');
      }
      
      // Fallback: eğer hisse detayları alınamadıysa default değerler kullan
      final stockName = stockDetails?.name ?? stockSymbol;
      final actualPrice = price ?? stockDetails?.currentPrice ?? 0.0;
      
      final totalAmount = quantity * actualPrice;
      const commission = 0.0; // Komisyon kullanıcı tarafından belirtilmiyor
      
      final transactionType = isSell 
          ? StockTransactionType.sell 
          : StockTransactionType.buy;
      
      final stockTransaction = StockTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        stockSymbol: stockSymbol,
        stockName: stockName,
        type: transactionType,
        quantity: quantity,
        price: actualPrice,
        totalAmount: totalAmount, // Net tutar = Toplam (komisyon yok)
        commission: commission,
        transactionDate: DateTime.now(),
        notes: null,
        accountId: _selectedStockAccount!.id,
      );
      
      await stockProvider.executeStockTransaction(stockTransaction);
      
      debugPrint('✅ Hisse işlemi başarıyla kaydedildi: ${stockTransaction.stockSymbol}');
      
      // Başarılı - FAB'ı kapat
      if (mounted) {
        _controller.clear();
        setState(() {
          _isExpanded = false;
          _isProcessing = false;
          _errorMessage = null;
          _accountOptions = null;
          _pendingTransaction = null;
          _pendingStockData = null;
          _selectedAccountId = null;
          _showStockSummary = false;
          _selectedStockAccount = null;
        });
        _animController.reverse();
      }
    } catch (e) {
      debugPrint('❌ Hisse işlemi hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '❌ Hata: $e';
          _isProcessing = false;
          _showStockSummary = false;
        });
      }
    }
  }

  /// Hesap adına göre eşleşen hesapları bul
  List<dynamic> _findMatchingAccounts(String searchName, UnifiedProviderV2 provider) {
    final lower = searchName.toLowerCase();
    final matches = <dynamic>[];
    
    // Tüm hesapları ara (accounts, creditCards, debitCards)
    for (final account in provider.accounts) {
      final accountNameLower = account.name.toLowerCase();
      
      // Tam eşleşme veya içerme kontrolü
      if (accountNameLower.contains(lower) || lower.contains(accountNameLower)) {
        matches.add(account);
      }
    }

    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: _isExpanded ? screenWidth * 0.75 : 56, // %75 genişlik veya 56px
        child: _isExpanded
            ? _buildExpandedInput(isDark)
            : _buildCollapsedFAB(isDark),
      ),
    );
  }

  /// Normal transaction'ı onayla ve kaydet
  Future<void> _confirmTransaction() async {
    if (_pendingTransaction == null || _selectedTransactionAccount == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final provider = context.read<UnifiedProviderV2>();
      
      await provider.createTransaction(
        type: _pendingTransaction!['transactionType'] as TransactionType,
        amount: _pendingTransaction!['amount'] as double,
        description: _pendingTransaction!['description'] as String,
        categoryId: _pendingTransaction!['categoryId'] as String?,
        sourceAccountId: _pendingTransaction!['accountId'] as String,
        transactionDate: _pendingTransaction!['transactionDate'] as DateTime,
      );
      
      debugPrint('✅ Transaction başarıyla kaydedildi');
      
      // Başarılı - FAB'ı kapat
      if (mounted) {
        _controller.clear();
        setState(() {
          _isExpanded = false;
          _isProcessing = false;
          _errorMessage = null;
          _accountOptions = null;
          _pendingTransaction = null;
          _selectedTransactionAccount = null;
          _showTransactionSummary = false;
          _selectedAccountId = null;
        });
        _animController.reverse();
      }
    } catch (e) {
      debugPrint('❌ Transaction hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '❌ Hata: $e';
          _isProcessing = false;
          _showTransactionSummary = false;
        });
      }
    }
  }
  
  Widget _buildTransactionSummary(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final amount = _pendingTransaction!['amount'] as double;
    final description = _pendingTransaction!['description'] as String;
    final categoryName = _pendingTransaction!['categoryName'] as String;
    final transactionType = _pendingTransaction!['transactionType'] as TransactionType;
    final account = _selectedTransactionAccount!;
    final transactionDate = _pendingTransaction!['transactionDate'] as DateTime;
    
    final isIncome = transactionType == TransactionType.income;
    final action = isIncome ? (l10n?.income ?? 'GELİR') : (l10n?.expense ?? 'GİDER');
    final actionColor = isIncome ? Colors.green.shade500 : const Color(0xFFFF3B30);
    final categoryIcon = CategoryIconService.getIcon(categoryName.toLowerCase());
    
    // Tarih formatı: 15 Ekim 2025
    final monthNames = [
      l10n?.january ?? 'Ocak',
      l10n?.february ?? 'Şubat',
      l10n?.march ?? 'Mart',
      l10n?.april ?? 'Nisan',
      l10n?.may ?? 'Mayıs',
      l10n?.june ?? 'Haziran',
      l10n?.july ?? 'Temmuz',
      l10n?.august ?? 'Ağustos',
      l10n?.september ?? 'Eylül',
      l10n?.october ?? 'Ekim',
      l10n?.november ?? 'Kasım',
      l10n?.december ?? 'Aralık',
    ];
    final formattedDate = '${transactionDate.day} ${monthNames[transactionDate.month - 1]} ${transactionDate.year}';
    
    return Material(
      elevation: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                Icon(categoryIcon, color: actionColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: actionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detaylar
            _buildSummaryRow(l10n?.amount ?? 'Tutar', '${amount.toStringAsFixed(2)} ₺', isDark, isBold: true),
            _buildSummaryRow(l10n?.account ?? 'Hesap', account.name, isDark),
            _buildSummaryRow(l10n?.date ?? 'Tarih', formattedDate, isDark),
            _buildSummaryRow(l10n?.category ?? 'Kategori', categoryName, isDark),
            
            const SizedBox(height: 16),
            
            // Butonlar
            Row(
              children: [
                // İptal
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : () {
                      setState(() {
                        _showTransactionSummary = false;
                        _pendingTransaction = null;
                        _selectedTransactionAccount = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n?.cancel ?? 'İptal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Onayla
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n?.confirmAndSave ?? 'Onayla ve Kaydet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStockSummary(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final stockSymbol = _pendingStockData!['stockSymbol'] as String;
    final quantity = _pendingStockData!['quantity'] as double;
    final price = _pendingStockData!['price'] as double?;
    final isSell = _pendingStockData!['isSell'] as bool;
    final isBuy = _pendingStockData!['isBuy'] as bool;
    final account = _selectedStockAccount!;
    
    final action = isSell ? (l10n?.sell ?? 'SATIŞ') : (isBuy ? (l10n?.buy ?? 'ALIM') : (l10n?.transaction ?? 'İŞLEM'));
    final actionColor = isSell ? const Color(0xFFFF3B30) : Colors.green.shade500;
    final actionIcon = isSell ? Icons.trending_down : Icons.trending_up;
    
    // Al/Sat seçimi - kullanıcı belirtmediyse sor
    if (!isBuy && !isSell) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFF007AFF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.selectTransactionType ?? 'İşlem Türü Seçin',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n?.stockSymbolQuantity(stockSymbol, quantity.toInt()) ?? "$stockSymbol için ${quantity.toInt()} adet"}\n${l10n?.buyOrSell ?? "Alım mı Satış mı?"}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Satış butonu
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pendingStockData!['isSell'] = true;
                          _pendingStockData!['isBuy'] = false;
                        });
                      },
                      icon: const Icon(Icons.trending_down, size: 20),
                      label: Text(
                        l10n?.sell ?? 'Satış',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Alım butonu
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pendingStockData!['isBuy'] = true;
                          _pendingStockData!['isSell'] = false;
                        });
                      },
                      icon: const Icon(Icons.trending_up, size: 20),
                      label: Text(
                        l10n?.buy ?? 'Alım',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showStockSummary = false;
                    _pendingStockData = null;
                    _selectedStockAccount = null;
                    _selectedAccountId = null;
                  });
                },
                child: Text(
                  l10n?.cancel ?? 'İptal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fiyat kontrolü - kullanıcı mutlaka fiyat girmeli
    if (price == null || price == 0.0) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFFFC300), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.priceNotSpecified ?? 'Fiyat Belirtilmedi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.pleaseEnterPrice ?? 'Lütfen fiyat bilgisi girin.\nÖrnek: "15 aselsan 205₺den sattım"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showStockSummary = false;
                    _pendingStockData = null;
                    _selectedStockAccount = null;
                    _selectedAccountId = null;
                  });
                },
                child: Text(
                  l10n?.goBack ?? 'Geri Dön',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final actualPrice = price;
    final totalAmount = quantity * actualPrice;
    const commission = 0.0; // Komisyon kullanıcı tarafından belirtilmiyor
    final netAmount = totalAmount; // Net tutar = Toplam (komisyon yok)
    
    return _buildStockSummaryContent(
      stockSymbol,
      quantity,
      actualPrice,
      account,
      action,
      actionColor,
      actionIcon,
      totalAmount,
      commission,
      netAmount,
      isDark,
    );
  }
  
  Widget _buildStockSummaryContent(
    String stockSymbol,
    double quantity,
    double actualPrice,
    AccountModel account,
    String action,
    Color actionColor,
    IconData actionIcon,
    double totalAmount,
    double commission,
    double netAmount,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                Icon(actionIcon, color: actionColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$stockSymbol $action',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: actionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detaylar
            _buildSummaryRow(l10n?.quantity ?? 'Miktar', '${quantity.toInt()} adet', isDark),
            _buildSummaryRow(l10n?.price ?? 'Fiyat', '${actualPrice.toStringAsFixed(2)} ₺', isDark),
            _buildSummaryRow(l10n?.account ?? 'Hesap', account.name, isDark),
            const Divider(height: 16),
            _buildSummaryRow(l10n?.total ?? 'Toplam', '${totalAmount.toStringAsFixed(2)} ₺', isDark),
            _buildSummaryRow(l10n?.commission ?? 'Komisyon', '${commission.toStringAsFixed(2)} ₺', isDark),
            _buildSummaryRow(
              l10n?.netAmount ?? 'Net Tutar',
              '${netAmount.toStringAsFixed(2)} ₺',
              isDark,
              isBold: true,
            ),
            const SizedBox(height: 16),
            
            // Onayla butonu
            Row(
              children: [
                // İptal
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : () {
                      setState(() {
                        _showStockSummary = false;
                        _pendingStockData = null;
                        _selectedStockAccount = null;
                        _selectedAccountId = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n?.cancel ?? 'İptal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Onayla
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmStockTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n?.confirmAndSave ?? 'Onayla ve Kaydet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCollapsedFAB(bool isDark) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _toggleExpand,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedInput(bool isDark) {
    final hasError = _errorMessage != null || _accountOptions != null;
    final hasStockSummary = _showStockSummary && _pendingStockData != null && _selectedStockAccount != null;
    final hasTransactionSummary = _showTransactionSummary && _pendingTransaction != null && _selectedTransactionAccount != null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hisse özeti (EN ÜSTTE)
        if (hasStockSummary) ...[
          _buildStockSummary(isDark),
          const SizedBox(height: 4),
        ],
        
        // Normal transaction özeti (EN ÜSTTE)
        if (hasTransactionSummary) ...[
          _buildTransactionSummary(isDark),
          const SizedBox(height: 4),
        ],
        
        // Hata mesajı ve pill butonlar (ÜSTTE - EXTRA ALAN)
        if (hasError) ...[
          Material(
            elevation: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hata mesajı
                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFF3B30),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                  // Hesap seçenekleri (HORIZONTAL SCROLL)
                  if (_accountOptions != null && _accountOptions!.isNotEmpty) ...[
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _accountOptions!.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final account = _accountOptions![index];
                          final isSelected = _selectedAccountId == account.id;
                          return GestureDetector(
                            onTap: () => _retryWithAccount(account.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF007AFF)
                                    : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    account.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
          const SizedBox(height: 4),
        ],

        // Input field (ALTTA - SABİT)
        Material(
          elevation: 6,
          borderRadius: (hasError || hasStockSummary)
              ? const BorderRadius.vertical(bottom: Radius.circular(28))
              : BorderRadius.circular(28),
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Close button
                SizedBox(
                  width: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isProcessing ? null : _toggleExpand,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                
                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isProcessing && !_showStockSummary && !_showTransactionSummary,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: (_showStockSummary || _showTransactionSummary)
                          ? (AppLocalizations.of(context)?.summaryHint ?? 'Özeti onaylayın veya iptal edin')
                          : (AppLocalizations.of(context)?.quickAddHint ?? 'Örn: 50₺ kahve ziraat'),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      if (!_showStockSummary && !_showTransactionSummary && !_isProcessing) {
                        _processQuickAdd();
                      }
                    },
                  ),
                ),
                
                // Add button (özet gösterildiğinde gizle)
                if (!_showStockSummary && !_showTransactionSummary)
                  SizedBox(
                    width: 40,
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                              ),
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.check, size: 24),
                            onPressed: _processQuickAdd,
                            color: const Color(0xFF007AFF),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


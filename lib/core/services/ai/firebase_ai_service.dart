import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_models.dart';

/// Firebase AI Service
/// 
/// Firebase Cloud Functions ile AI entegrasyonu.
/// Backend'de Gemini AI çalışır, güvenli ve ölçeklenebilir.
class FirebaseAIService {
  late final FirebaseFunctions _functions;

  // Singleton pattern
  static final FirebaseAIService _instance = FirebaseAIService._internal();
  factory FirebaseAIService() => _instance;

  FirebaseAIService._internal() {
    // Function deploy edildiği region ile aynı olmalı
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    debugPrint('🔥 Firebase Functions initialized: us-central1');
  }

  /// Harcama açıklamasından kategori tahmin et
  Future<AICategoryResult> categorizeExpense(
    String description, {
    List<String>? availableCategories,
  }) async {
    try {
      debugPrint('🤖 Firebase AI: Categorizing "$description"');

      final callable = _functions.httpsCallable('categorizeExpense');
      
      final result = await callable.call<Map<String, dynamic>>({
        'description': description,
        'availableCategories': availableCategories,
      });

      final data = Map<String, dynamic>.from(result.data);
      
      debugPrint('✅ Firebase AI: ${data['categoryName']} (${(data['confidence'] * 100).toStringAsFixed(0)}%)');

      return AICategoryResult(
        categoryId: data['categoryId'] as String,
        categoryName: data['categoryName'] as String,
        categoryIcon: data['categoryIcon'] as String,
        confidence: (data['confidence'] as num).toDouble(),
        reasoning: data['reasoning'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Firebase AI Error: $e');
      
      // Fallback
      return _fallbackCategorization(description);
    }
  }

  /// Fallback kategorizasyon (AI hata verirse)
  AICategoryResult _fallbackCategorization(String description) {
    final lowerDesc = description.toLowerCase();
    
    if (lowerDesc.contains('market') || 
        lowerDesc.contains('migros') ||
        lowerDesc.contains('şok') ||
        lowerDesc.contains('bim') ||
        lowerDesc.contains('a101')) {
      return const AICategoryResult(
        categoryId: 'food_drink',
        categoryName: 'Yiyecek & İçecek',
        categoryIcon: '🛒',
        confidence: 0.7,
        reasoning: 'Market alışverişi tespit edildi',
      );
    }
    
    if (lowerDesc.contains('starbucks') ||
        lowerDesc.contains('cafe') ||
        lowerDesc.contains('kahve') ||
        lowerDesc.contains('restaurant')) {
      return const AICategoryResult(
        categoryId: 'food_drink',
        categoryName: 'Yiyecek & İçecek',
        categoryIcon: '☕',
        confidence: 0.8,
        reasoning: 'Yeme-içme yeri tespit edildi',
      );
    }
    
    if (lowerDesc.contains('benzin') ||
        lowerDesc.contains('shell') ||
        lowerDesc.contains('opet') ||
        lowerDesc.contains('uber') ||
        lowerDesc.contains('taksi')) {
      return const AICategoryResult(
        categoryId: 'transportation',
        categoryName: 'Ulaşım',
        categoryIcon: '⛽',
        confidence: 0.8,
        reasoning: 'Ulaşım gideri tespit edildi',
      );
    }
    
    if (lowerDesc.contains('netflix') ||
        lowerDesc.contains('spotify') ||
        lowerDesc.contains('youtube') ||
        lowerDesc.contains('sinema')) {
      return const AICategoryResult(
        categoryId: 'entertainment',
        categoryName: 'Eğlence',
        categoryIcon: '🎬',
        confidence: 0.9,
        reasoning: 'Eğlence hizmeti tespit edildi',
      );
    }
    
    // Varsayılan
    return const AICategoryResult(
      categoryId: 'other',
      categoryName: 'Diğer',
      categoryIcon: '💰',
      confidence: 0.3,
      reasoning: 'Belirli bir kategori tespit edilemedi',
    );
  }

  /// Quick Add Text Parsing - AI ile otomatik işlem tespiti
  Future<Map<String, dynamic>?> parseQuickAddText(String text) async {
    try {
      debugPrint('🤖 Firebase AI: Parsing "$text"');

      final callable = _functions.httpsCallable('parseQuickAddText');
      
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
      });

      final data = Map<String, dynamic>.from(result.data);
      
      if (data['success'] == true) {
        debugPrint('✅ Firebase AI Parse Success');
        debugPrint('   Amount: ${data['amount']}');
        debugPrint('   Category: ${data['categoryName']}');
        debugPrint('   Account: ${data['accountName']}');
        debugPrint('   Type: ${data['transactionType']}');
        debugPrint('   IsStock: ${data['isStock']}');
        
        // TransactionType enum'a çevir
        final transactionType = data['transactionType'] == 'income' 
            ? 'income' 
            : 'expense';
        
        return {
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'description': data['description'] as String? ?? '',
          'categoryName': data['categoryName'] as String? ?? 'Diğer',
          'accountName': data['accountName'] as String?,
          'transactionDate': data['transactionDate'] != null 
              ? _parseLocalDate(data['transactionDate'] as String)
              : null,
          'transactionType': transactionType,
          'isStock': data['isStock'] as bool? ?? false,
          'stockSymbol': data['stockSymbol'] as String?,
          'quantity': (data['quantity'] as num?)?.toDouble(),
          'price': (data['price'] as num?)?.toDouble(),
          'isBuy': data['isBuy'] as bool? ?? false,
          'isSell': data['isSell'] as bool? ?? false,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Firebase AI Parse Error: $e');
      rethrow;
    }
  }

  /// Parse date string to local DateTime (no UTC conversion)
  DateTime _parseLocalDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      // Prevent UTC conversion - keep local time
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Test fonksiyonu
  Future<void> testConnection() async {
    try {
      final result = await categorizeExpense('Starbucks kahve');
      debugPrint('✅ Firebase AI Connection Test Successful: ${result.categoryName}');
    } catch (e) {
      debugPrint('❌ Firebase AI Connection Test Failed: $e');
      rethrow;
    }
  }

  /// Kullanıcının timezone offset'ini al (Firebase Functions için)
  String _getUserTimezoneOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    
    // Convert to "+03:00" format
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '-';
    final hourStr = hours.abs().toString().padLeft(2, '0');
    final minStr = minutes.toString().padLeft(2, '0');
    
    return '$sign$hourStr:$minStr';
  }

  /// Chat with AI - Conversational interface with image/PDF support
  Future<Map<String, dynamic>?> chatWithAI(
    String message, {
    List<Map<String, String>>? conversationHistory,
    List<Map<String, dynamic>>? userAccounts,
    Map<String, dynamic>? financialSummary,
    List<Map<String, dynamic>>? budgets,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? stockPortfolio,
    List<Map<String, dynamic>>? stockTransactions,
    String? language,
    String? currency,
    String? imageBase64, // 📷 Görüntü/PDF base64
    String? fileType, // 'image' veya 'pdf'
  }) async {
    try {
      debugPrint('💬 AI Chat: "$message" (lang: $language, currency: $currency, hasImage: ${imageBase64 != null}, fileType: $fileType, budgetCount: ${budgets?.length ?? 0}, categoryCount: ${categories?.length ?? 0}, stockCount: ${stockPortfolio?.length ?? 0}, stockTxCount: ${stockTransactions?.length ?? 0})');

      final callable = _functions.httpsCallable('chatWithAI');
      
      // Kullanıcının timezone'unu al
      final userTimezone = _getUserTimezoneOffset();
      debugPrint('🌍 User timezone: $userTimezone');
      
      final params = {
        'message': message,
        'conversationHistory': conversationHistory ?? [],
        'userAccounts': userAccounts ?? [],
        'financialSummary': financialSummary ?? {},
        'budgets': budgets ?? [],
        'categories': categories ?? [],
        'stockPortfolio': stockPortfolio ?? [],
        'stockTransactions': stockTransactions ?? [],
        'language': language ?? 'tr',
        'currency': currency ?? 'TRY',
        'userTimezone': userTimezone, // Timezone ekle
      };
      
      // Görüntü varsa ekle
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        params['imageBase64'] = imageBase64;
        params['fileType'] = fileType ?? 'image'; // Default: image
        debugPrint('📷 ${fileType ?? 'Image'} attached: ${imageBase64.length} characters');
      }
      
      final result = await callable.call<Map<String, dynamic>>(params);

      final data = Map<String, dynamic>.from(result.data);
      
      if (data['success'] == true) {
        debugPrint('✅ AI Chat Response: ${data['message']}');
        debugPrint('   IsReady: ${data['isReady']}');
        
        // Usage bilgisini logla (type-safe)
        if (data['usage'] != null) {
          try {
            final usage = Map<String, dynamic>.from(data['usage'] as Map);
            debugPrint('📊 AI Usage: ${usage['current']}/${usage['limit']} (Kalan: ${usage['remaining']})');
          } catch (e) {
            debugPrint('⚠️ Failed to parse usage in log: $e');
          }
        }
        
        return {
          'message': data['message'] as String,
          'isReady': data['isReady'] as bool? ?? false,
          'transactionData': data['transactionData'],
          'usage': data['usage'], // Raw data, caller'da parse edilecek
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ AI Chat Error: $e');
      rethrow;
    }
  }

  /// Bulk Delete Transactions - Toplu işlem silme
  Future<Map<String, dynamic>?> bulkDeleteTransactions({
    required Map<String, dynamic> filters,
  }) async {
    try {
      debugPrint('🗑️ Bulk Delete: filters=$filters');

      // Auth kontrolü
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found!');
        throw Exception('User must be authenticated');
      }
      debugPrint('👤 Current user: ${user.uid}');
      debugPrint('📧 Email: ${user.email}');
      
      // Token refresh dene
      try {
        final token = await user.getIdToken(true); // Force refresh
        debugPrint('🔑 Token refreshed: ${token?.substring(0, 20)}...');
      } catch (e) {
        debugPrint('⚠️ Token refresh error: $e');
      }

      final callable = _functions.httpsCallable('bulkDeleteTransactions');
      
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filters,
      });

      final data = Map<String, dynamic>.from(result.data);
      
      if (data['success'] == true) {
        final deletedCount = data['deletedCount'] as int? ?? 0;
        debugPrint('✅ Bulk Delete Success: $deletedCount işlem silindi');
        
        // Usage bilgisini logla
        if (data['usage'] != null) {
          try {
            final usage = Map<String, dynamic>.from(data['usage'] as Map);
            debugPrint('📊 AI Usage: ${usage['current']}/${usage['limit']} (Kalan: ${usage['remaining']})');
          } catch (e) {
            debugPrint('⚠️ Failed to parse usage in log: $e');
          }
        }
        
        return {
          'deletedCount': deletedCount,
          'message': data['message'] as String,
          'usage': data['usage'],
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Bulk Delete Error: $e');
      rethrow;
    }
  }
}


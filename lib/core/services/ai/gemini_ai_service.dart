import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_models.dart';

/// Gemini AI Service
/// 
/// Google Gemini AI ile entegrasyon için ana servis.
/// Harcama kategorizasyonu, analiz ve öneriler sağlar.
class GeminiAIService {
  late final GenerativeModel _model;
  static const String _apiKey = 'AIzaSyAZJAs_OCsi-gmYpN1RaX7dQGaIZY-8n-Q'; // TODO: Environment variable'a taşınacak

  // Singleton pattern
  static final GeminiAIService _instance = GeminiAIService._internal();
  factory GeminiAIService() => _instance;

  GeminiAIService._internal() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-pro', // En stabil eski model
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Daha tutarlı sonuçlar için düşük
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );
  }

  /// Harcama açıklamasından kategori tahmin et
  Future<AICategoryResult> categorizeExpense(
    String description, {
    List<String>? availableCategories,
  }) async {
    try {
      debugPrint('🤖 AI: Categorizing "$description"');

      // Mevcut kategorileri prompt'a ekle
      final categoriesText = availableCategories?.join(', ') ?? 
        'Yiyecek & İçecek, Ulaşım, Eğlence, Sağlık, Alışveriş, Faturalar, Eğitim, Diğer';

      final prompt = '''
Aşağıdaki harcama açıklamasını analiz et ve en uygun kategoriyi seç.

Harcama: "$description"

Mevcut Kategoriler:
$categoriesText

Sadece şu formatta yanıt ver (başka açıklama ekleme):
KATEGORİ: [kategori adı]
GÜVENİLİRLİK: [0-100 arası sayı]
NEDEN: [kısa açıklama]

Örnek:
KATEGORİ: Yiyecek & İçecek
GÜVENİLİRLİK: 95
NEDEN: Starbucks bir kafe zinciridir
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw AIException(
          'Boş yanıt alındı',
          type: AIErrorType.invalidResponse,
        );
      }

      // Parse response
      final result = _parseCategorizationResponse(response.text!);
      debugPrint('✅ AI: Category = ${result.categoryName}, Confidence = ${result.confidence}');

      return result;
    } catch (e) {
      debugPrint('❌ AI Error: $e');
      
      // Fallback - basit kural tabanlı kategorizasyon
      return _fallbackCategorization(description);
    }
  }

  /// AI yanıtını parse et
  AICategoryResult _parseCategorizationResponse(String response) {
    try {
      final lines = response.trim().split('\n');
      String categoryName = 'Diğer';
      double confidence = 0.5;
      String reasoning = '';

      for (final line in lines) {
        if (line.toUpperCase().startsWith('KATEGORİ:')) {
          categoryName = line.substring(line.indexOf(':') + 1).trim();
        } else if (line.toUpperCase().startsWith('GÜVENİLİRLİK:')) {
          final confidenceStr = line.substring(line.indexOf(':') + 1).trim();
          confidence = (double.tryParse(confidenceStr) ?? 50) / 100;
        } else if (line.toUpperCase().startsWith('NEDEN:')) {
          reasoning = line.substring(line.indexOf(':') + 1).trim();
        }
      }

      return AICategoryResult(
        categoryId: _getCategoryId(categoryName),
        categoryName: categoryName,
        categoryIcon: _getCategoryIcon(categoryName),
        confidence: confidence,
        reasoning: reasoning,
      );
    } catch (e) {
      throw AIException(
        'Yanıt parse edilemedi: $e',
        type: AIErrorType.invalidResponse,
        originalError: e,
      );
    }
  }

  /// Kategori adından ID oluştur
  String _getCategoryId(String categoryName) {
    final map = {
      'Yiyecek & İçecek': 'food_drink',
      'Ulaşım': 'transportation',
      'Eğlence': 'entertainment',
      'Sağlık': 'health',
      'Alışveriş': 'shopping',
      'Faturalar': 'bills',
      'Eğitim': 'education',
      'Diğer': 'other',
    };
    return map[categoryName] ?? 'other';
  }

  /// Kategori için ikon seç
  String _getCategoryIcon(String categoryName) {
    final map = {
      'Yiyecek & İçecek': '🍔',
      'Ulaşım': '🚗',
      'Eğlence': '🎭',
      'Sağlık': '💊',
      'Alışveriş': '🛒',
      'Faturalar': '📱',
      'Eğitim': '📚',
      'Diğer': '💰',
    };
    return map[categoryName] ?? '💰';
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
        lowerDesc.contains('restaurant') ||
        lowerDesc.contains('lokanta')) {
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
        lowerDesc.contains('bp') ||
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
        lowerDesc.contains('sinema') ||
        lowerDesc.contains('cinema')) {
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

  /// Batch kategorizasyon (birden fazla harcama için)
  Future<List<AICategoryResult>> batchCategorize(
    List<String> descriptions,
  ) async {
    final results = <AICategoryResult>[];
    
    for (final description in descriptions) {
      try {
        final result = await categorizeExpense(description);
        results.add(result);
        
        // Rate limiting için kısa bekleme
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ Batch categorization error for "$description": $e');
        results.add(_fallbackCategorization(description));
      }
    }
    
    return results;
  }

  /// Test fonksiyonu
  Future<void> testConnection() async {
    try {
      final result = await categorizeExpense('Starbucks kahve');
      debugPrint('✅ AI Connection Test Successful: ${result.categoryName}');
    } catch (e) {
      debugPrint('❌ AI Connection Test Failed: $e');
      rethrow;
    }
  }
}


/// AI Response Models
/// 
/// Bu dosya AI servislerinin döndürdüğü veri modellerini içerir.

/// Kategorizasyon sonucu
class AICategoryResult {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double confidence; // 0.0 - 1.0 arası güven skoru
  final String? reasoning; // AI'ın neden bu kategoriyi seçtiği

  const AICategoryResult({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.confidence,
    this.reasoning,
  });

  factory AICategoryResult.fromJson(Map<String, dynamic> json) {
    return AICategoryResult(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIcon: json['categoryIcon'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'confidence': confidence,
      'reasoning': reasoning,
    };
  }

  @override
  String toString() {
    return 'AICategoryResult(category: $categoryName, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Harcama analizi sonucu
class AIAnalysisResult {
  final String analysis;
  final List<String> insights;
  final List<String> recommendations;
  final DateTime timestamp;

  const AIAnalysisResult({
    required this.analysis,
    required this.insights,
    required this.recommendations,
    required this.timestamp,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      analysis: json['analysis'] as String,
      insights: (json['insights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      timestamp: _parseLocalDateTime(json['timestamp'] as String),
    );
  }
  
  /// Helper to parse datetime without UTC conversion
  static DateTime _parseLocalDateTime(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateTime(parsed.year, parsed.month, parsed.day, 
                     parsed.hour, parsed.minute, parsed.second);
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'insights': insights,
      'recommendations': recommendations,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Bütçe önerisi sonucu
class AIBudgetAdvice {
  final String summary;
  final Map<String, double> suggestedBudget;
  final List<String> savingsTips;
  final double potentialSavings;

  const AIBudgetAdvice({
    required this.summary,
    required this.suggestedBudget,
    required this.savingsTips,
    required this.potentialSavings,
  });

  factory AIBudgetAdvice.fromJson(Map<String, dynamic> json) {
    return AIBudgetAdvice(
      summary: json['summary'] as String,
      suggestedBudget: Map<String, double>.from(json['suggestedBudget'] as Map),
      savingsTips: (json['savingsTips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      potentialSavings: (json['potentialSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'suggestedBudget': suggestedBudget,
      'savingsTips': savingsTips,
      'potentialSavings': potentialSavings,
    };
  }
}

/// AI hata türleri
enum AIErrorType {
  networkError,
  apiError,
  rateLimitExceeded,
  invalidResponse,
  unknown,
}

/// AI Exception
class AIException implements Exception {
  final String message;
  final AIErrorType type;
  final dynamic originalError;

  AIException(this.message, {
    this.type = AIErrorType.unknown,
    this.originalError,
  });

  @override
  String toString() => 'AIException: $message';
}


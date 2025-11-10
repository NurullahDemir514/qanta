import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ai/firebase_ai_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/events/transaction_events.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../models/ai_insight_model.dart';
import '../models/statistics_model.dart';
import 'statistics_provider.dart';

/// AI Insights Provider - Cache mekanizması ile optimize edilmiş
class AIInsightsProvider extends ChangeNotifier {
  final UnifiedProviderV2 _unifiedProvider;
  final FirebaseAIService _aiService = FirebaseAIService();

  AIInsightsSummary? _summary;
  bool _isLoading = false;
  String? _error;
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
  
  // Cache mekanizması
  final Map<TimePeriod, AIInsightsSummary?> _cache = {};
  final Map<TimePeriod, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(hours: 1);
  
  // Transaction event listener
  StreamSubscription<TransactionEvent>? _transactionSubscription;
  DateTime? _lastTransactionDate;
  bool _isInitialized = false;

  AIInsightsProvider(this._unifiedProvider) {
    _initializeTransactionListener();
  }

  // Getters
  AIInsightsSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;
  TimePeriod get selectedPeriod => _selectedPeriod;

  /// Initialize transaction event listener
  void _initializeTransactionListener() {
    _transactionSubscription = transactionEvents.stream.listen((event) {
      if (event is TransactionAdded) {
        _handleTransactionAdded(event);
      }
    });
  }

  /// Handle transaction added event - Arkaplanda güncelle
  void _handleTransactionAdded(TransactionAdded event) async {
    // Sadece bugün için güncelle
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Cache'i invalidate et ve arkaplanda güncelle
    _cache.clear();
    _cacheTimestamps.clear();
    _lastTransactionDate = today;
    
    // Arkaplanda sessizce güncelle
    Future.delayed(const Duration(seconds: 2), () {
      _refreshInsightsInBackground();
    });
  }
  
  /// Manual trigger - Transaction eklendiğinde çağrılabilir
  void onTransactionAdded() {
    final today = DateTime.now();
    _lastTransactionDate = today;
    _cache.clear();
    _cacheTimestamps.clear();
    
    // Arkaplanda güncelle (2 saniye gecikmeyle)
    Future.delayed(const Duration(seconds: 2), () {
      _refreshInsightsInBackground();
    });
  }

  /// Arkaplanda insights'ı güncelle (UI'ı bloklamadan)
  void _refreshInsightsInBackground() async {
    if (_isLoading) return;
    
    try {
      // Sessizce yükle (loading state gösterme)
      // Context olmadan sadece cache temizle
      _cache.clear();
      _cacheTimestamps.clear();
      debugPrint('🔄 AI Insights: Cache cleared, will refresh on next load');
    } catch (e) {
      debugPrint('Background AI insights refresh failed: $e');
    }
  }

  /// Initial load - Sadece uygulama açılışında çağrılmalı
  Future<void> initializeInsights(BuildContext context) async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    await loadInsights(_selectedPeriod, context, forceRefresh: false);
  }

  /// Load AI insights - Cache kontrolü ile
  Future<void> loadInsights(
    TimePeriod period, 
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    // Filter değiştiğinde sadece period'u güncelle, AI request gönderme
    _selectedPeriod = period;
    
    // Cache'den kontrol et
    if (!forceRefresh && _isCacheValid(period)) {
      _summary = _cache[period];
      notifyListeners();
      return;
    }

    await _loadInsightsInternal(period, context: context, silent: false);
  }

  /// Internal load method
  Future<void> _loadInsightsInternal(
    TimePeriod period, {
    BuildContext? context,
    bool silent = false,
  }) async {
    if (!silent) {
      _setLoading(true);
      _clearError();
    }

    try {
      StatisticsData? statistics;
      
      if (context != null) {
        // Get statistics data
        final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        await statisticsProvider.loadStatistics(period);
        statistics = statisticsProvider.statistics;
      } else {
        // Context yoksa cache'den kullan
        return;
      }

      if (statistics == null || !statistics.hasData) {
        if (!silent) {
          _setError('Analiz için yeterli veri yok');
        }
        if (!silent) {
          _setLoading(false);
        }
        return;
      }

      // Yeterli veri kontrolü - En az 25 harcama işlemi gerekli
      final expenseTransactions = _unifiedProvider.transactions
          .where((t) => t.type == TransactionType.expense)
          .length;
      
      if (expenseTransactions < 25) {
        // AI'a request göndermeden fallback mesaj göster
        final themeProvider = context != null
            ? Provider.of<ThemeProvider>(context, listen: false)
            : null;
        if (themeProvider == null) {
          if (!silent) {
            _setLoading(false);
          }
          return;
        }
        
        final language = themeProvider.locale.languageCode;
        final fallbackMessage = language == 'tr'
            ? '**Yeterli veri bulunmuyor**\n\nDaha fazla harcama işlemi kaydettikten sonra analiz yapılabilecektir.\n\nYeterli veriye sahip olunduğunda AI size kapsamlı ve doğru öneriler sunabilecektir.'
            : language == 'de'
                ? '**Nicht genügend Daten**\n\nNach der Erfassung weiterer Ausgabentransaktionen kann eine Analyse durchgeführt werden.\n\nSobald ausreichend Daten vorhanden sind, kann KI Ihnen umfassende und genaue Empfehlungen geben.'
                : '**Insufficient Data**\n\nAnalysis will be available after recording more expense transactions.\n\nOnce sufficient data is available, AI can provide comprehensive and accurate recommendations.';
        
        // Fallback summary oluştur
        final fallbackSummary = AIInsightsSummary(
          overview: fallbackMessage,
          totalExpenses: statistics.totalExpenses,
          totalIncome: statistics.totalIncome,
          netBalance: statistics.netBalance,
          savingsRate: statistics.savingsRate,
          insights: [],
        );
        
        _summary = fallbackSummary;
        if (!silent) {
          _setLoading(false);
          notifyListeners();
        }
        return;
      }

      // Prepare financial data for AI
      final themeProvider = context != null
          ? Provider.of<ThemeProvider>(context, listen: false)
          : null;
      if (themeProvider == null) return;

      final currency = themeProvider.currency;
      final language = themeProvider.locale.languageCode;

      final financialData = _prepareFinancialData(statistics, currency);

      // Call AI service to get insights (kısa markdown formatında)
      final aiResponse = await _getAIInsights(
        financialData,
        period,
        language,
        currency,
      );

      // Parse AI response
      final summary = _parseAIResponse(aiResponse, statistics);

      // Cache'e kaydet
      _cache[period] = summary;
      _cacheTimestamps[period] = DateTime.now();
      _summary = summary;

      if (!silent) {
        notifyListeners();
      }
    } catch (e) {
      if (!silent) {
        _setError('AI analizi yüklenirken hata oluştu: ${e.toString()}');
      }
      debugPrint('Error loading AI insights: $e');
    } finally {
      if (!silent) {
        _setLoading(false);
      }
    }
  }

  /// Check if cache is valid
  bool _isCacheValid(TimePeriod period) {
    if (!_cache.containsKey(period)) return false;
    if (!_cacheTimestamps.containsKey(period)) return false;
    
    final cacheTime = _cacheTimestamps[period]!;
    final now = DateTime.now();
    final age = now.difference(cacheTime);
    
    return age < _cacheValidDuration;
  }

  /// Prepare financial data for AI analysis
  Map<String, dynamic> _prepareFinancialData(
    StatisticsData statistics,
    Currency currency,
  ) {
    // Get top categories
    final topCategories = statistics.categoryBreakdown.take(5).map((cat) {
      return {
        'category': cat.categoryName,
        'amount': cat.amount,
        'percentage': cat.percentage,
        'count': cat.transactionCount,
      };
    }).toList();

    // Get monthly trends
    final trends = statistics.monthlyTrends.take(3).map((trend) {
      return {
        'month': trend.monthYear,
        'income': trend.income,
        'expenses': trend.expenses,
        'netBalance': trend.netBalance,
      };
    }).toList();

    return {
      'totalIncome': statistics.totalIncome,
      'totalExpenses': statistics.totalExpenses,
      'netBalance': statistics.netBalance,
      'savingsRate': statistics.savingsRate,
      'averageSpending': statistics.averageSpending,
      'totalTransactions': statistics.totalTransactions,
      'topCategories': topCategories,
      'monthlyTrends': trends,
      'period': _periodToString(statistics.period),
    };
  }

  /// Get AI insights - Kısa ve markdown formatında
  Future<String> _getAIInsights(
    Map<String, dynamic> financialData,
    TimePeriod period,
    String language,
    Currency currency,
  ) async {
    // Kısa ve markdown formatında prompt
    final prompt = language == 'tr'
        ? '''Finansal durumumu **kısa ve öz** şekilde analiz et (max 150 kelime). Markdown formatında yanıtla:

**Özet:**
- Net bakiye ve genel durum
- En çok harcama yapılan kategori (top 1)

**Öneriler:**
- 2-3 kısa madde ile tasarruf fırsatları

Markdown formatında: **bold**, *italic*, listeler (-) kullan.'''
        : '''Analyze my financial situation **briefly** (max 150 words). Respond in Markdown format:

**Summary:**
- Net balance and overall status
- Top spending category (top 1)

**Recommendations:**
- 2-3 short bullet points for savings opportunities

Use Markdown: **bold**, *italic*, lists (-).''';

    final financialSummary = {
      'thisMonth': {
        'income': financialData['totalIncome'],
        'expense': financialData['totalExpenses'],
        'balance': financialData['netBalance'],
        'dailyAverage': financialData['averageSpending'],
      },
      'totalBalance': financialData['netBalance'],
    };

      final response = await _aiService.chatWithAI(
      prompt,
      financialSummary: financialSummary,
      language: language,
      currency: currency.code,
      isInsightsAnalysis: true, // Free kullanıcılar için limit bypass
    );

    return response?['message'] as String? ?? '';
  }

  /// Parse AI response and create insights
  AIInsightsSummary _parseAIResponse(String aiMessage, StatisticsData statistics) {
    // Create insights from statistics and AI message
    final insights = <AIInsight>[];

    // Add category insights (top 5)
    for (final category in statistics.categoryBreakdown.take(5)) {
      insights.add(
        AIInsight(
          id: 'category_${category.categoryId}',
          type: 'category',
          title: category.categoryName,
          description: '${category.percentage.toStringAsFixed(1)}% of total expenses',
          icon: _getCategoryIcon(category.categoryIcon),
          color: _getCategoryColor(category.percentage),
          amount: category.amount,
          percentage: category.percentage,
          transactionCount: category.transactionCount,
          categoryId: category.categoryId,
        ),
      );
    }

    // Add savings rate insight
    if (statistics.savingsRate > 0) {
      insights.add(
        AIInsight(
          id: 'savings_rate',
          type: 'recommendation',
          title: 'Tasarruf Oranı',
          description: '${statistics.savingsRate.toStringAsFixed(1)}% tasarruf oranı ile iyi durumdasınız',
          icon: Icons.savings,
          color: Colors.green.shade500,
          percentage: statistics.savingsRate,
        ),
      );
    }

    // Add trend insights
    if (statistics.monthlyTrends.length >= 2) {
      final recent = statistics.monthlyTrends[0];
      final previous = statistics.monthlyTrends[1];
      final expenseChange = recent.expenses - previous.expenses;
      final expenseChangePercent = previous.expenses > 0 
          ? (expenseChange / previous.expenses) * 100 
          : 0;

      if (expenseChangePercent.abs() > 10) {
        insights.add(
          AIInsight(
            id: 'trend_expense',
            type: expenseChangePercent > 0 ? 'warning' : 'trend',
            title: 'Harcama Trendi',
            description: expenseChangePercent > 0
                ? 'Harcamalarınız ${expenseChangePercent.toStringAsFixed(1)}% arttı'
                : 'Harcamalarınız ${expenseChangePercent.abs().toStringAsFixed(1)}% azaldı',
            icon: expenseChangePercent > 0 ? Icons.trending_up : Icons.trending_down,
            color: expenseChangePercent > 0 
                ? const Color(0xFFFF4C4C) 
                : Colors.green.shade500,
            amount: expenseChange.abs(),
            percentage: expenseChangePercent.abs().toDouble(),
          ),
        );
      }
    }

    return AIInsightsSummary(
      overview: aiMessage,
      totalExpenses: statistics.totalExpenses,
      totalIncome: statistics.totalIncome,
      netBalance: statistics.netBalance,
      savingsRate: statistics.savingsRate,
      insights: insights,
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'shopping': Icons.shopping_bag,
      'entertainment': Icons.movie,
      'bills': Icons.receipt,
      'health': Icons.medical_services,
      'education': Icons.school,
      'other': Icons.category,
    };
    return iconMap[iconName.toLowerCase()] ?? Icons.category;
  }

  Color _getCategoryColor(double percentage) {
    if (percentage > 30) return const Color(0xFFFF4C4C);
    if (percentage > 20) return const Color(0xFFFF9500);
    if (percentage > 10) return const Color(0xFFFFC300);
    return Colors.green.shade500;
  }

  String _periodToString(TimePeriod period) {
    switch (period) {
      case TimePeriod.thisMonth:
        return 'Bu Ay';
      case TimePeriod.lastMonth:
        return 'Geçen Ay';
      case TimePeriod.last3Months:
        return 'Son 3 Ay';
      case TimePeriod.last6Months:
        return 'Son 6 Ay';
      case TimePeriod.yearToDate:
        return 'Yıl Başından İtibaren';
    }
  }

  /// Clear cache (manual refresh için)
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Dispose
  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

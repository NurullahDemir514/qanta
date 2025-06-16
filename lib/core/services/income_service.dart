import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/income_category_model.dart';
import '../../shared/models/income_stats_model.dart';
import 'supabase_service.dart';

class IncomeService {
  static final _supabase = SupabaseService.instance.client;

  // Gelir kategorilerini getir
  static Future<List<IncomeCategoryModel>> getIncomeCategories({
    String language = 'tr',
  }) async {
    try {
      final response = await _supabase.rpc('get_income_categories', params: {
        'p_language': language,
      });

      return (response as List)
          .map((json) => IncomeCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gelir kategorileri yüklenirken hata oluştu: $e');
    }
  }

  // Kategori bazlı gelir istatistikleri
  static Future<List<IncomeStatsModel>> getIncomeStatsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('get_income_stats_by_category', params: {
        'p_user_id': currentUser.id,
        'p_start_date': startDate?.toUtc().toIso8601String(),
        'p_end_date': endDate?.toUtc().toIso8601String(),
      });

      return (response as List)
          .map((json) => IncomeStatsModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gelir istatistikleri yüklenirken hata oluştu: $e');
    }
  }

  // Aylık gelir trendi
  static Future<List<MonthlyIncomeTrendModel>> getMonthlyIncomeTrend({
    int months = 12,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('get_monthly_income_trend', params: {
        'p_user_id': currentUser.id,
        'p_months': months,
      });

      return (response as List)
          .map((json) => MonthlyIncomeTrendModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Aylık gelir trendi yüklenirken hata oluştu: $e');
    }
  }

  // Gelir dönem karşılaştırması
  static Future<IncomeComparisonModel> compareIncomePeriods({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('compare_income_periods', params: {
        'p_user_id': currentUser.id,
        'p_current_start': currentStart.toUtc().toIso8601String(),
        'p_current_end': currentEnd.toUtc().toIso8601String(),
        'p_previous_start': previousStart.toUtc().toIso8601String(),
        'p_previous_end': previousEnd.toUtc().toIso8601String(),
      });

      return IncomeComparisonModel.fromJson(response.first);
    } catch (e) {
      throw Exception('Gelir karşılaştırması yüklenirken hata oluştu: $e');
    }
  }

  // En yüksek gelir kaynakları
  static Future<List<TopIncomeSourceModel>> getTopIncomeSources({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('get_top_income_sources', params: {
        'p_user_id': currentUser.id,
        'p_start_date': startDate?.toUtc().toIso8601String(),
        'p_end_date': endDate?.toUtc().toIso8601String(),
        'p_limit': limit,
      });

      return (response as List)
          .map((json) => TopIncomeSourceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('En yüksek gelir kaynakları yüklenirken hata oluştu: $e');
    }
  }

  // Bu ay vs geçen ay hızlı karşılaştırma
  static Future<IncomeComparisonModel> getThisMonthVsLastMonth() async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return compareIncomePeriods(
      currentStart: thisMonthStart,
      currentEnd: thisMonthEnd,
      previousStart: lastMonthStart,
      previousEnd: lastMonthEnd,
    );
  }

  // Bu yıl vs geçen yıl karşılaştırma
  static Future<IncomeComparisonModel> getThisYearVsLastYear() async {
    final now = DateTime.now();
    final thisYearStart = DateTime(now.year, 1, 1);
    final thisYearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    final lastYearStart = DateTime(now.year - 1, 1, 1);
    final lastYearEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);

    return compareIncomePeriods(
      currentStart: thisYearStart,
      currentEnd: thisYearEnd,
      previousStart: lastYearStart,
      previousEnd: lastYearEnd,
    );
  }

  // Kategori bazlı bu ay geliri
  static Future<List<IncomeStatsModel>> getThisMonthIncomeByCategory() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getIncomeStatsByCategory(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  // Kategori bazlı bu yıl geliri
  static Future<List<IncomeStatsModel>> getThisYearIncomeByCategory() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return getIncomeStatsByCategory(
      startDate: startOfYear,
      endDate: endOfYear,
    );
  }
} 
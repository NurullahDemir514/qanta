import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/unified_category_model.dart';
import 'supabase_service.dart';

class UnifiedCategoryService {
  static final _supabase = SupabaseService.instance.client;

  // =====================================================
  // GET CATEGORIES
  // =====================================================

  /// Get all categories for a specific transaction type
  static Future<List<UnifiedCategoryModel>> getCategories({
    required CategoryType categoryType,
    String language = 'tr',
    bool includeUserCategories = true,
  }) async {
    try {
      List<dynamic> response;

      switch (categoryType) {
        case CategoryType.income:
          response = await _supabase.rpc('get_income_categories', params: {
            'p_language': language,
          });
          break;

        case CategoryType.expense:
          response = await _supabase.rpc('get_expense_categories', params: {
            'p_language': language,
            'p_include_user_categories': includeUserCategories,
          });
          break;

        case CategoryType.transfer:
          response = await _supabase.rpc('get_transfer_categories', params: {
            'p_language': language,
          });
          break;

        case CategoryType.other:
          return [];
      }

      return response
          .map((json) => UnifiedCategoryModel.fromJson({
                ...json,
                'category_type': categoryType.name,
              }))
          .toList();
    } catch (e) {
      throw Exception('Kategoriler yüklenirken hata oluştu: $e');
    }
  }

  /// Get all categories (unified)
  static Future<List<UnifiedCategoryModel>> getAllCategories({
    String language = 'tr',
    CategoryType? filterByType,
  }) async {
    try {
      final response = await _supabase.rpc('get_all_categories', params: {
        'p_language': language,
        'p_transaction_type': filterByType?.name,
      });

      return (response as List)
          .map((json) => UnifiedCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Tüm kategoriler yüklenirken hata oluştu: $e');
    }
  }

  /// Get category info by name and type
  static Future<UnifiedCategoryModel?> getCategoryInfo({
    required String categoryName,
    required CategoryType categoryType,
    String language = 'tr',
  }) async {
    try {
      final response = await _supabase.rpc('get_category_info', params: {
        'p_category_name': categoryName,
        'p_transaction_type': categoryType.name,
        'p_language': language,
      });

      if (response.isEmpty) return null;

      return UnifiedCategoryModel.fromJson(response.first);
    } catch (e) {
      throw Exception('Kategori bilgisi yüklenirken hata oluştu: $e');
    }
  }

  // =====================================================
  // CATEGORY STATISTICS
  // =====================================================

  /// Get income statistics by category
  static Future<List<CategoryStatsModel>> getIncomeStatsByCategory({
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
          .map((json) => CategoryStatsModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gelir istatistikleri yüklenirken hata oluştu: $e');
    }
  }

  /// Get expense statistics by category
  static Future<List<CategoryStatsModel>> getExpenseStatsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('get_expense_stats_by_category', params: {
        'p_user_id': currentUser.id,
        'p_start_date': startDate?.toUtc().toIso8601String(),
        'p_end_date': endDate?.toUtc().toIso8601String(),
      });

      return (response as List)
          .map((json) => CategoryStatsModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gider istatistikleri yüklenirken hata oluştu: $e');
    }
  }

  /// Get category usage statistics
  static Future<List<CategoryUsageStatsModel>> getCategoryUsageStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase.rpc('get_category_usage_stats', params: {
        'p_user_id': currentUser.id,
        'p_start_date': startDate?.toUtc().toIso8601String(),
        'p_end_date': endDate?.toUtc().toIso8601String(),
      });

      return (response as List)
          .map((json) => CategoryUsageStatsModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kategori kullanım istatistikleri yüklenirken hata oluştu: $e');
    }
  }

  // =====================================================
  // USER CATEGORIES
  // =====================================================

  /// Create user custom expense category
  static Future<String> createUserExpenseCategory({
    required String name,
    required String displayNameTr,
    required String displayNameEn,
    String? descriptionTr,
    String? descriptionEn,
    String iconName = 'category_rounded',
    String colorHex = '#6B7280',
  }) async {
    try {
      final response = await _supabase.rpc('create_user_expense_category', params: {
        'p_name': name,
        'p_display_name_tr': displayNameTr,
        'p_display_name_en': displayNameEn,
        'p_description_tr': descriptionTr,
        'p_description_en': descriptionEn,
        'p_icon_name': iconName,
        'p_color_hex': colorHex,
      });

      return response as String;
    } catch (e) {
      throw Exception('Özel kategori oluşturulurken hata oluştu: $e');
    }
  }

  // =====================================================
  // CONVENIENCE METHODS
  // =====================================================

  /// Get categories for income transactions
  static Future<List<UnifiedCategoryModel>> getIncomeCategories({
    String language = 'tr',
  }) async {
    return getCategories(
      categoryType: CategoryType.income,
      language: language,
    );
  }

  /// Get categories for expense transactions
  static Future<List<UnifiedCategoryModel>> getExpenseCategories({
    String language = 'tr',
    bool includeUserCategories = true,
  }) async {
    return getCategories(
      categoryType: CategoryType.expense,
      language: language,
      includeUserCategories: includeUserCategories,
    );
  }

  /// Get categories for transfer transactions
  static Future<List<UnifiedCategoryModel>> getTransferCategories({
    String language = 'tr',
  }) async {
    return getCategories(
      categoryType: CategoryType.transfer,
      language: language,
    );
  }

  // =====================================================
  // CACHE MANAGEMENT
  // =====================================================

  static final Map<String, List<UnifiedCategoryModel>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get categories with caching
  static Future<List<UnifiedCategoryModel>> getCategoriesWithCache({
    required CategoryType categoryType,
    String language = 'tr',
    bool includeUserCategories = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${categoryType.name}_${language}_$includeUserCategories';
    final now = DateTime.now();

    // Check cache validity
    if (!forceRefresh && 
        _cache.containsKey(cacheKey) && 
        _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (now.difference(cacheTime) < _cacheExpiry) {
        return _cache[cacheKey]!;
      }
    }

    // Fetch fresh data
    final categories = await getCategories(
      categoryType: categoryType,
      language: language,
      includeUserCategories: includeUserCategories,
    );

    // Update cache
    _cache[cacheKey] = categories;
    _cacheTimestamps[cacheKey] = now;

    return categories;
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for specific category type
  static void clearCacheForType(CategoryType categoryType) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(categoryType.name))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  /// Find category by name in a list
  static UnifiedCategoryModel? findCategoryByName(
    List<UnifiedCategoryModel> categories,
    String name,
  ) {
    try {
      return categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Group categories by type
  static Map<CategoryType, List<UnifiedCategoryModel>> groupCategoriesByType(
    List<UnifiedCategoryModel> categories,
  ) {
    final Map<CategoryType, List<UnifiedCategoryModel>> grouped = {};
    
    for (final category in categories) {
      if (!grouped.containsKey(category.categoryType)) {
        grouped[category.categoryType] = [];
      }
      grouped[category.categoryType]!.add(category);
    }
    
    return grouped;
  }

  /// Sort categories by sort order
  static List<UnifiedCategoryModel> sortCategories(
    List<UnifiedCategoryModel> categories,
  ) {
    final sorted = List<UnifiedCategoryModel>.from(categories);
    sorted.sort((a, b) {
      // First by sort order
      final sortComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortComparison != 0) return sortComparison;
      
      // Then by display name
      return a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }
} 
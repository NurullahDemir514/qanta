import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../../shared/models/models_v2.dart';

/// Service for managing categories (income and expense)
class CategoryServiceV2 {
  static SupabaseClient get _client => SupabaseManager.client;

  /// Get all categories (system + user categories)
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('type')
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Get categories by type
  static Future<List<CategoryModel>> getCategoriesByType(CategoryType type) async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .eq('type', type.value)
          .eq('is_active', true)
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories by type: $e');
      rethrow;
    }
  }

  /// Get system categories only
  static Future<List<CategoryModel>> getSystemCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .isFilter('user_id', null)
          .eq('is_active', true)
          .order('type')
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching system categories: $e');
      rethrow;
    }
  }

  /// Get user categories only
  static Future<List<CategoryModel>> getUserCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .not('user_id', 'is', null)
          .eq('is_active', true)
          .order('type')
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user categories: $e');
      rethrow;
    }
  }

  /// Get income categories
  static Future<List<CategoryModel>> getIncomeCategories() async {
    return getCategoriesByType(CategoryType.income);
  }

  /// Get expense categories
  static Future<List<CategoryModel>> getExpenseCategories() async {
    return getCategoriesByType(CategoryType.expense);
  }

  /// Get category by ID
  static Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .eq('id', categoryId)
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching category by ID: $e');
      return null;
    }
  }

  /// Create a new user category
  static Future<CategoryModel> createCategory({
    required CategoryType type,
    required String name,
    String icon = 'category',
    String color = '#6B7280',
    int sortOrder = 0,
  }) async {
    try {
      // Get current user ID for RLS policy compliance
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('categories')
          .insert({
            'user_id': currentUser.id, // Add user_id for RLS policy
            'type': type.value,
            'name': name,
            'icon': icon,
            'color': color,
            'sort_order': sortOrder,
            'is_active': true,
          })
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating category: $e');
      rethrow;
    }
  }

  /// Update category details
  static Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (icon != null) updateData['icon'] = icon;
      if (color != null) updateData['color'] = color;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      if (isActive != null) updateData['is_active'] = isActive;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('categories')
          .update(updateData)
          .eq('id', categoryId)
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  /// Soft delete category (set is_active to false)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      // Check if it's a system category
      final category = await getCategoryById(categoryId);
      if (category?.isSystemCategory == true) {
        throw Exception('Cannot delete system categories');
      }

      await _client
          .from('categories')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId);
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  /// Search categories by name
  static Future<List<CategoryModel>> searchCategories({
    required String query,
    CategoryType? type,
  }) async {
    try {
      var queryBuilder = _client
          .from('categories')
          .select('*')
          .ilike('name', '%$query%')
          .eq('is_active', true);

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type.value);
      }

      final response = await queryBuilder
          .order('type')
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching categories: $e');
      rethrow;
    }
  }

  /// Check if category name already exists for user
  static Future<bool> categoryNameExists({
    required String name,
    required CategoryType type,
    String? excludeCategoryId,
  }) async {
    try {
      var queryBuilder = _client
          .from('categories')
          .select('id')
          .eq('name', name)
          .eq('type', type.value)
          .eq('is_active', true);

      if (excludeCategoryId != null) {
        queryBuilder = queryBuilder.neq('id', excludeCategoryId);
      }

      final response = await queryBuilder;
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking category name: $e');
      return false;
    }
  }

  /// Get category usage statistics
  static Future<Map<String, int>> getCategoryUsageStats() async {
    try {
      final response = await _client
          .from('transactions')
          .select('category_id')
          .not('category_id', 'is', null);

      final categoryUsage = <String, int>{};
      for (final transaction in response as List) {
        final categoryId = transaction['category_id'] as String;
        categoryUsage[categoryId] = (categoryUsage[categoryId] ?? 0) + 1;
      }

      return categoryUsage;
    } catch (e) {
      debugPrint('Error fetching category usage stats: $e');
      return {};
    }
  }

  /// Get most used categories
  static Future<List<CategoryModel>> getMostUsedCategories({
    CategoryType? type,
    int limit = 5,
  }) async {
    try {
      final usageStats = await getCategoryUsageStats();
      final allCategories = type != null 
          ? await getCategoriesByType(type)
          : await getAllCategories();

      // Sort categories by usage count
      allCategories.sort((a, b) {
        final aUsage = usageStats[a.id] ?? 0;
        final bUsage = usageStats[b.id] ?? 0;
        return bUsage.compareTo(aUsage);
      });

      return allCategories.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching most used categories: $e');
      return [];
    }
  }

  /// Reorder categories
  static Future<void> reorderCategories(List<String> categoryIds) async {
    try {
      for (int i = 0; i < categoryIds.length; i++) {
        await _client
            .from('categories')
            .update({
              'sort_order': i,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', categoryIds[i]);
      }
    } catch (e) {
      debugPrint('Error reordering categories: $e');
      rethrow;
    }
  }
} 
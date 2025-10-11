import 'package:flutter/foundation.dart';
import '../../shared/models/unified_category_model.dart';
import 'firebase_firestore_service.dart';
import 'firebase_auth_service.dart';

class UnifiedCategoryService {
  static const String _collectionName = 'categories';

  // Kategorileri getir
  static Future<List<UnifiedCategoryModel>> getAllCategories() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('is_active', isEqualTo: true)
            .orderBy('sort_order')
            .orderBy('name'),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final categoryData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };
        return UnifiedCategoryModel.fromJson(categoryData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      rethrow;
    }
  }

  // Kategori ekle
  static Future<String> addCategory(UnifiedCategoryModel category) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final categoryData = {
        ...category.toJson(),
        'user_id': userId,
        'is_active': true, // Add missing is_active field
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      };

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: categoryData,
      );

      final docId = docRef.id;
      return docId;
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  // Kategori güncelle
  static Future<bool> updateCategory(UnifiedCategoryModel category) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final categoryData = {
        ...category.toJson(),
        'user_id': userId,
        'is_active': true, // Ensure is_active is set
        'updated_at': DateTime.now(),
      };

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: category.id,
        data: categoryData,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  // Kategori sil
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: categoryId,
        data: {'is_active': false, 'updated_at': DateTime.now()},
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }
}

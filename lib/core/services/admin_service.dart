import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Admin Service
/// Checks if current user is admin and provides admin utilities
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool? _isAdminCache;
  DateTime? _cacheTime;
  
  // Predefined admin user ID
  static const String predefinedAdminUserId = 'obwsYff7JuNBEis9ENvX2pIdIKE2';

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // Check if this is the predefined admin user
      if (userId == predefinedAdminUserId) {
        // Auto-add to admin list if not already added
        await _ensureAdminInList(userId);
        _isAdminCache = true;
        _cacheTime = DateTime.now();
        return true;
      }

      // Check cache (5 minutes)
      if (_isAdminCache != null && 
          _cacheTime != null && 
          DateTime.now().difference(_cacheTime!).inMinutes < 5) {
        return _isAdminCache!;
      }

      final adminDoc = await _firestore
          .collection('admins')
          .doc('admin_list')
          .get();

      if (!adminDoc.exists) {
        _isAdminCache = false;
        _cacheTime = DateTime.now();
        return false;
      }

      final data = adminDoc.data();
      final userIds = List<String>.from(data?['userIds'] ?? []);
      final isAdmin = userIds.contains(userId);

      _isAdminCache = isAdmin;
      _cacheTime = DateTime.now();

      debugPrint('🔍 AdminService: User $userId isAdmin = $isAdmin');
      return isAdmin;
    } catch (e) {
      debugPrint('❌ AdminService: Error checking admin status: $e');
      return false;
    }
  }

  /// Ensure predefined admin user is in admin list
  Future<void> _ensureAdminInList(String userId) async {
    try {
      // Check if already in list (with error handling)
      try {
        final adminDoc = await _firestore
            .collection('admins')
            .doc('admin_list')
            .get();

        if (adminDoc.exists) {
          final data = adminDoc.data();
          final userIds = List<String>.from(data?['userIds'] ?? []);
          if (userIds.contains(userId)) {
            return; // Already in list
          }
        }
      } catch (e) {
        // If we can't read the admin list, try to add via Cloud Function anyway
        debugPrint('⚠️ AdminService: Could not read admin list, will try to add via Cloud Function: $e');
      }

      // Add to admin list via Cloud Function
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('addAdmin');
        await callable.call({'userId': userId});
        debugPrint('✅ AdminService: Predefined admin added to list');
      } catch (e) {
        debugPrint('⚠️ AdminService: Failed to add admin via Cloud Function: $e');
        // This is expected if admin is already in list or Cloud Function fails
      }
    } catch (e) {
      debugPrint('❌ AdminService: Error ensuring admin in list: $e');
      // Don't throw - this is a best-effort operation
    }
  }

  /// Clear admin cache (call after admin status changes)
  void clearCache() {
    _isAdminCache = null;
    _cacheTime = null;
  }

  /// Get admin list (for admin users only)
  Future<List<String>> getAdminList() async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc('admin_list')
          .get();

      if (!adminDoc.exists) return [];

      final data = adminDoc.data();
      return List<String>.from(data?['userIds'] ?? []);
    } catch (e) {
      debugPrint('❌ AdminService: Error getting admin list: $e');
      return [];
    }
  }
}


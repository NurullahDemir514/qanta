import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase client manager for Qanta app
/// Handles Firebase initialization and provides access to Firebase services
class FirebaseManager {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;

  /// Initialize Firebase
  static Future<void> init() async {
    try {
      _app = await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      
      // Configure Firestore settings
      // IMPORTANT: Cache size limited to 40MB to prevent app size growth
      // This prevents Firestore cache from consuming unlimited storage space
      // Users with many transactions may need to fetch data from server more often,
      // but this prevents the app from growing to 400MB+
      _firestore?.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 40 * 1024 * 1024, // 40MB limit (default was unlimited)
      );
      
      debugPrint('✅ Firebase initialized successfully');
      debugPrint('✅ Firebase Auth: ${_auth != null}');
      debugPrint('✅ Firestore: ${_firestore != null}');
      debugPrint('✅ Firebase Storage: ${_storage != null}');
      
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Get Firebase App instance
  static FirebaseApp get app {
    if (_app == null) {
      throw Exception('Firebase not initialized. Call FirebaseManager.init() first.');
    }
    return _app!;
  }

  /// Get Firebase Auth instance
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call FirebaseManager.init() first.');
    }
    return _auth!;
  }

  /// Get Firestore instance
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call FirebaseManager.init() first.');
    }
    return _firestore!;
  }

  /// Get Firebase Storage instance
  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase not initialized. Call FirebaseManager.init() first.');
    }
    return _storage!;
  }

  /// Get current user
  static User? get currentUser => _auth?.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => _auth?.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => _auth?.currentUser?.uid;

  /// Get auth state changes stream
  static Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();
}

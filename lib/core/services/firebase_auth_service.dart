import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_client.dart';

/// Firebase Authentication Service
/// Handles all authentication operations for the Qanta app
class FirebaseAuthService {
  static FirebaseAuth get _auth => FirebaseManager.auth;

  /// Get current user
  static User? get currentUser => FirebaseManager.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => FirebaseManager.isLoggedIn;

  /// Get current user ID
  static String? get currentUserId => FirebaseManager.currentUserId;

  /// Get auth state changes stream
  static Stream<User?> get authStateChanges => FirebaseManager.authStateChanges;

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email and password
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with additional data if provided
      if (additionalData != null && credential.user != null) {
        await credential.user!.updateDisplayName(additionalData['displayName']);
        // Add more profile updates as needed
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.');
      case 'wrong-password':
        return Exception('Hatalı şifre girdiniz.');
      case 'email-already-in-use':
        return Exception('Bu e-posta adresi zaten kullanımda.');
      case 'weak-password':
        return Exception('Şifre çok zayıf. En az 6 karakter olmalıdır.');
      case 'invalid-email':
        return Exception('Geçersiz e-posta adresi.');
      case 'user-disabled':
        return Exception('Bu hesap devre dışı bırakılmış.');
      case 'too-many-requests':
        return Exception('Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.');
      case 'operation-not-allowed':
        return Exception('Bu işlem şu anda izin verilmiyor.');
      default:
        return Exception('Kimlik doğrulama hatası: ${e.message}');
    }
  }
}

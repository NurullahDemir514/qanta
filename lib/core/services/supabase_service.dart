import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../supabase_client.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient get client => SupabaseManager.client;
  
  // Authentication methods
  User? get currentUser => SupabaseManager.currentUser;
  
  bool get isLoggedIn => SupabaseManager.isLoggedIn;
  
  String? get currentUserId => SupabaseManager.currentUserId;
  
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
  
  // Database methods
  SupabaseQueryBuilder from(String table) => client.from(table);
  
  SupabaseStorageClient get storage => client.storage;
} 
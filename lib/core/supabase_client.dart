import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseManager {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  
  // Helper methods for common operations
  static bool get isLoggedIn => client.auth.currentUser != null;
  
  static User? get currentUser => client.auth.currentUser;
  
  static String? get currentUserId => client.auth.currentUser?.id;
} 
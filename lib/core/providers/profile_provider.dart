import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../services/profile_image_service.dart';

class ProfileProvider extends ChangeNotifier {
  String? _profileImageUrl;
  String? _userName;
  String? _userEmail;
  bool _isLoading = false;

  // Getters
  String? get profileImageUrl => _profileImageUrl;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;

  ProfileProvider() {
    _loadProfileData();
  }

  /// Profil verilerini yükle
  Future<void> _loadProfileData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        _userName = user.userMetadata?['full_name'] as String?;
        _userEmail = user.email;
        _profileImageUrl = ProfileImageService.instance.getProfileImageUrl();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading profile data: $e');
    }
  }

  /// Profil fotoğrafını güncelle
  Future<void> updateProfileImage(String? newImageUrl) async {
    _profileImageUrl = newImageUrl;
    notifyListeners();
  }

  /// Profil verilerini yenile
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadProfileData();
    } catch (e) {
      debugPrint('❌ Error refreshing profile data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı adını güncelle
  Future<void> updateUserName(String? newUserName) async {
    _userName = newUserName;
    notifyListeners();
  }

  /// Kullanıcı email'ini güncelle
  Future<void> updateUserEmail(String? newUserEmail) async {
    _userEmail = newUserEmail;
    notifyListeners();
  }

  /// Profil verilerini temizle (logout)
  void clearProfile() {
    _profileImageUrl = null;
    _userName = null;
    _userEmail = null;
    _isLoading = false;
    notifyListeners();
  }
} 
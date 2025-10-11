import 'package:flutter/foundation.dart';
import '../services/firebase_auth_service.dart';
import '../services/profile_image_service.dart';
import '../services/image_cache_service.dart';

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
      final user = FirebaseAuthService.currentUser;
      debugPrint('👤 ProfileProvider._loadProfileData() - Loading profile data:');
      debugPrint('   User: ${user?.email}');
      debugPrint('   User ID: ${user?.uid}');
      
      if (user != null) {
        _userName = user.displayName;
        _userEmail = user.email;

        // Load cached profile image URL
        debugPrint('🖼️ Loading cached profile image...');
        await ProfileImageService.instance.loadCachedImageUrl();
        _profileImageUrl = await ProfileImageService.instance.getProfileImageUrl();
        
        // If no cached image, try to load from SharedPreferences
        if (_profileImageUrl == null) {
          debugPrint('🔄 No cached image found, checking SharedPreferences...');
          await ProfileImageService.instance.loadCachedImageUrl();
          _profileImageUrl = await ProfileImageService.instance.getProfileImageUrl();
        }
        
        debugPrint('✅ Profile data loaded:');
        debugPrint('   Name: $_userName');
        debugPrint('   Email: $_userEmail');
        debugPrint('   Profile Image URL: $_profileImageUrl');

        notifyListeners();
      } else {
        debugPrint('❌ No user found - cannot load profile data');
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
  Future<void> clearProfile() async {
    try {
      // Clear profile image memory cache only (keep SharedPreferences)
      await ProfileImageService.instance.clearCache();

      // Clear image cache
      await ImageCacheService.instance.clearCache();
    } catch (e) {
      debugPrint('Error clearing profile image cache: $e');
    }

    _profileImageUrl = null;
    _userName = null;
    _userEmail = null;
    _isLoading = false;
    notifyListeners();
  }
}

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
      if (user != null) {
        _userName = user.displayName;
        _userEmail = user.email;
        
        // Load cached profile image URL
        await ProfileImageService.instance.loadCachedImageUrl();
        _profileImageUrl = ProfileImageService.instance.getProfileImageUrl();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
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
      // Clear profile image cache
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

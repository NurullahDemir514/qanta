import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_storage_service.dart';
import 'firebase_auth_service.dart';
import 'encryption_service.dart';

/// Profile Image Service - Manages profile image uploads using Firebase Storage
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  static ProfileImageService get instance => _instance;

  // Cache for profile image URL
  String? _cachedImageUrl;
  static const String _profileImageUrlKey = 'profile_image_url';

  /// Get profile image URL from cache or SharedPreferences
  String? getProfileImageUrl() {
    if (_cachedImageUrl != null) {
      // Security check: Verify URL belongs to current user
      final userId = FirebaseAuthService.currentUserId;
      if (userId != null && _isUrlForCurrentUser(_cachedImageUrl!, userId)) {
        return _cachedImageUrl;
      } else {
        // Clear invalid cache
        _cachedImageUrl = null;
        _saveImageUrlToCache(null);
      }
    }
    return null;
  }

  /// Security check: Verify URL belongs to current user
  bool _isUrlForCurrentUser(String imageUrl, String userId) {
    try {
      // Check if URL contains the user's ID (handle both encoded and non-encoded paths)
      final expectedPath = 'users/$userId/profile-images/';
      final encodedPath = 'users%2F$userId%2Fprofile-images%2F';
      
      return imageUrl.contains(expectedPath) || imageUrl.contains(encodedPath);
    } catch (e) {
      debugPrint('❌ Error checking URL ownership: $e');
      return false;
    }
  }

  /// Load profile image URL from SharedPreferences
  Future<void> loadCachedImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedImageUrl = prefs.getString(_profileImageUrlKey);
    } catch (e) {
      debugPrint('Error loading cached profile image URL: $e');
    }
  }

  /// Save profile image URL to SharedPreferences
  Future<void> _saveImageUrlToCache(String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (imageUrl != null) {
        await prefs.setString(_profileImageUrlKey, imageUrl);
      } else {
        await prefs.remove(_profileImageUrlKey);
      }
      _cachedImageUrl = imageUrl;
    } catch (e) {
      debugPrint('Error saving profile image URL to cache: $e');
    }
  }

  /// Ensure bucket exists (not needed for Firebase Storage)
  Future<void> ensureBucketExists() async {
    // Firebase Storage doesn't require bucket creation
    // This method is kept for compatibility
    debugPrint('ProfileImageService.ensureBucketExists() - No action needed for Firebase Storage');
  }

  /// Upload profile image to Firebase Storage (encrypted)
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      debugPrint('🔄 ProfileImageService.uploadProfileImage() - Starting encrypted upload');
      debugPrint('📁 Image path: $imagePath');
      
      final file = File(imagePath);
      
      // Validate file exists
      if (!await file.exists()) {
        debugPrint('❌ File does not exist: $imagePath');
        throw Exception('File not found');
      }
      debugPrint('✅ File exists, size: ${await file.length()} bytes');

      // Validate file size (max 5MB)
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        debugPrint('❌ File too large: ${fileSize} bytes (max: $maxSize)');
        throw Exception('File too large (max 5MB)');
      }
      debugPrint('✅ File size OK: ${fileSize} bytes');

      // Initialize encryption for current user
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception('User session not found');
      }
      await EncryptionService.instance.initialize(userId);

      // Delete old profile image if exists
      debugPrint('🗑️ Deleting old profile image...');
      await _deleteOldProfileImage();

      // Encrypt file before upload
      debugPrint('🔐 Encrypting file...');
      final encryptedFile = await EncryptionService.instance.createEncryptedTempFile(file);
      debugPrint('✅ File encrypted successfully');

      // Upload encrypted image
      debugPrint('☁️ Uploading encrypted file to Firebase Storage...');
      final downloadUrl = await FirebaseStorageService.uploadFile(
        file: encryptedFile,
        folder: 'profile-images',
        customFileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.enc',
      );

      // Clean up temporary encrypted file
      try {
        await encryptedFile.delete();
        debugPrint('🗑️ Temporary encrypted file deleted');
      } catch (e) {
        debugPrint('⚠️ Failed to delete temporary file: $e');
      }

      debugPrint('✅ Encrypted upload successful! URL: $downloadUrl');

      // Save to cache
      debugPrint('💾 Saving to cache...');
      await _saveImageUrlToCache(downloadUrl);

      debugPrint('🎉 Encrypted profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Delete profile image from Firebase Storage
  Future<void> deleteProfileImage() async {
    try {
      await _deleteOldProfileImage();
      await _saveImageUrlToCache(null);
      debugPrint('Profile image deleted successfully');
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      rethrow;
    }
  }

  /// Delete old profile image from storage
  Future<void> _deleteOldProfileImage() async {
    try {
      final currentUrl = _cachedImageUrl;
      if (currentUrl != null && currentUrl.isNotEmpty) {
        await FirebaseStorageService.deleteFileByUrl(currentUrl);
        debugPrint('Old profile image deleted from storage');
      }
    } catch (e) {
      // Don't throw error if old image doesn't exist
      debugPrint('Error deleting old profile image (may not exist): $e');
    }
  }

  /// Get profile image file path in storage
  String _getProfileImagePath() {
    final userId = FirebaseAuthService.currentUserId;
    if (userId == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }
    return 'users/$userId/profile-images/profile.jpg';
  }

  /// Clear all cached data (for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageUrlKey);
      _cachedImageUrl = null;
      debugPrint('Profile image cache cleared');
    } catch (e) {
      debugPrint('Error clearing profile image cache: $e');
    }
  }
}
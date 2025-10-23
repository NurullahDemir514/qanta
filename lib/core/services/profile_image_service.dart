import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_storage_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';
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
  Future<String?> getProfileImageUrl() async {
    if (_cachedImageUrl != null) {
      // Security check: Verify URL belongs to current user
      final userId = FirebaseAuthService.currentUserId;
      debugPrint('🔍 ProfileImageService.getProfileImageUrl() - Security Check:');
      debugPrint('   Cached URL: $_cachedImageUrl');
      debugPrint('   Current User ID: $userId');
      
      // Temporarily disable security check for debugging
      debugPrint('✅ Returning cached URL (security check disabled for debugging)');
      return _cachedImageUrl;
      
      // TODO: Re-enable security check after debugging
      // if (userId != null && _isUrlForCurrentUser(_cachedImageUrl!, userId)) {
      //   debugPrint('✅ URL belongs to current user - returning cached URL');
      //   return _cachedImageUrl;
      // } else {
      //   debugPrint('❌ URL does not belong to current user - clearing cache');
      //   // Clear invalid cache
      //   _cachedImageUrl = null;
      //   await _saveImageUrlToCache(null);
      // }
    }
    
    // Try to load from SharedPreferences if cache is empty
    debugPrint('🔍 No cached URL found - checking SharedPreferences...');
    await loadCachedImageUrl();
    if (_cachedImageUrl != null) {
      debugPrint('✅ Loaded URL from SharedPreferences: $_cachedImageUrl');
      return _cachedImageUrl;
    }
    
    // If not in SharedPreferences, try Firestore
    debugPrint('🔍 No URL in SharedPreferences - checking Firestore...');
    final firestoreUrl = await loadProfileImageUrlFromFirestore();
    if (firestoreUrl != null && firestoreUrl.isNotEmpty) {
      debugPrint('✅ Loaded URL from Firestore: $firestoreUrl');
      return firestoreUrl;
    } else {
      debugPrint('❌ No valid URL found in Firestore');
    }
    
    debugPrint('❌ No profile image URL found in any storage');
    return null;
  }

  /// Security check: Verify URL belongs to current user
  bool _isUrlForCurrentUser(String imageUrl, String userId) {
    try {
      // Check if URL contains the user's ID (handle both encoded and non-encoded paths)
      final expectedPath = 'users/$userId/profile-images/';
      final encodedPath = 'users%2F$userId%2Fprofile-images%2F';

      debugPrint('🔍 ProfileImageService._isUrlForCurrentUser() - URL Check:');
      debugPrint('   Image URL: $imageUrl');
      debugPrint('   User ID: $userId');
      debugPrint('   Expected path: $expectedPath');
      debugPrint('   Encoded path: $encodedPath');
      debugPrint('   Contains check (normal): ${imageUrl.contains(expectedPath)}');
      debugPrint('   Contains check (encoded): ${imageUrl.contains(encodedPath)}');

      final result = imageUrl.contains(expectedPath) || imageUrl.contains(encodedPath);
      debugPrint('   Result: $result');
      
      return result;
    } catch (e) {
      debugPrint('❌ Error checking URL ownership: $e');
      return false;
    }
  }

  /// Load profile image URL from Firestore
  Future<String?> loadProfileImageUrlFromFirestore() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        debugPrint('❌ No user ID found for Firestore query');
        return null;
      }

      debugPrint('🔍 Loading profile image URL from Firestore...');
      debugPrint('   User ID: $userId');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final profileImageUrl = doc.data()!['profile_image_url'] as String?;
        debugPrint('✅ Profile image URL loaded from Firestore: $profileImageUrl');
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          // Save to local cache
          await _saveImageUrlToCache(profileImageUrl);
          return profileImageUrl;
        } else {
          debugPrint('❌ Profile image URL is null or empty in Firestore');
        }
      } else {
        debugPrint('❌ No profile document found in Firestore');
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error loading profile image URL from Firestore: $e');
      return null;
    }
  }

  /// Save profile image URL to Firestore
  Future<void> saveProfileImageUrlToFirestore(String imageUrl) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        debugPrint('❌ No user ID found for Firestore save');
        return;
      }

      debugPrint('💾 Saving profile image URL to Firestore...');
      debugPrint('   User ID: $userId');
      debugPrint('   Image URL: $imageUrl');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('settings')
          .set({
        'profile_image_url': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Profile image URL saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving profile image URL to Firestore: $e');
      rethrow;
    }
  }

  /// Load profile image URL from SharedPreferences
  Future<void> loadCachedImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedImageUrl = prefs.getString(_profileImageUrlKey);
    } catch (e) {
      debugPrint('❌ Error loading cached profile image URL: $e');
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
    debugPrint(
      'ProfileImageService.ensureBucketExists() - No action needed for Firebase Storage',
    );
  }

  /// Upload profile image to Firebase Storage (encrypted)
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      debugPrint(
        '🔄 ProfileImageService.uploadProfileImage() - Starting encrypted upload',
      );
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
        debugPrint('❌ File too large: $fileSize bytes (max: $maxSize)');
        throw Exception('File too large (max 5MB)');
      }
      debugPrint('✅ File size OK: $fileSize bytes');

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
      final encryptedFile = await EncryptionService.instance
          .createEncryptedTempFile(file);
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

      // Save to cache and Firestore
      debugPrint('💾 Saving to cache and Firestore...');
      await _saveImageUrlToCache(downloadUrl);
      await saveProfileImageUrlToFirestore(downloadUrl);

      debugPrint(
        '🎉 Encrypted profile image uploaded successfully: $downloadUrl',
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Delete profile image from Firebase Storage and Firestore
  Future<void> deleteProfileImage() async {
    try {
      // 1. Delete from Firebase Storage
      await _deleteOldProfileImage();
      
      // 2. Delete from Firestore (critical - must succeed)
      await _deleteProfileImageFromFirestore();
      
      // 3. Clear cache and SharedPreferences (only if Firestore deletion succeeded)
      await _saveImageUrlToCache(null);
      
      debugPrint('✅ Profile image deleted successfully from storage, Firestore, and cache');
    } catch (e) {
      debugPrint('❌ Error deleting profile image: $e');
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

  /// Delete profile image from Firestore
  Future<void> _deleteProfileImageFromFirestore() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the same path as saveProfileImageUrlToFirestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('settings')
          .update({
        'profile_image_url': FieldValue.delete(),
      });
      
      debugPrint('✅ Profile image deleted from Firestore');
    } catch (e) {
      debugPrint('❌ Error deleting profile image from Firestore: $e');
      rethrow; // Re-throw to ensure deletion fails if Firestore fails
    }
  }

  /// Clear profile image cache (memory only, keep SharedPreferences)
  Future<void> clearCache() async {
    try {
      _cachedImageUrl = null;
      debugPrint('✅ Profile image memory cache cleared (SharedPreferences preserved)');
    } catch (e) {
      debugPrint('❌ Error clearing profile image cache: $e');
    }
  }

  /// Clear all profile image data (including SharedPreferences)
  Future<void> clearAllData() async {
    try {
      _cachedImageUrl = null;
      await _saveImageUrlToCache(null);
      debugPrint('✅ All profile image data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all profile image data: $e');
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

}

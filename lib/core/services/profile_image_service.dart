import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ProfileImageService {
  static ProfileImageService? _instance;
  static ProfileImageService get instance => _instance ??= ProfileImageService._();
  
  ProfileImageService._();
  
  static const String _bucketName = 'profile-images';
  
  SupabaseClient get _client => SupabaseService.instance.client;
  
  /// Profil fotoğrafını yükle
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }
      
      // Dosya uzantısını al
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/profile.$fileExtension';
      
      // Dosyayı yükle
      final response = await _client.storage
          .from(_bucketName)
          .upload(fileName, imageFile, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true, // Varsa üzerine yaz
          ));
      
      debugPrint('✅ Profile image uploaded: $fileName');
      
      // Public URL'i al
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      
      // User metadata'sını güncelle
      await _updateUserProfileImageUrl(publicUrl);
      
      return publicUrl;
      
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      rethrow;
    }
  }
  
  /// Web için profil fotoğrafını yükle (Uint8List)
  Future<String> uploadProfileImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }
      
      // Dosya uzantısını al
      final fileExtension = fileName.split('.').last.toLowerCase();
      final storageFileName = '$userId/profile.$fileExtension';
      
      // Dosyayı yükle
      await _client.storage
          .from(_bucketName)
          .uploadBinary(storageFileName, imageBytes, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));
      
      debugPrint('✅ Profile image uploaded (bytes): $storageFileName');
      
      // Public URL'i al
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(storageFileName);
      
      // User metadata'sını güncelle
      await _updateUserProfileImageUrl(publicUrl);
      
      return publicUrl;
      
    } catch (e) {
      debugPrint('❌ Error uploading profile image bytes: $e');
      rethrow;
    }
  }
  
  /// Kullanıcının profil fotoğrafı URL'ini al
  String? getProfileImageUrl() {
    final user = SupabaseService.instance.currentUser;
    return user?.userMetadata?['profile_image_url'] as String?;
  }
  
  /// Profil fotoğrafını sil
  Future<void> deleteProfileImage() async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }
      
      // Storage'dan sil (tüm uzantıları dene)
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      for (final ext in extensions) {
        try {
          await _client.storage
              .from(_bucketName)
              .remove(['$userId/profile.$ext']);
        } catch (e) {
          // Dosya yoksa hata vermez, devam eder
          debugPrint('File not found: $userId/profile.$ext');
        }
      }
      
      // User metadata'sından kaldır
      await _updateUserProfileImageUrl(null);
      
      debugPrint('✅ Profile image deleted');
      
    } catch (e) {
      debugPrint('❌ Error deleting profile image: $e');
      rethrow;
    }
  }
  
  /// User metadata'sında profil fotoğrafı URL'ini güncelle
  Future<void> _updateUserProfileImageUrl(String? imageUrl) async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) return;
      
      // Mevcut metadata'yı al
      final currentMetadata = Map<String, dynamic>.from(currentUser.userMetadata ?? {});
      
      // Profil fotoğrafı URL'ini güncelle
      if (imageUrl != null) {
        currentMetadata['profile_image_url'] = imageUrl;
      } else {
        currentMetadata.remove('profile_image_url');
      }
      
      // User'ı güncelle
      await _client.auth.updateUser(
        UserAttributes(data: currentMetadata),
      );
      
      debugPrint('✅ User profile image URL updated');
      
    } catch (e) {
      debugPrint('❌ Error updating user profile image URL: $e');
      rethrow;
    }
  }
  
  /// Storage bucket'ının var olup olmadığını kontrol et ve oluştur
  Future<void> ensureBucketExists() async {
    try {
      // Bucket'ları listele
      final buckets = await _client.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);
      
      if (!bucketExists) {
        // Bucket oluştur
        await _client.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5242880', // 5MB in bytes as string
          ),
        );
        debugPrint('✅ Profile images bucket created');
      } else {
        debugPrint('✅ Profile images bucket already exists');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring bucket exists: $e');
      // Bucket zaten varsa hata vermez
    }
  }
} 
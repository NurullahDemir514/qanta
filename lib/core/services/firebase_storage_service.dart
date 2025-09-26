import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'firebase_auth_service.dart';

/// Firebase Storage Service
/// Handles file uploads, downloads, and management for Qanta app
class FirebaseStorageService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Get current user ID
  static String? get _currentUserId => FirebaseAuthService.currentUserId;

  /// Upload a file to Firebase Storage
  static Future<String> uploadFile({
    required File file,
    required String folder,
    String? customFileName,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final fileName = customFileName ?? path.basename(file.path);
      final filePath = 'users/$userId/$folder/$fileName';
      
      final ref = _storage.ref().child(filePath);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload CSV file for data import
  static Future<String> uploadCSVFile({
    required File file,
    required String tableName,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final fileName = '${tableName}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = 'users/$userId/tables/$fileName';
      
      final ref = _storage.ref().child(filePath);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image file
  static Future<String> uploadImageFile({
    required File file,
    required String folder,
    String? customFileName,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final fileName = customFileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'users/$userId/images/$folder/$fileName';
      
      final ref = _storage.ref().child(filePath);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Download file from Firebase Storage
  static Future<File> downloadFile({
    required String downloadUrl,
    required String localPath,
  }) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final file = File(localPath);
      
      await ref.writeToFile(file);
      
      return file;
    } catch (e) {
      rethrow;
    }
  }

  /// Get download URL for a file
  static Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// List files in a folder
  static Future<List<Reference>> listFiles({
    required String folder,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final ref = _storage.ref().child('users/$userId/$folder');
      final result = await ref.listAll();
      
      return result.items;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file from Firebase Storage
  static Future<void> deleteFile(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
      
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file by download URL
  static Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      
    } catch (e) {
      rethrow;
    }
  }

  /// Get file metadata
  static Future<FullMetadata> getFileMetadata(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      final metadata = await ref.getMetadata();
      
      return metadata;
    } catch (e) {
      rethrow;
    }
  }

  /// Update file metadata
  static Future<void> updateFileMetadata({
    required String filePath,
    required Map<String, String> customMetadata,
  }) async {
    try {
      final ref = _storage.ref().child(filePath);
      final metadata = SettableMetadata(customMetadata: customMetadata);
      
      await ref.updateMetadata(metadata);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple files
  static Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String folder,
  }) async {
    try {
      final downloadUrls = <String>[];
      
      for (final file in files) {
        final downloadUrl = await uploadFile(
          file: file,
          folder: folder,
        );
        downloadUrls.add(downloadUrl);
      }
      
      return downloadUrls;
    } catch (e) {
      rethrow;
    }
  }

  /// Get storage usage for current user
  static Future<StorageUsage> getStorageUsage() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final ref = _storage.ref().child('users/$userId');
      final result = await ref.listAll();
      
      int totalSize = 0;
      int fileCount = 0;
      
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
        fileCount++;
      }
      
      return StorageUsage(
        totalSize: totalSize,
        fileCount: fileCount,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Clean up old files (older than specified days)
  static Future<void> cleanupOldFiles({
    required String folder,
    required int daysOld,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final ref = _storage.ref().child('users/$userId/$folder');
      final result = await ref.listAll();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        final createdAt = metadata.timeCreated;
        
        if (createdAt != null && createdAt.isBefore(cutoffDate)) {
          await item.delete();
        }
      }
      
    } catch (e) {
      rethrow;
    }
  }
}

/// Storage usage information
class StorageUsage {
  final int totalSize;
  final int fileCount;

  StorageUsage({
    required this.totalSize,
    required this.fileCount,
  });

  /// Get total size in MB
  double get totalSizeMB => totalSize / (1024 * 1024);

  /// Get total size in GB
  double get totalSizeGB => totalSizeMB / 1024;

  /// Get formatted size string
  String get formattedSize {
    if (totalSizeGB >= 1) {
      return '${totalSizeGB.toStringAsFixed(2)} GB';
    } else {
      return '${totalSizeMB.toStringAsFixed(2)} MB';
    }
  }
}

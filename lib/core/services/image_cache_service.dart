import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Image Cache Service - Manages local caching of profile images
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static ImageCacheService get instance => _instance;

  // Cache configuration
  // Profile images: Users have only 1 profile photo (max 5MB per photo)
  // Cache limit set to 5MB since we only cache current user's single profile photo
  // This is much lower than before (was 30MB) since we don't need to cache multiple photos
  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB (sufficient for 1 profile photo)
  static const int _maxCacheAge = 7 * 24 * 60 * 60; // 7 days (keep cached for a week)
  static const String _cacheFolder = 'profile_images';

  /// Get cache directory
  Future<Directory> get _cacheDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheFolder');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get cached image file path
  Future<File> _getCachedImageFile(String url) async {
    final cacheDir = await _cacheDirectory;
    final cacheKey = _generateCacheKey(url);
    return File('${cacheDir.path}/$cacheKey.jpg');
  }

  /// Get cache metadata file path
  Future<File> _getCacheMetadataFile(String url) async {
    final cacheDir = await _cacheDirectory;
    final cacheKey = _generateCacheKey(url);
    return File('${cacheDir.path}/$cacheKey.meta');
  }

  /// Check if image is cached and valid
  Future<bool> isCached(String url) async {
    try {
      final imageFile = await _getCachedImageFile(url);
      final metadataFile = await _getCacheMetadataFile(url);

      if (!await imageFile.exists() || !await metadataFile.exists()) {
        return false;
      }

      // Check cache age
      final metadata = await metadataFile.readAsString();
      final timestamp = int.tryParse(metadata) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (now - timestamp > _maxCacheAge) {
        // Cache expired, delete files
        await imageFile.delete();
        await metadataFile.delete();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking cache: $e');
      return false;
    }
  }

  /// Get cached image data
  Future<Uint8List?> getCachedImage(String url) async {
    try {
      if (!await isCached(url)) {
        return null;
      }

      final imageFile = await _getCachedImageFile(url);
      final imageData = await imageFile.readAsBytes();

      debugPrint('✅ Image loaded from cache: ${imageData.length} bytes');
      return imageData;
    } catch (e) {
      debugPrint('❌ Error loading cached image: $e');
      return null;
    }
  }

  /// Cache image data
  Future<void> cacheImage(String url, Uint8List imageData) async {
    try {
      // Check cache size before adding
      await _cleanupCacheIfNeeded();

      final imageFile = await _getCachedImageFile(url);
      final metadataFile = await _getCacheMetadataFile(url);

      // Save image data
      await imageFile.writeAsBytes(imageData);

      // Save metadata (timestamp)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await metadataFile.writeAsString(timestamp.toString());

      debugPrint('✅ Image cached: ${imageData.length} bytes');
    } catch (e) {
      debugPrint('❌ Error caching image: $e');
    }
  }

  /// Clean up cache if size exceeds limit
  Future<void> _cleanupCacheIfNeeded() async {
    try {
      final cacheDir = await _cacheDirectory;
      final files = await cacheDir.list().toList();

      int totalSize = 0;
      final fileInfo = <MapEntry<File, int>>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final size = await file.length();
          totalSize += size;
          fileInfo.add(MapEntry(file, size));
        }
      }

      if (totalSize > _maxCacheSize) {
        debugPrint('🧹 Cache size exceeded ($totalSize bytes), cleaning up...');

        // Sort by modification time (oldest first)
        fileInfo.sort((a, b) {
          final aTime = a.key.statSync().modified.millisecondsSinceEpoch;
          final bTime = b.key.statSync().modified.millisecondsSinceEpoch;
          return aTime.compareTo(bTime);
        });

        // Delete oldest files until under limit
        for (final fileEntry in fileInfo) {
          if (totalSize <= _maxCacheSize) break;

          final file = fileEntry.key;
          final size = fileEntry.value;
          await file.delete();
          totalSize -= size.toInt();

          // Also delete metadata file
          final metadataFile = File(file.path.replaceAll('.jpg', '.meta'));
          if (await metadataFile.exists()) {
            await metadataFile.delete();
          }
        }

        debugPrint('✅ Cache cleanup completed. New size: $totalSize bytes');
      }
    } catch (e) {
      debugPrint('❌ Error during cache cleanup: $e');
    }
  }

  /// Remove specific cached image
  Future<void> removeCachedImage(String url) async {
    try {
      final imageFile = await _getCachedImageFile(url);
      final metadataFile = await _getCacheMetadataFile(url);
      
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      debugPrint('❌ Error removing cached image: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('✅ All cached images cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clear cache for specific user
  Future<void> clearUserCache(String userId) async {
    try {
      final cacheDir = await _cacheDirectory;
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file is File && file.path.contains(userId)) {
          await file.delete();
        }
      }

      debugPrint('✅ Cache cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await _cacheDirectory;
      final files = await cacheDir.list().toList();

      int totalSize = 0;
      int imageCount = 0;
      int metadataCount = 0;

      for (final file in files) {
        if (file is File) {
          final size = await file.length();
          totalSize += size;

          if (file.path.endsWith('.jpg')) {
            imageCount++;
          } else if (file.path.endsWith('.meta')) {
            metadataCount++;
          }
        }
      }

      return {
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'imageCount': imageCount,
        'metadataCount': metadataCount,
        'maxSizeMB': (_maxCacheSize / (1024 * 1024)).toStringAsFixed(0),
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }
}

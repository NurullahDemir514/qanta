import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_cache_service.dart';
import 'unified_cache_manager.dart';

/// Cache Cleanup Service
/// Manages periodic cleanup of all cache systems to prevent app size growth
class CacheCleanupService {
  static final CacheCleanupService _instance = CacheCleanupService._internal();
  factory CacheCleanupService() => _instance;
  CacheCleanupService._internal();

  static CacheCleanupService get instance => _instance;

  /// Perform comprehensive cache cleanup on app startup
  /// This is called once per app launch to prevent cache accumulation
  Future<void> performStartupCleanup() async {
    try {
      debugPrint('🧹 Starting cache cleanup...');
      
      // 1. Clean expired unified cache
      try {
        await UnifiedCacheManager.instance.initialize();
        debugPrint('✅ Unified cache cleaned');
      } catch (e) {
        debugPrint('⚠️ Unified cache cleanup error: $e');
      }

      // 2. Clean expired image cache (automatic via ImageCacheService)
      // Profile images: Only 1 photo per user, so cache should be small (<5MB)
      try {
        final imageStats = await ImageCacheService.instance.getCacheStats();
        final imageSizeMB = double.tryParse(imageStats['totalSizeMB']?.toString() ?? '0') ?? 0;
        if (imageSizeMB > 4) {
          // If image cache exceeds 4MB (limit is 5MB), force cleanup
          // This should rarely happen since users only have 1 profile photo
          debugPrint('⚠️ Image cache is ${imageSizeMB.toStringAsFixed(2)}MB (limit: 5MB), forcing cleanup');
          await ImageCacheService.instance.clearCache();
          debugPrint('✅ Image cache cleared');
        }
      } catch (e) {
        debugPrint('⚠️ Image cache cleanup error: $e');
      }

      // 3. Clean temporary files from app directories
      await _cleanupTemporaryFiles();

      debugPrint('✅ Cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Cache cleanup error: $e');
    }
  }

  /// Clean temporary files from app directories
  Future<void> _cleanupTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final files = await tempDir.list().toList();
        int deletedCount = 0;
        int deletedSize = 0;

        for (final file in files) {
          if (file is File) {
            try {
              final size = await file.length();
              // Delete files older than 7 days
              final stat = await file.stat();
              final age = DateTime.now().difference(stat.modified);
              if (age.inDays > 7) {
                await file.delete();
                deletedCount++;
                deletedSize += size;
              }
            } catch (e) {
              // Skip files that can't be deleted
            }
          }
        }

        if (deletedCount > 0) {
          debugPrint('✅ Cleaned $deletedCount temp files (${(deletedSize / (1024 * 1024)).toStringAsFixed(2)}MB)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Temporary files cleanup error: $e');
    }
  }

  /// Get total cache size across all cache systems
  Future<Map<String, dynamic>> getTotalCacheSize() async {
    try {
      int totalSize = 0;
      final details = <String, dynamic>{};

      // Image cache size
      try {
        final imageStats = await ImageCacheService.instance.getCacheStats();
        final imageSize = imageStats['totalSize'] as int? ?? 0;
        totalSize += imageSize;
        details['imageCache'] = {
          'size': imageSize,
          'sizeMB': (imageSize / (1024 * 1024)).toStringAsFixed(2),
          'count': imageStats['imageCount'] ?? 0,
        };
      } catch (e) {
        details['imageCache'] = {'error': e.toString()};
      }

      // Unified cache size
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final unifiedCacheDir = Directory('${appDir.path}/unified_cache');
        if (await unifiedCacheDir.exists()) {
          int unifiedSize = 0;
          final files = await unifiedCacheDir.list().toList();
          for (final file in files) {
            if (file is File) {
              unifiedSize += await file.length();
            }
          }
          totalSize += unifiedSize;
          details['unifiedCache'] = {
            'size': unifiedSize,
            'sizeMB': (unifiedSize / (1024 * 1024)).toStringAsFixed(2),
            'count': files.length,
          };
        }
      } catch (e) {
        details['unifiedCache'] = {'error': e.toString()};
      }

      // Firestore cache (estimated, as we can't directly measure it)
      // We set a 40MB limit, so we assume it's using some portion
      details['firestoreCache'] = {
        'size': 0, // Cannot directly measure
        'sizeMB': '0.00',
        'limitMB': '40',
        'note': 'Firestore cache is limited to 40MB and managed automatically',
      };

      return {
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'details': details,
      };
    } catch (e) {
      debugPrint('❌ Error getting total cache size: $e');
      return {
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'error': e.toString(),
      };
    }
  }

  /// Force cleanup all caches (for manual cleanup by user)
  Future<void> clearAllCaches() async {
    try {
      debugPrint('🧹 Force clearing all caches...');
      
      await ImageCacheService.instance.clearCache();
      await UnifiedCacheManager.instance.clearAll();
      await _cleanupTemporaryFiles();
      
      debugPrint('✅ All caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all caches: $e');
      rethrow;
    }
  }

  /// Cleanup old cache based on last cleanup time
  /// This prevents too frequent cleanups
  Future<void> performPeriodicCleanup({Duration? interval}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanupKey = 'last_cache_cleanup_time';
      final lastCleanupStr = prefs.getString(lastCleanupKey);
      
      final now = DateTime.now();
      final shouldCleanup = lastCleanupStr == null ||
          now.difference(DateTime.parse(lastCleanupStr)) > (interval ?? const Duration(days: 1));
      
      if (shouldCleanup) {
        await performStartupCleanup();
        await prefs.setString(lastCleanupKey, now.toIso8601String());
        debugPrint('✅ Periodic cache cleanup completed');
      } else {
        debugPrint('⏭️ Skipping periodic cleanup (too soon)');
      }
    } catch (e) {
      debugPrint('❌ Periodic cleanup error: $e');
    }
  }
}

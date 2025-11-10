import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'cache_strategy_config.dart';

/// Unified Cache Manager - Centralized cache management system
class UnifiedCacheManager {
  static final UnifiedCacheManager _instance = UnifiedCacheManager._internal();
  factory UnifiedCacheManager() => _instance;
  UnifiedCacheManager._internal();

  static UnifiedCacheManager get instance => _instance;

  // Cache configuration
  static const Duration _defaultCacheDuration = Duration(minutes: 15);
  static const int _maxMemoryCacheSize = 100; // Max items in memory
  // Reduced from 100MB to 60MB to prevent app size growth
  // This prevents unified cache from consuming too much storage
  static const int _maxFileCacheSize = 60 * 1024 * 1024; // 60MB (reduced from 100MB)
  static const String _cacheFolder = 'unified_cache';

  // Cache layers
  final Map<String, CacheItem> _memoryCache = {};
  SharedPreferences? _prefs;
  Directory? _cacheDirectory;

  // Cache analytics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  int _cacheWrites = 0;
  int _cacheReads = 0;
  DateTime? _lastWarmUpTime;

  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDirectory = await _getCacheDirectory();
    await _cleanupExpiredCache();
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheFolder');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Generate cache key
  String _generateCacheKey(String key, CacheType type) {
    final bytes = utf8.encode('${type.name}_$key');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Cache data with TTL
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    CacheType type = CacheType.memory,
    bool compress = false,
  }) async {
    final cacheKey = _generateCacheKey(key, type);
    final expiry = DateTime.now().add(ttl ?? _defaultCacheDuration);
    
    final cacheItem = CacheItem<T>(
      data: data,
      expiry: expiry,
      compressed: compress,
      accessCount: 0,
      lastAccessed: DateTime.now(),
    );

    switch (type) {
      case CacheType.memory:
        await _setMemoryCache(cacheKey, cacheItem);
        break;
      case CacheType.persistent:
        await _setPersistentCache(cacheKey, cacheItem);
        break;
      case CacheType.file:
        await _setFileCache(cacheKey, cacheItem);
        break;
    }
    
    _cacheWrites++;
  }

  /// Get cached data
  Future<T?> get<T>(
    String key, {
    CacheType type = CacheType.memory,
  }) async {
    _cacheReads++;
    final cacheKey = _generateCacheKey(key, type);
    
    switch (type) {
      case CacheType.memory:
        return await _getMemoryCache<T>(cacheKey);
      case CacheType.persistent:
        return await _getPersistentCache<T>(cacheKey);
      case CacheType.file:
        return await _getFileCache<T>(cacheKey);
    }
  }

  /// Memory cache operations
  Future<void> _setMemoryCache<T>(String key, CacheItem<T> item) async {
    // Check memory limit
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      await _evictLeastUsed();
    }
    
    _memoryCache[key] = item;
  }

  Future<T?> _getMemoryCache<T>(String key) async {
    final item = _memoryCache[key];
    
    if (item == null) {
      _cacheMisses++;
      return null;
    }

    if (item.isExpired) {
      _memoryCache.remove(key);
      _cacheMisses++;
      return null;
    }

    // Update access statistics
    item.accessCount++;
    item.lastAccessed = DateTime.now();
    _cacheHits++;
    
    return item.data as T?;
  }

  /// Persistent cache operations (SharedPreferences)
  Future<void> _setPersistentCache<T>(String key, CacheItem<T> item) async {
    if (_prefs == null) return;
    
    final jsonData = json.encode({
      'data': item.data,
      'expiry': item.expiry.millisecondsSinceEpoch,
      'compressed': item.compressed,
      'accessCount': item.accessCount,
      'lastAccessed': item.lastAccessed.millisecondsSinceEpoch,
    });
    
    await _prefs!.setString(key, jsonData);
  }

  Future<T?> _getPersistentCache<T>(String key) async {
    if (_prefs == null) {
      _cacheMisses++;
      return null;
    }
    
    final jsonData = _prefs!.getString(key);
    if (jsonData == null) {
      _cacheMisses++;
      return null;
    }

    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
      
      if (DateTime.now().isAfter(expiry)) {
        await _prefs!.remove(key);
        _cacheMisses++;
        return null;
      }

      _cacheHits++;
      return data['data'] as T?;
    } catch (e) {
      debugPrint('❌ Error reading persistent cache: $e');
      _cacheMisses++;
      return null;
    }
  }

  /// File cache operations
  Future<void> _setFileCache<T>(String key, CacheItem<T> item) async {
    if (_cacheDirectory == null) return;
    
    final file = File('${_cacheDirectory!.path}/$key.json');
    final jsonData = json.encode({
      'data': item.data,
      'expiry': item.expiry.millisecondsSinceEpoch,
      'compressed': item.compressed,
      'accessCount': item.accessCount,
      'lastAccessed': item.lastAccessed.millisecondsSinceEpoch,
    });
    
    await file.writeAsString(jsonData);
  }

  Future<T?> _getFileCache<T>(String key) async {
    if (_cacheDirectory == null) {
      _cacheMisses++;
      return null;
    }
    
    final file = File('${_cacheDirectory!.path}/$key.json');
    if (!await file.exists()) {
      _cacheMisses++;
      return null;
    }

    try {
      final jsonData = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonData);
      final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
      
      if (DateTime.now().isAfter(expiry)) {
        await file.delete();
        _cacheMisses++;
        return null;
      }

      _cacheHits++;
      return data['data'] as T?;
    } catch (e) {
      debugPrint('❌ Error reading file cache: $e');
      _cacheMisses++;
      return null;
    }
  }

  /// Evict least used items from memory cache
  Future<void> _evictLeastUsed() async {
    if (_memoryCache.isEmpty) return;
    
    // Find least accessed item
    String? leastUsedKey;
    int minAccessCount = 999999; // Use large number instead of int.maxFinite
    DateTime oldestAccess = DateTime.now();
    
    for (final entry in _memoryCache.entries) {
      final item = entry.value;
      if (item.accessCount < minAccessCount || 
          (item.accessCount == minAccessCount && item.lastAccessed.isBefore(oldestAccess))) {
        leastUsedKey = entry.key;
        minAccessCount = item.accessCount;
        oldestAccess = item.lastAccessed;
      }
    }
    
    if (leastUsedKey != null) {
      _memoryCache.remove(leastUsedKey);
      _cacheEvictions++;
    }
  }

  /// Clean up expired cache entries
  Future<void> _cleanupExpiredCache() async {
    // Clean memory cache
    _memoryCache.removeWhere((key, item) => item.isExpired);
    
    // Clean persistent cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          try {
            final jsonData = _prefs!.getString(key);
            if (jsonData != null) {
              final data = json.decode(jsonData);
              final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
              if (DateTime.now().isAfter(expiry)) {
                await _prefs!.remove(key);
              }
            }
          } catch (e) {
            await _prefs!.remove(key);
          }
        }
      }
    }
    
    // Clean file cache
    if (_cacheDirectory != null) {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonData = await file.readAsString();
            final data = json.decode(jsonData);
            final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
            if (DateTime.now().isAfter(expiry)) {
              await file.delete();
            }
          } catch (e) {
            await file.delete();
          }
        }
      }
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs!.remove(key);
        }
      }
    }
    
    if (_cacheDirectory != null) {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    }
    
    _resetAnalytics();
  }

  /// Clear specific cache
  Future<void> clear(String key, {CacheType type = CacheType.memory}) async {
    final cacheKey = _generateCacheKey(key, type);
    
    switch (type) {
      case CacheType.memory:
        _memoryCache.remove(cacheKey);
        break;
      case CacheType.persistent:
        if (_prefs != null) {
          await _prefs!.remove(cacheKey);
        }
        break;
      case CacheType.file:
        if (_cacheDirectory != null) {
          final file = File('${_cacheDirectory!.path}/$cacheKey.json');
          if (await file.exists()) {
            await file.delete();
          }
        }
        break;
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests) * 100 : 0.0;
    
    return CacheStats(
      hits: _cacheHits,
      misses: _cacheMisses,
      evictions: _cacheEvictions,
      writes: _cacheWrites,
      reads: _cacheReads,
      hitRate: hitRate,
      memoryItems: _memoryCache.length,
      lastWarmUpTime: _lastWarmUpTime,
    );
  }

  /// Reset analytics
  void _resetAnalytics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;
    _cacheWrites = 0;
    _cacheReads = 0;
    _lastWarmUpTime = null;
  }

  /// Warm up cache with essential data
  Future<void> warmUpCache() async {
    debugPrint('🔥 Cache warming up...');
    
    try {
      // Essential data types to warm up
      final essentialTypes = [
        'user_profile',
        'accounts', 
        'categories',
        'credit_cards',
        'debit_cards',
        'cash_account',
      ];
      
      for (final dataType in essentialTypes) {
        final policy = CacheStrategyConfig.getPolicy(dataType);
        
        // Check if data exists in cache
        final cachedData = await get(dataType, type: policy.type);
        
        if (cachedData == null) {
          debugPrint('⚠️ No cached data found for $dataType - will be loaded on demand');
        } else {
          debugPrint('✅ Cached data found for $dataType');
        }
      }
      
      _lastWarmUpTime = DateTime.now();
      debugPrint('🔥 Cache warming completed');
    } catch (e) {
      debugPrint('❌ Error during cache warming: $e');
    }
  }
}

/// Cache item model
class CacheItem<T> {
  final T data;
  final DateTime expiry;
  final bool compressed;
  int accessCount;
  DateTime lastAccessed;

  CacheItem({
    required this.data,
    required this.expiry,
    this.compressed = false,
    this.accessCount = 0,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Cache item model
class CacheStats {
  final int hits;
  final int misses;
  final int evictions;
  final int writes;
  final int reads;
  final double hitRate;
  final int memoryItems;
  final DateTime? lastWarmUpTime;

  CacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.writes,
    required this.reads,
    required this.hitRate,
    required this.memoryItems,
    this.lastWarmUpTime,
  });

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, evictions: $evictions, writes: $writes, reads: $reads, hitRate: ${hitRate.toStringAsFixed(2)}%, memoryItems: $memoryItems, lastWarmUp: $lastWarmUpTime)';
  }
}

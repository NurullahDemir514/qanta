import 'package:flutter/foundation.dart';

/// Cache Strategy Configuration - Defines cache policies for different data types
class CacheStrategyConfig {
  static const Map<String, CachePolicy> _policies = {
    // User data - Long cache, high priority
    'user_profile': CachePolicy(
      ttl: Duration(hours: 24),
      type: CacheType.persistent,
      priority: CachePriority.high,
      compress: false,
    ),
    
    // Account data - Medium cache, high priority
    'accounts': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.high,
      compress: false,
    ),
    
    // Transactions - Short cache, medium priority
    'transactions': CachePolicy(
      ttl: Duration(minutes: 15),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: true,
    ),
    
    // Credit cards - Medium cache, medium priority
    'credit_cards': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: false,
    ),
    
    // Debit cards - Medium cache, medium priority
    'debit_cards': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: false,
    ),
    
    // Cash account - Medium cache, high priority
    'cash_account': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.high,
      compress: false,
    ),
    
    // Card transactions - Short cache, medium priority
    'card_transactions': CachePolicy(
      ttl: Duration(minutes: 15),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: true,
    ),
    
    // Budgets - Medium cache, medium priority
    'budgets': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: false,
    ),
    
    // Installments - Medium cache, medium priority
    'installments': CachePolicy(
      ttl: Duration(minutes: 30),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: false,
    ),
    
    // Statements - Short cache, high priority
    'statements': CachePolicy(
      ttl: Duration(minutes: 10),
      type: CacheType.memory,
      priority: CachePriority.high,
      compress: true,
    ),
    
    // Stock data - Very short cache, high priority
    'stock_prices': CachePolicy(
      ttl: Duration(minutes: 5),
      type: CacheType.memory,
      priority: CachePriority.high,
      compress: false,
    ),
    
    // Statistics - Medium cache, medium priority
    'statistics': CachePolicy(
      ttl: Duration(minutes: 20),
      type: CacheType.memory,
      priority: CachePriority.medium,
      compress: true,
    ),
    
    // Images - Long cache, low priority
    'profile_images': CachePolicy(
      ttl: Duration(days: 7),
      type: CacheType.file,
      priority: CachePriority.low,
      compress: false,
    ),
    
    // Theme settings - Permanent cache
    'theme_settings': CachePolicy(
      ttl: Duration(days: 365), // Effectively permanent
      type: CacheType.persistent,
      priority: CachePriority.low,
      compress: false,
    ),
  };

  /// Get cache policy for a specific data type
  static CachePolicy getPolicy(String dataType) {
    return _policies[dataType] ?? _defaultPolicy;
  }

  /// Default cache policy
  static const CachePolicy _defaultPolicy = CachePolicy(
    ttl: Duration(minutes: 15),
    type: CacheType.memory,
    priority: CachePriority.medium,
    compress: false,
  );

  /// Get all policies
  static Map<String, CachePolicy> get allPolicies => Map.unmodifiable(_policies);

  /// Check if data type should be cached
  static bool shouldCache(String dataType) {
    return _policies.containsKey(dataType);
  }

  /// Get cache key for data type and identifier
  static String getCacheKey(String dataType, String identifier) {
    return '${dataType}_$identifier';
  }

  /// Get cache key for data type only
  static String getCacheKeyForType(String dataType) {
    return dataType;
  }
}

/// Cache policy model
class CachePolicy {
  final Duration ttl;
  final CacheType type;
  final CachePriority priority;
  final bool compress;

  const CachePolicy({
    required this.ttl,
    required this.type,
    required this.priority,
    required this.compress,
  });

  @override
  String toString() {
    return 'CachePolicy(ttl: $ttl, type: $type, priority: $priority, compress: $compress)';
  }
}

/// Cache types
enum CacheType {
  memory,
  persistent,
  file,
}

/// Cache priority levels
enum CachePriority {
  low,
  medium,
  high,
}

/// Cache warming strategies
enum CacheWarmingStrategy {
  /// Load all data at app startup
  aggressive,
  
  /// Load only essential data at startup
  selective,
  
  /// Load data on demand
  lazy,
  
  /// Load data in background after startup
  background,
}

/// Cache optimization settings
class CacheOptimizationSettings {
  final bool enableCompression;
  final bool enableAnalytics;
  final bool enableWarming;
  final CacheWarmingStrategy warmingStrategy;
  final Duration cleanupInterval;
  final int maxMemoryItems;
  final int maxFileCacheSizeMB;

  const CacheOptimizationSettings({
    this.enableCompression = true,
    this.enableAnalytics = true,
    this.enableWarming = true,
    this.warmingStrategy = CacheWarmingStrategy.selective,
    this.cleanupInterval = const Duration(hours: 1),
    this.maxMemoryItems = 100,
    this.maxFileCacheSizeMB = 100,
  });

  /// Default settings for production
  static const CacheOptimizationSettings production = CacheOptimizationSettings(
    enableCompression: true,
    enableAnalytics: true,
    enableWarming: true,
    warmingStrategy: CacheWarmingStrategy.selective,
    cleanupInterval: Duration(hours: 1),
    maxMemoryItems: 100,
    maxFileCacheSizeMB: 100,
  );

  /// Default settings for development
  static const CacheOptimizationSettings development = CacheOptimizationSettings(
    enableCompression: false,
    enableAnalytics: true,
    enableWarming: false,
    warmingStrategy: CacheWarmingStrategy.lazy,
    cleanupInterval: Duration(minutes: 30),
    maxMemoryItems: 50,
    maxFileCacheSizeMB: 50,
  );

  /// Get settings based on environment
  static CacheOptimizationSettings getCurrent() {
    return kDebugMode ? development : production;
  }
}

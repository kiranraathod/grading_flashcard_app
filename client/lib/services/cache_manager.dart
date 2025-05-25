import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'enhanced_cache_manager.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  
  final EnhancedCacheManager _enhancedCache = EnhancedCacheManager();
  bool _useEnhancedCache = true;
  bool _isInitialized = false;

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _enhancedCache.initialize();
      _isInitialized = true;
      debugPrint('CacheManager initialized with enhanced features');
    } catch (e) {
      debugPrint('Failed to initialize enhanced cache, using basic: $e');
      _useEnhancedCache = false;
      _isInitialized = true;
    }
  }

  /// Cache data with enhanced features
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? ttl}) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        await _enhancedCache.cacheData(key, data, ttl: ttl ?? _defaultCacheExpiry);
        return;
      } catch (e) {
        debugPrint('Enhanced cache failed, falling back: $e');
      }
    }
    
    // Fallback to basic caching
    await _fallbackCacheData(key, data);
  }

  /// Get cached data with enhanced features
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        return await _enhancedCache.getCachedData(key);
      } catch (e) {
        debugPrint('Enhanced cache failed, falling back: $e');
      }
    }
    
    // Fallback to basic cache retrieval
    return await _fallbackGetCachedData(key);
  }

  /// Clear cache with enhanced options
  Future<void> clearCache(String key) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        await _enhancedCache.clearCache(key: key);
        return;
      } catch (e) {
        debugPrint('Enhanced cache clear failed, falling back: $e');
      }
    }
    
    // Fallback to basic cache clearing
    await _fallbackClearCache(key);
  }

  /// Check if cache is valid
  Future<bool> isCacheValid(String key) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        return await _enhancedCache.isCacheValid(key);
      } catch (e) {
        debugPrint('Enhanced cache validation failed, falling back: $e');
      }
    }
    
    // Fallback to basic cache validation
    return await _fallbackIsCacheValid(key);
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        await _enhancedCache.clearCache();
        return;
      } catch (e) {
        debugPrint('Enhanced cache clear all failed, falling back: $e');
      }
    }
    
    // Fallback to basic clear all
    await _fallbackClearAllCache();
  }

  /// Add to offline queue (enhanced feature)
  Future<void> addToOfflineQueue(String key, Map<String, dynamic> data, {int priority = 0}) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        await _enhancedCache.addToOfflineQueue(key, data, priority: priority);
      } catch (e) {
        debugPrint('Failed to add to offline queue: $e');
      }
    }
  }

  /// Process offline queue (enhanced feature)
  Future<List<String>> processOfflineQueue() async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      try {
        return await _enhancedCache.processOfflineQueue();
      } catch (e) {
        debugPrint('Failed to process offline queue: $e');
      }
    }
    
    return [];
  }

  /// Get cache statistics (enhanced feature)
  Map<String, dynamic> getStatistics() {
    if (_useEnhancedCache) {
      return _enhancedCache.getStatistics();
    }
    return {'message': 'Enhanced features not available'};
  }

  /// Fallback implementations for basic functionality
  Future<void> _fallbackCacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', json.encode(data));
      final expiryTime = DateTime.now().add(_defaultCacheExpiry);
      await prefs.setInt('$_cachePrefix${key}_timestamp', expiryTime.millisecondsSinceEpoch);
      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Error caching data for key $key: $e');
    }
  }

  Future<Map<String, dynamic>?> _fallbackGetCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('$_cachePrefix$key');
      final timestamp = prefs.getInt('$_cachePrefix${key}_timestamp');
      
      if (dataString == null || timestamp == null) return null;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().isAfter(expiryTime)) {
        await _fallbackClearCache(key);
        return null;
      }
      
      return json.decode(dataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error retrieving cached data for key $key: $e');
      return null;
    }
  }

  Future<void> _fallbackClearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_cachePrefix${key}_timestamp');
    } catch (e) {
      debugPrint('Error clearing cache for key $key: $e');
    }
  }

  Future<bool> _fallbackIsCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('$_cachePrefix${key}_timestamp');
      if (timestamp == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _fallbackClearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  /// Ensure cache manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

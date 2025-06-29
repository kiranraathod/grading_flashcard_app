import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_cache_manager.dart';
import 'simple_error_handler.dart';
import 'initialization_coordinator.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  
  final EnhancedCacheManager _enhancedCache = EnhancedCacheManager();
  final InitializationCoordinator _coordinator = InitializationCoordinator();
  
  bool _useEnhancedCache = true;
  bool _isInitialized = false;

  /// Initialize the cache manager with reliable error handling
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _coordinator.registerService('CacheManager');
    _coordinator.markServiceInitializing('CacheManager');
    
    await SimpleErrorHandler.safe(
      () async {
        await _enhancedCache.initialize();
        _useEnhancedCache = true;
        _isInitialized = true;
      },
      fallbackOperation: () async {
        _useEnhancedCache = false;
        _isInitialized = true;
      },
      operationName: 'cache_manager_initialization',
    );
    
    _coordinator.markServiceInitialized('CacheManager');
  }

  /// Cache data with reliable enhanced/fallback pattern
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? ttl}) async {
    await _ensureInitialized();
    
    await SimpleErrorHandler.safe(
      () => _enhancedCache.cacheData(key, data, ttl: ttl ?? _defaultCacheExpiry),
      fallbackOperation: () => _fallbackCacheData(key, data),
      operationName: 'cache_data',
    );
  }

  /// Get cached data with default null return
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    await _ensureInitialized();
    
    return await SimpleErrorHandler.safe(
      () => _enhancedCache.getCachedData(key),
      fallbackOperation: () => _fallbackGetCachedData(key),
      operationName: 'get_cached_data',
    );
  }

  /// Clear cache safely
  Future<void> clearCache(String key) async {
    await _ensureInitialized();
    
    await SimpleErrorHandler.safe(
      () => _enhancedCache.clearCache(key: key),
      fallbackOperation: () => _fallbackClearCache(key),
      operationName: 'clear_cache',
    );
  }

  /// Check if cache is valid with default false
  Future<bool> isCacheValid(String key) async {
    await _ensureInitialized();
    
    return await SimpleErrorHandler.safe(
      () => _useEnhancedCache 
        ? _enhancedCache.isCacheValid(key)
        : _fallbackIsCacheValid(key),
      fallback: false,
      operationName: 'is_cache_valid',
    );
  }

  /// Clear all cache safely
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    
    await SimpleErrorHandler.safely(
      () => _useEnhancedCache 
        ? _enhancedCache.clearCache()
        : _fallbackClearAllCache(),
      operationName: 'clear_all_cache',
    );
  }

  /// Enhanced features with safe operations
  Future<void> addToOfflineQueue(String key, Map<String, dynamic> data, {int priority = 0}) async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      await SimpleErrorHandler.safely(
        () => _enhancedCache.addToOfflineQueue(key, data, priority: priority),
        operationName: 'add_to_offline_queue',
      );
    }
  }

  Future<List<String>> processOfflineQueue() async {
    await _ensureInitialized();
    
    if (_useEnhancedCache) {
      return await SimpleErrorHandler.safe(
        () => _enhancedCache.processOfflineQueue(),
        fallback: <String>[],
        operationName: 'process_offline_queue',
      );
    }
    return [];
  }

  Map<String, dynamic> getStatistics() {
    if (_useEnhancedCache) {
      return SimpleErrorHandler.safeSync(
        () => _enhancedCache.getStatistics(),
        fallback: {'message': 'Enhanced features not available'},
        operationName: 'get_statistics',
      );
    }
    return {'message': 'Enhanced features not available'};
  }

  /// Fallback implementations using SimpleErrorHandler
  Future<void> _fallbackCacheData(String key, Map<String, dynamic> data) async {
    await SimpleErrorHandler.safely(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_cachePrefix$key', json.encode(data));
        final expiryTime = DateTime.now().add(_defaultCacheExpiry);
        await prefs.setInt('$_cachePrefix${key}_timestamp', expiryTime.millisecondsSinceEpoch);
      },
      operationName: 'fallback_cache_data',
    );
  }

  Future<Map<String, dynamic>?> _fallbackGetCachedData(String key) async {
    return await SimpleErrorHandler.safe(
      () async {
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
      },
      fallback: null,
      operationName: 'fallback_get_cached_data',
    );
  }

  Future<void> _fallbackClearCache(String key) async {
    await SimpleErrorHandler.safely(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_cachePrefix$key');
        await prefs.remove('$_cachePrefix${key}_timestamp');
      },
      operationName: 'fallback_clear_cache',
    );
  }

  Future<bool> _fallbackIsCacheValid(String key) async {
    return await SimpleErrorHandler.safe(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getInt('$_cachePrefix${key}_timestamp');
        if (timestamp == null) return false;
        
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateTime.now().isBefore(expiryTime);
      },
      fallback: false,
      operationName: 'fallback_is_cache_valid',
    );
  }

  Future<void> _fallbackClearAllCache() async {
    await SimpleErrorHandler.safely(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
        for (final key in keys) {
          await prefs.remove(key);
        }
      },
      operationName: 'fallback_clear_all_cache',
    );
  }

  /// Ensure cache manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

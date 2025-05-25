import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';

enum CachePolicy {
  cacheFirst,    // Try cache first, then network
  networkFirst,  // Try network first, then cache
  cacheOnly,     // Only use cache
  networkOnly,   // Only use network
}

class CacheEntry {
  final String key;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? etag;
  final int accessCount;
  final DateTime lastAccessedAt;
  final bool isCompressed;

  const CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    this.etag,
    this.accessCount = 0,
    required this.lastAccessedAt,
    this.isCompressed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  CacheEntry copyWith({
    int? accessCount,
    DateTime? lastAccessedAt,
  }) {
    return CacheEntry(
      key: key,
      data: data,
      createdAt: createdAt,
      expiresAt: expiresAt,
      etag: etag,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isCompressed: isCompressed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'etag': etag,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'isCompressed': isCompressed,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      etag: json['etag'],
      accessCount: json['accessCount'] ?? 0,
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      isCompressed: json['isCompressed'] ?? false,
    );
  }
}

class OfflineQueueItem {
  final String key;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int priority;
  final int retryCount;

  const OfflineQueueItem({
    required this.key,
    required this.data,
    required this.timestamp,
    this.priority = 0,
    this.retryCount = 0,
  });

  OfflineQueueItem copyWith({int? retryCount}) {
    return OfflineQueueItem(
      key: key,
      data: data,
      timestamp: timestamp,
      priority: priority,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority,
      'retryCount': retryCount,
    };
  }

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      key: json['key'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      priority: json['priority'],
      retryCount: json['retryCount'],
    );
  }
}

class EnhancedCacheManager extends ChangeNotifier {
  static final EnhancedCacheManager _instance = EnhancedCacheManager._internal();
  factory EnhancedCacheManager() => _instance;
  EnhancedCacheManager._internal();

  // Memory cache (Level 1)
  final Map<String, CacheEntry> _memoryCache = {};
  
  // Offline queue
  final List<OfflineQueueItem> _offlineQueue = [];
  
  // Cache configuration
  static const String _cachePrefix = 'enhanced_cache_';
  static const String _offlineQueueKey = 'offline_queue';
  static const Duration _defaultTtl = Duration(hours: 24);
  static const int _maxMemoryCacheSize = 100;
  static const int _maxOfflineQueueSize = 50;

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;

  /// Initialize the enhanced cache manager
  Future<void> initialize() async {
    await _loadOfflineQueue();
    AppConfig.logNetwork('EnhancedCacheManager initialized', level: NetworkLogLevel.basic);
  }

  /// Cache data with enhanced features
  Future<void> cacheData(
    String key,
    Map<String, dynamic> data, {
    Duration? ttl,
    String? etag,
    bool useCompression = false,
    int priority = 0,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(ttl ?? _defaultTtl);
      
      final entry = CacheEntry(
        key: key,
        data: data,
        createdAt: now,
        expiresAt: expiresAt,
        etag: etag,
        lastAccessedAt: now,
        isCompressed: useCompression,
      );

      // Store in memory cache
      _memoryCache[key] = entry;
      _evictMemoryCacheIfNeeded();

      // Store in persistent cache
      await _storePersistentCache(key, entry);
      
      AppConfig.logNetwork('Cached data: $key', level: NetworkLogLevel.verbose);
    } catch (e) {
      AppConfig.logNetwork('Failed to cache data: $key - $e', level: NetworkLogLevel.errors);
    }
  }

  /// Get cached data with policy support
  Future<Map<String, dynamic>?> getCachedData(
    String key, {
    CachePolicy policy = CachePolicy.cacheFirst,
  }) async {
    try {
      CacheEntry? entry;

      // Check memory cache first
      entry = _memoryCache[key];
      
      if (entry == null || entry.isExpired) {
        // Check persistent cache
        entry = await _loadPersistentCache(key);
      }

      if (entry != null && entry.isValid) {
        // Update access statistics
        final updatedEntry = entry.copyWith(
          accessCount: entry.accessCount + 1,
          lastAccessedAt: DateTime.now(),
        );
        
        _memoryCache[key] = updatedEntry;
        _cacheHits++;
        
        AppConfig.logNetwork('Cache hit: $key', level: NetworkLogLevel.verbose);
        return updatedEntry.data;
      }

      _cacheMisses++;
      AppConfig.logNetwork('Cache miss: $key', level: NetworkLogLevel.verbose);
      return null;
      
    } catch (e) {
      AppConfig.logNetwork('Failed to get cached data: $key - $e', level: NetworkLogLevel.errors);
      return null;
    }
  }

  /// Add item to offline queue
  Future<void> addToOfflineQueue(
    String key,
    Map<String, dynamic> data, {
    int priority = 0,
  }) async {
    try {
      final item = OfflineQueueItem(
        key: key,
        data: data,
        timestamp: DateTime.now(),
        priority: priority,
      );

      _offlineQueue.add(item);
      
      // Sort by priority (higher priority first)
      _offlineQueue.sort((a, b) => b.priority.compareTo(a.priority));
      
      // Maintain queue size
      if (_offlineQueue.length > _maxOfflineQueueSize) {
        _offlineQueue.removeRange(_maxOfflineQueueSize, _offlineQueue.length);
      }

      await _saveOfflineQueue();
      
      AppConfig.logNetwork('Added to offline queue: $key', level: NetworkLogLevel.verbose);
      notifyListeners();
    } catch (e) {
      AppConfig.logNetwork('Failed to add to offline queue: $key - $e', level: NetworkLogLevel.errors);
    }
  }

  /// Process offline queue
  Future<List<String>> processOfflineQueue() async {
    final processedKeys = <String>[];
    final failedItems = <OfflineQueueItem>[];

    for (final item in List.from(_offlineQueue)) {
      try {
        // Attempt to sync the item
        // This would typically involve calling the network service
        await _syncOfflineItem(item);
        
        processedKeys.add(item.key);
        _offlineQueue.remove(item);
        
        AppConfig.logNetwork('Processed offline item: ${item.key}', level: NetworkLogLevel.basic);
      } catch (e) {
        AppConfig.logNetwork('Failed to process offline item: ${item.key} - $e', level: NetworkLogLevel.errors);
        
        if (item.retryCount < 3) {
          failedItems.add(item.copyWith(retryCount: item.retryCount + 1));
        }
        _offlineQueue.remove(item);
      }
    }

    // Re-add failed items for retry
    _offlineQueue.addAll(failedItems);
    await _saveOfflineQueue();
    
    if (processedKeys.isNotEmpty) {
      notifyListeners();
    }

    return processedKeys;
  }

  /// Sync a single offline item (placeholder for actual sync logic)
  Future<void> _syncOfflineItem(OfflineQueueItem item) async {
    // This would be implemented to call the appropriate API endpoint
    // For now, we'll just simulate the sync
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Clear cache with options
  Future<void> clearCache({
    String? key,
    bool clearMemory = true,
    bool clearPersistent = true,
    Duration? olderThan,
  }) async {
    try {
      if (key != null) {
        // Clear specific key
        if (clearMemory) _memoryCache.remove(key);
        if (clearPersistent) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('$_cachePrefix$key');
        }
      } else {
        // Clear all cache
        if (clearMemory) _memoryCache.clear();
        if (clearPersistent) {
          final prefs = await SharedPreferences.getInstance();
          final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
          for (final key in keys) {
            if (olderThan != null) {
              // Only clear entries older than specified duration
              final entry = await _loadPersistentCache(key.substring(_cachePrefix.length));
              if (entry != null && DateTime.now().difference(entry.createdAt) > olderThan) {
                await prefs.remove(key);
              }
            } else {
              await prefs.remove(key);
            }
          }
        }
      }
      
      AppConfig.logNetwork('Cache cleared${key != null ? ": $key" : ""}', level: NetworkLogLevel.basic);
    } catch (e) {
      AppConfig.logNetwork('Failed to clear cache: $e', level: NetworkLogLevel.errors);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests) * 100 : 0.0;

    return {
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheEvictions': _cacheEvictions,
      'hitRate': hitRate,
      'memoryEntries': _memoryCache.length,
      'offlineQueueSize': _offlineQueue.length,
    };
  }

  /// Check if cache entry is valid
  Future<bool> isCacheValid(String key, {String? etag}) async {
    final entry = await _loadPersistentCache(key);
    if (entry == null || entry.isExpired) return false;
    
    if (etag != null && entry.etag != null) {
      return entry.etag == etag;
    }
    
    return true;
  }

  /// Evict memory cache entries if needed (LRU strategy)
  void _evictMemoryCacheIfNeeded() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // Sort by last accessed time (LRU)
    final entries = _memoryCache.entries.toList();
    entries.sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    // Remove oldest entries
    final toRemove = entries.length - _maxMemoryCacheSize;
    for (int i = 0; i < toRemove; i++) {
      _memoryCache.remove(entries[i].key);
      _cacheEvictions++;
    }

    AppConfig.logNetwork('Evicted $toRemove entries from memory cache', level: NetworkLogLevel.verbose);
  }

  /// Store cache entry in persistent storage
  Future<void> _storePersistentCache(String key, CacheEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(entry.toJson());
      await prefs.setString('$_cachePrefix$key', jsonString);
    } catch (e) {
      AppConfig.logNetwork('Failed to store persistent cache: $key - $e', level: NetworkLogLevel.errors);
    }
  }

  /// Load cache entry from persistent storage
  Future<CacheEntry?> _loadPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_cachePrefix$key');
      
      if (jsonString == null) return null;
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry.fromJson(jsonData);
    } catch (e) {
      AppConfig.logNetwork('Failed to load persistent cache: $key - $e', level: NetworkLogLevel.errors);
      return null;
    }
  }

  /// Save offline queue to persistent storage
  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _offlineQueue.map((item) => item.toJson()).toList();
      await prefs.setString(_offlineQueueKey, jsonEncode(jsonList));
    } catch (e) {
      AppConfig.logNetwork('Failed to save offline queue: $e', level: NetworkLogLevel.errors);
    }
  }

  /// Load offline queue from persistent storage
  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_offlineQueueKey);
      
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _offlineQueue.addAll(
          jsonList.map((item) => OfflineQueueItem.fromJson(item as Map<String, dynamic>))
        );
      }
    } catch (e) {
      AppConfig.logNetwork('Failed to load offline queue: $e', level: NetworkLogLevel.errors);
    }
  }
}

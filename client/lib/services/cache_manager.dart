import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheExpiry = Duration(hours: 24);

  Future<void> cacheData(String key, Map<String, dynamic> data) async {
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

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('$_cachePrefix$key');
      final timestamp = prefs.getInt('$_cachePrefix${key}_timestamp');
      
      if (dataString == null || timestamp == null) return null;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().isAfter(expiryTime)) {
        await clearCache(key);
        return null;
      }
      
      return json.decode(dataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error retrieving cached data for key $key: $e');
      return null;
    }
  }

  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_cachePrefix${key}_timestamp');
    } catch (e) {
      debugPrint('Error clearing cache for key $key: $e');
    }
  }

  Future<bool> isCacheValid(String key) async {
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

  Future<void> clearAllCache() async {
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
}

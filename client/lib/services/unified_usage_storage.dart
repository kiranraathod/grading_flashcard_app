import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Unified storage service for all usage tracking
/// 
/// This provides a single, consistent system for all user data.
class UnifiedUsageStorage {
  // ✅ SINGLE STORAGE KEY PATTERN
  static const String _unifiedUsageKey = 'unified_usage_v3';

  /// Store unified usage data for a user (authenticated or guest)
  static Future<void> storeUsageData(String userId, UnifiedUsageData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_unifiedUsageKey}_$userId';
      final jsonData = jsonEncode(data.toJson());
      
      await prefs.setString(key, jsonData);
      debugPrint('✅ Unified usage data stored for: $userId');
      debugPrint('📊 Data: ${data.toDebugString()}');
    } catch (e) {
      debugPrint('❌ Failed to store unified usage data: $e');
    }
  }

  /// Retrieve unified usage data for a user
  static Future<UnifiedUsageData> getUsageData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_unifiedUsageKey}_$userId';
      final jsonString = prefs.getString(key);
      
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final data = UnifiedUsageData.fromJson(jsonData);
        debugPrint('📖 Loaded usage data for: $userId');
        return data;
      }
      
      // Return empty data if none exists
      debugPrint('📝 No existing usage data for: $userId, creating new');
      return UnifiedUsageData.empty(userId);
    } catch (e) {
      debugPrint('❌ Failed to load usage data: $e, returning empty');
      return UnifiedUsageData.empty(userId);
    }
  }

  /// Clear usage data for a user
  static Future<void> clearUsageData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_unifiedUsageKey}_$userId';
      await prefs.remove(key);
      debugPrint('🗑️ Cleared usage data for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear usage data: $e');
    }
  }

  /// Reset daily usage for a user (keeps the structure, zeros counts)
  static Future<void> resetDailyUsage(String userId) async {
    try {
      final currentData = await getUsageData(userId);
      final resetData = currentData.resetDaily();
      await storeUsageData(userId, resetData);
      debugPrint('🔄 Daily usage reset for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to reset daily usage: $e');
    }
  }

  /// Get all stored user IDs (for maintenance/debug purposes)
  static Future<List<String>> getAllUserIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final userIds = <String>[];
      for (final key in keys) {
        if (key.startsWith(_unifiedUsageKey)) {
          final userId = key.substring('${_unifiedUsageKey}_'.length);
          userIds.add(userId);
        }
      }
      
      return userIds;
    } catch (e) {
      debugPrint('❌ Failed to get user IDs: $e');
      return [];
    }
  }

  /// 🎯 CRITICAL FIX: Migrate guest data to authenticated user
  static Future<void> migrateGuestToAuthenticated(String guestId, String authenticatedUserId) async {
    try {
      debugPrint('🔄 Migrating guest data: $guestId → $authenticatedUserId');
      
      // Get guest data
      final guestData = await getUsageData(guestId);
      if (guestData.actionCounts.isEmpty) {
        debugPrint('📝 No guest data to migrate');
        return;
      }
      
      // Get or create authenticated user data
      final authenticatedData = await getUsageData(authenticatedUserId);
      
      // Merge guest progress with authenticated user data
      final mergedCounts = Map<String, int>.from(authenticatedData.actionCounts);
      for (final entry in guestData.actionCounts.entries) {
        mergedCounts[entry.key] = (mergedCounts[entry.key] ?? 0) + entry.value;
      }
      
      // Create updated authenticated user data with preserved progress
      final updatedData = authenticatedData.copyWith(
        actionCounts: mergedCounts,
        // Keep the earlier reset time to preserve progress timing
        lastReset: guestData.lastReset.isBefore(authenticatedData.lastReset) 
            ? guestData.lastReset 
            : authenticatedData.lastReset,
      );
      
      // Store updated authenticated user data
      await storeUsageData(authenticatedUserId, updatedData);
      
      // Clear guest data
      await clearUsageData(guestId);
      
      debugPrint('✅ Guest data migration successful');
      debugPrint('📊 Migrated counts: ${guestData.actionCounts}');
      debugPrint('📊 Final counts: ${updatedData.actionCounts}');
      
    } catch (e) {
      debugPrint('❌ Failed to migrate guest data: $e');
    }
  }

  /// 🔄 LEGACY: No-op method for compatibility (legacy migration removed)
  static Future<void> migrateLegacyData(String userId) async {
    // Legacy migration is no longer needed - all users are now in unified system
    debugPrint('📝 Legacy migration skipped for: $userId (unified system only)');
  }

  /// Debug method: Get storage overview
  static Future<Map<String, dynamic>> getStorageOverview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final unifiedKeys = <String>[];
      final legacyKeys = <String>[];
      
      for (final key in allKeys) {
        if (key.startsWith(_unifiedUsageKey)) {
          unifiedKeys.add(key);
        } else if (key.startsWith('guest_') || key.startsWith('auth_user_actions')) {
          legacyKeys.add(key);
        }
      }
      
      return {
        'unifiedKeys': unifiedKeys,
        'legacyKeys': legacyKeys,
        'totalUsers': unifiedKeys.length,
        'needsMigration': legacyKeys.isNotEmpty,
      };
    } catch (e) {
      debugPrint('❌ Failed to get storage overview: $e');
      return {};
    }
  }
}

/// Unified data structure for all usage tracking
class UnifiedUsageData {
  final String userId;
  final Map<String, int> actionCounts;
  final Map<String, int> dailyLimits;
  final DateTime lastReset;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasReachedLimit;

  const UnifiedUsageData({
    required this.userId,
    required this.actionCounts,
    required this.dailyLimits,
    required this.lastReset,
    required this.createdAt,
    required this.updatedAt,
    this.hasReachedLimit = false,
  });

  /// Create empty usage data for a new user
  factory UnifiedUsageData.empty(String userId) {
    final now = DateTime.now();
    return UnifiedUsageData(
      userId: userId,
      actionCounts: {},
      dailyLimits: {},
      lastReset: now,
      createdAt: now,
      updatedAt: now,
      hasReachedLimit: false,
    );
  }

  /// Create from JSON data
  factory UnifiedUsageData.fromJson(Map<String, dynamic> json) {
    return UnifiedUsageData(
      userId: json['userId'] as String,
      actionCounts: Map<String, int>.from(json['actionCounts'] ?? {}),
      dailyLimits: Map<String, int>.from(json['dailyLimits'] ?? {}),
      lastReset: DateTime.parse(json['lastReset'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      hasReachedLimit: json['hasReachedLimit'] ?? false,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'actionCounts': actionCounts,
      'dailyLimits': dailyLimits,
      'lastReset': lastReset.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'hasReachedLimit': hasReachedLimit,
    };
  }

  /// Create a copy with updated fields
  UnifiedUsageData copyWith({
    String? userId,
    Map<String, int>? actionCounts,
    Map<String, int>? dailyLimits,
    DateTime? lastReset,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasReachedLimit,
  }) {
    return UnifiedUsageData(
      userId: userId ?? this.userId,
      actionCounts: actionCounts ?? this.actionCounts,
      dailyLimits: dailyLimits ?? this.dailyLimits,
      lastReset: lastReset ?? this.lastReset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      hasReachedLimit: hasReachedLimit ?? this.hasReachedLimit,
    );
  }

  /// Reset daily usage counts (keep limits and structure)
  UnifiedUsageData resetDaily() {
    return copyWith(
      actionCounts: {},
      lastReset: DateTime.now(),
      hasReachedLimit: false,
    );
  }

  /// Get total usage across all action types
  int get totalUsage {
    return actionCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Get total limit across all action types
  int get totalLimit {
    return dailyLimits.values.fold(0, (sum, limit) => sum + limit);
  }

  /// Get remaining actions for a specific type
  int getRemainingActions(String actionType) {
    final used = actionCounts[actionType] ?? 0;
    final limit = dailyLimits[actionType] ?? 0;
    return (limit - used).clamp(0, limit);
  }

  /// Check if user can perform a specific action
  bool canPerformAction(String actionType) {
    return getRemainingActions(actionType) > 0;
  }

  /// Debug string representation
  String toDebugString() {
    return 'UnifiedUsageData(userId: $userId, totalUsage: $totalUsage/$totalLimit, '
           'actions: $actionCounts, limits: $dailyLimits, lastReset: $lastReset)';
  }
}

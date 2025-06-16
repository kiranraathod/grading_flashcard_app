import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Unified storage service for all usage tracking
/// 
/// This replaces the fragmented storage approach with a single, consistent system.
/// Consolidates data from GuestUserManager, SimpleActionTracker, and WorkingSecureAuthStorage.
class UnifiedUsageStorage {
  // ✅ SINGLE STORAGE KEY PATTERN
  static const String _unifiedUsageKey = 'unified_usage_v3';
  static const String _legacyMigrationKey = 'legacy_migration_completed_v3';
  
  // Legacy keys for migration (will be removed after migration)
  static const String _legacyGuestCountKey = 'guest_grading_count';
  static const String _legacyGuestResetKey = 'guest_limit_reset_date';
  static const String _legacyUserActionsPrefix = 'auth_user_actions_v2';

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

  /// 🔄 MIGRATION: Move data from legacy storage to unified storage
  static Future<void> migrateLegacyData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if already migrated
      final migrationKey = '${_legacyMigrationKey}_$userId';
      if (prefs.getBool(migrationKey) == true) {
        debugPrint('✅ Legacy data already migrated for: $userId');
        return;
      }

      debugPrint('🔄 Migrating legacy data for: $userId');
      
      // Create new unified data structure
      var unifiedData = UnifiedUsageData.empty(userId);
      
      // Migrate from GuestUserManager storage
      final legacyGuestCount = prefs.getInt(_legacyGuestCountKey) ?? 0;
      if (legacyGuestCount > 0) {
        debugPrint('📦 Migrating guest count: $legacyGuestCount');
        unifiedData = unifiedData.copyWith(
          actionCounts: {'flashcard_grading': legacyGuestCount},
        );
      }

      // Migrate from SimpleActionTracker storage
      final legacyUserActionsKey = '${_legacyUserActionsPrefix}_$userId';
      final legacyActionsJson = prefs.getString(legacyUserActionsKey);
      if (legacyActionsJson != null) {
        try {
          final legacyActions = jsonDecode(legacyActionsJson) as Map<String, dynamic>;
          final convertedActions = Map<String, int>.from(legacyActions);
          debugPrint('📦 Migrating user actions: $convertedActions');
          
          // Merge with any existing counts
          final mergedCounts = Map<String, int>.from(unifiedData.actionCounts);
          for (final entry in convertedActions.entries) {
            mergedCounts[entry.key] = (mergedCounts[entry.key] ?? 0) + entry.value;
          }
          
          unifiedData = unifiedData.copyWith(actionCounts: mergedCounts);
        } catch (e) {
          debugPrint('⚠️ Failed to parse legacy actions JSON: $e');
        }
      }

      // Store the migrated data
      await storeUsageData(userId, unifiedData);
      
      // Mark migration as complete
      await prefs.setBool(migrationKey, true);
      
      // Clean up legacy keys
      await _cleanupLegacyKeys(prefs);
      
      debugPrint('✅ Legacy data migration completed for: $userId');
      debugPrint('📊 Migrated data: ${unifiedData.toDebugString()}');
      
    } catch (e) {
      debugPrint('❌ Legacy data migration failed: $e');
    }
  }

  /// Clean up old storage keys after migration
  static Future<void> _cleanupLegacyKeys(SharedPreferences prefs) async {
    try {
      final keysToRemove = [
        _legacyGuestCountKey,
        _legacyGuestResetKey,
      ];
      
      // Remove guest manager keys
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      // Remove old user action keys
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_legacyUserActionsPrefix)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('🧹 Legacy storage keys cleaned up');
    } catch (e) {
      debugPrint('⚠️ Failed to cleanup legacy keys: $e');
    }
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

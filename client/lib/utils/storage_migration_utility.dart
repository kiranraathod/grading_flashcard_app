import 'dart:convert';
import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unified_usage_storage.dart';

/// Custom debug print to avoid conflicts with Flutter's debugPrint
void migrationDebugPrint(String message) {
  if (foundation.kDebugMode) {
    foundation.debugPrint(message);
  }
}

/// Utility for unified storage verification and cleanup
/// 
/// This handles:
/// - Current unified usage data verification
/// - Legacy storage cleanup  
/// - Data integrity checks
/// 
/// All users now use the UnifiedUsageStorage system.
class StorageMigrationUtility {
  
  /// Perform complete migration for all users
  static Future<MigrationResult> performFullMigration() async {
    try {
      migrationDebugPrint('🔄 Starting unified storage verification...');
      
      final result = MigrationResult();
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get overview of current storage state
      final overview = await _getStorageOverview(prefs);
      result.initialState = overview;
      
      migrationDebugPrint('📊 Storage state:');
      migrationDebugPrint('  - Current unified users: ${overview['currentUnifiedUsers'].length}');
      migrationDebugPrint('  - Legacy keys remaining: ${overview['legacyKeys'].length}');
      
      // 2. Report current unified users
      await _reportCurrentUnifiedUsers(prefs, result);
      
      // 3. Clean up any remaining legacy keys
      await _cleanupLegacyKeys(prefs, result);
      
      // 4. Verify integrity
      final finalOverview = await _getStorageOverview(prefs);
      result.finalState = finalOverview;
      result.success = true;
      
      migrationDebugPrint('✅ Storage verification completed');
      migrationDebugPrint('📊 Final state:');
      migrationDebugPrint('  - Active unified users: ${finalOverview['currentUnifiedUsers'].length}');
      migrationDebugPrint('  - Cleaned legacy keys: ${result.cleanedKeys.length}');
      
      return result;
      
    } catch (e) {
      migrationDebugPrint('❌ Storage verification failed: $e');
      return MigrationResult()
        ..success = false
        ..errors.add('Storage verification failed: $e');
    }
  }

  /// 🎯 Report current unified users (already in new system)
  static Future<void> _reportCurrentUnifiedUsers(SharedPreferences prefs, MigrationResult result) async {
    try {
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith('unified_usage_v3_')) {
          final userId = key.substring('unified_usage_v3_'.length);
          
          try {
            final dataJson = prefs.getString(key);
            if (dataJson != null) {
              final data = Map<String, dynamic>.from(
                (jsonDecode(dataJson) as Map<String, dynamic>)
              );
              
              final actionCounts = Map<String, int>.from(data['actionCounts'] ?? {});
              
              result.migratedUsers.add({
                'userId': userId,
                'type': userId.startsWith('guest_') ? 'current_guest' : 'current_authenticated',
                'currentActions': actionCounts,
                'source': 'unified_system',
              });
              
              migrationDebugPrint('📋 Current unified user: $userId (${actionCounts.length} action types)');
            }
          } catch (e) {
            result.errors.add('Failed to read current unified data for $userId: $e');
            migrationDebugPrint('❌ Failed to read current unified data for $userId: $e');
          }
        }
      }
    } catch (e) {
      result.errors.add('Failed to report current unified users: $e');
      migrationDebugPrint('❌ Failed to report current unified users: $e');
    }
  }

  /// Clean up legacy storage keys
  static Future<void> _cleanupLegacyKeys(SharedPreferences prefs, MigrationResult result) async {
    try {
      final allKeys = prefs.getKeys().toList();
      
      // Remove any legacy keys that might still exist
      for (final key in allKeys) {
        if (_isLegacyKey(key)) {
          await prefs.remove(key);
          result.cleanedKeys.add(key);
          migrationDebugPrint('🧹 Removed legacy key: $key');
        }
      }
      
      migrationDebugPrint('✅ Legacy cleanup completed: ${result.cleanedKeys.length} keys removed');
    } catch (e) {
      result.errors.add('Cleanup failed: $e');
      migrationDebugPrint('❌ Cleanup failed: $e');
    }
  }

  /// Check if a key is legacy and should be removed
  static bool _isLegacyKey(String key) {
    return key.startsWith('guest_grading_count') ||
           key.startsWith('guest_limit_reset_date') ||
           key.startsWith('auth_session_v2') ||
           key.startsWith('auth_guest_id_v2') ||
           key.startsWith('auth_guest_data_v2') ||
           key.startsWith('auth_migration_completed_v2') ||
           key.startsWith('auth_user_actions_v2_') ||
           key.startsWith('legacy_migration_completed_v3');
  }

  /// Get comprehensive storage overview
  static Future<Map<String, dynamic>> _getStorageOverview(SharedPreferences prefs) async {
    final allKeys = prefs.getKeys();
    
    final unifiedKeys = <String>[];
    final currentUnifiedUsers = <String>[];
    final legacyKeys = <String>[];
    final otherKeys = <String>[];
    
    for (final key in allKeys) {
      if (key.startsWith('unified_usage_v3_')) {
        unifiedKeys.add(key);
        // Extract user ID from unified key
        final userId = key.substring('unified_usage_v3_'.length);
        currentUnifiedUsers.add(userId);
      } else if (_isLegacyKey(key)) {
        legacyKeys.add(key);
      } else {
        otherKeys.add(key);
      }
    }
    
    return {
      'unifiedKeys': unifiedKeys,
      'currentUnifiedUsers': currentUnifiedUsers,
      'legacyKeys': legacyKeys,
      'otherKeys': otherKeys,
      'totalKeys': allKeys.length,
    };
  }

  /// Verify migration integrity
  static Future<VerificationResult> verifyMigration() async {
    try {
      final verification = VerificationResult();
      final prefs = await SharedPreferences.getInstance();
      
      // Check for remaining legacy keys
      final overview = await _getStorageOverview(prefs);
      verification.remainingLegacyKeys = overview['legacyKeys'].length;
      verification.unifiedUsersCount = overview['unifiedKeys'].length;
      
      // Verify unified data integrity
      for (final key in overview['unifiedKeys']) {
        try {
          final userId = key.substring('unified_usage_v3_'.length);
          final data = await UnifiedUsageStorage.getUsageData(userId);
          verification.verifiedUsers.add(userId);
          
          // Check data integrity
          if (data.actionCounts.isEmpty && data.dailyLimits.isEmpty) {
            verification.warnings.add('User $userId has empty data');
          }
        } catch (e) {
          // Extract userId safely for error reporting
          String userIdForError;
          try {
            userIdForError = key.substring('unified_usage_v3_'.length);
          } catch (_) {
            userIdForError = 'unknown';
          }
          verification.errors.add('Failed to verify user $userIdForError: $e');
        }
      }
      
      verification.success = verification.errors.isEmpty;
      
      migrationDebugPrint('📋 Migration verification completed:');
      migrationDebugPrint('  - Verified users: ${verification.verifiedUsers.length}');
      migrationDebugPrint('  - Remaining legacy keys: ${verification.remainingLegacyKeys}');
      migrationDebugPrint('  - Warnings: ${verification.warnings.length}');
      migrationDebugPrint('  - Errors: ${verification.errors.length}');
      
      return verification;
    } catch (e) {
      return VerificationResult()
        ..success = false
        ..errors.add('Verification failed: $e');
    }
  }

  /// Generate migration report
  static String generateMigrationReport(MigrationResult result, VerificationResult verification) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 UNIFIED STORAGE VERIFICATION REPORT');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    buffer.writeln('🔄 VERIFICATION SUMMARY:');
    buffer.writeln('  ✅ Success: ${result.success}');
    buffer.writeln('  👥 Active Users: ${result.migratedUsers.length}');
    buffer.writeln('  🧹 Cleaned Legacy Keys: ${result.cleanedKeys.length}');
    buffer.writeln('  ❌ Errors: ${result.errors.length}');
    buffer.writeln();
    
    if (result.migratedUsers.isNotEmpty) {
      buffer.writeln('👥 ACTIVE USERS:');
      for (final user in result.migratedUsers) {
        final userId = user['userId'] as String;
        final type = user['type'] as String;
        final actionCounts = user['currentActions'] as Map<String, int>? ?? {};
        final totalActions = actionCounts.values.fold(0, (sum, count) => sum + count);
        buffer.writeln('  - $userId ($type) - $totalActions actions');
      }
      buffer.writeln();
    }
    
    buffer.writeln('🔍 DATA INTEGRITY:');
    buffer.writeln('  ✅ Success: ${verification.success}');
    buffer.writeln('  👤 Verified Users: ${verification.verifiedUsers.length}');
    buffer.writeln('  🏚️ Legacy Keys Found: ${verification.remainingLegacyKeys}');
    buffer.writeln('  ⚠️ Warnings: ${verification.warnings.length}');
    buffer.writeln('  ❌ Errors: ${verification.errors.length}');
    buffer.writeln();
    
    if (result.errors.isNotEmpty || verification.errors.isNotEmpty) {
      buffer.writeln('❌ ERRORS:');
      for (final error in [...result.errors, ...verification.errors]) {
        buffer.writeln('  - $error');
      }
      buffer.writeln();
    }
    
    if (verification.warnings.isNotEmpty) {
      buffer.writeln('⚠️ WARNINGS:');
      for (final warning in verification.warnings) {
        buffer.writeln('  - $warning');
      }
      buffer.writeln();
    }
    
    buffer.writeln('🏁 Verification completed at: ${DateTime.now()}');
    
    return buffer.toString();
  }
}

/// Result of migration operation
class MigrationResult {
  bool success = false;
  List<Map<String, dynamic>> migratedUsers = [];
  List<String> cleanedKeys = [];
  List<String> errors = [];
  Map<String, dynamic> initialState = {};
  Map<String, dynamic> finalState = {};
}

/// Result of migration verification
class VerificationResult {
  bool success = false;
  List<String> verifiedUsers = [];
  int remainingLegacyKeys = 0;
  int unifiedUsersCount = 0;
  List<String> warnings = [];
  List<String> errors = [];
}

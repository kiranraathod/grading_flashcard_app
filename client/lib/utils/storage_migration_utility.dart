import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unified_usage_storage.dart';
import '../utils/config.dart';

/// Utility for migrating from legacy storage systems to unified storage
/// 
/// This handles the transition from:
/// - GuestUserManager storage
/// - Old SimpleActionTracker storage  
/// - WorkingSecureAuthStorage patterns
/// 
/// To the new UnifiedUsageStorage system.
class StorageMigrationUtility {
  
  /// Perform complete migration for all users
  static Future<MigrationResult> performFullMigration() async {
    try {
      debugPrint('🔄 Starting full storage migration...');
      
      final result = MigrationResult();
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get overview of current storage state
      final overview = await _getStorageOverview(prefs);
      result.initialState = overview;
      
      debugPrint('📊 Initial storage state:');
      debugPrint('  - Legacy guest keys: ${overview['legacyGuestKeys'].length}');
      debugPrint('  - Legacy user keys: ${overview['legacyUserKeys'].length}');
      debugPrint('  - Unified keys: ${overview['unifiedKeys'].length}');
      
      // 2. Migrate guest data
      await _migrateGuestData(prefs, result);
      
      // 3. Migrate user data
      await _migrateUserData(prefs, result);
      
      // 4. Clean up legacy keys
      await _cleanupLegacyKeys(prefs, result);
      
      // 5. Verify migration
      final finalOverview = await _getStorageOverview(prefs);
      result.finalState = finalOverview;
      result.success = true;
      
      debugPrint('✅ Migration completed successfully');
      debugPrint('📊 Final state:');
      debugPrint('  - Migrated users: ${result.migratedUsers.length}');
      debugPrint('  - Cleaned keys: ${result.cleanedKeys.length}');
      debugPrint('  - Errors: ${result.errors.length}');
      
      return result;
      
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      return MigrationResult()
        ..success = false
        ..errors.add('Migration failed: $e');
    }
  }

  /// Migrate guest user data
  static Future<void> _migrateGuestData(SharedPreferences prefs, MigrationResult result) async {
    try {
      // Check for legacy guest data
      final guestCount = prefs.getInt('guest_grading_count');
      final guestResetDate = prefs.getString('guest_limit_reset_date');
      
      if (guestCount != null && guestCount > 0) {
        debugPrint('📦 Migrating guest data: count=$guestCount, resetDate=$guestResetDate');
        
        // Create guest user ID
        final guestId = 'migrated_guest_${DateTime.now().millisecondsSinceEpoch}';
        
        // Create unified data
        final guestData = UnifiedUsageData.empty(guestId).copyWith(
          actionCounts: {'flashcard_grading': guestCount},
          dailyLimits: {
            'flashcard_grading': AuthConfig.guestMaxGradingActions,
            'interview_practice': AuthConfig.guestMaxInterviewActions,
            'content_generation': AuthConfig.guestMaxContentGeneration,
            'ai_assistance': AuthConfig.guestMaxAiAssistance,
          },
        );
        
        // Store migrated data
        await UnifiedUsageStorage.storeUsageData(guestId, guestData);
        
        result.migratedUsers.add({
          'userId': guestId,
          'type': 'guest',
          'originalCount': guestCount,
          'resetDate': guestResetDate,
        });
        
        debugPrint('✅ Guest data migrated to: $guestId');
      }
    } catch (e) {
      result.errors.add('Guest migration failed: $e');
      debugPrint('❌ Guest migration failed: $e');
    }
  }

  /// Migrate authenticated user data
  static Future<void> _migrateUserData(SharedPreferences prefs, MigrationResult result) async {
    try {
      final allKeys = prefs.getKeys();
      
      // Find all legacy user action keys
      for (final key in allKeys) {
        if (key.startsWith('auth_user_actions_v2_')) {
          final userId = key.substring('auth_user_actions_v2_'.length);
          
          try {
            final actionsJson = prefs.getString(key);
            if (actionsJson != null) {
              final actions = Map<String, dynamic>.from(
                (jsonDecode(actionsJson) as Map<String, dynamic>)
              );
              
              debugPrint('📦 Migrating user data: $userId');
              debugPrint('   Actions: $actions');
              
              // Convert to int map
              final actionCounts = <String, int>{};
              for (final entry in actions.entries) {
                if (entry.value is int) {
                  actionCounts[entry.key] = entry.value;
                } else if (entry.value is String) {
                  actionCounts[entry.key] = int.tryParse(entry.value) ?? 0;
                }
              }
              
              // Create unified data
              final userData = UnifiedUsageData.empty(userId).copyWith(
                actionCounts: actionCounts,
                dailyLimits: {
                  'flashcard_grading': AuthConfig.authenticatedMaxGradingActions,
                  'interview_practice': AuthConfig.authenticatedMaxInterviewActions,
                  'content_generation': AuthConfig.authenticatedMaxContentGeneration,
                  'ai_assistance': AuthConfig.authenticatedMaxAiAssistance,
                },
              );
              
              // Store migrated data
              await UnifiedUsageStorage.storeUsageData(userId, userData);
              
              result.migratedUsers.add({
                'userId': userId,
                'type': 'authenticated',
                'originalActions': actionCounts,
              });
              
              debugPrint('✅ User data migrated: $userId');
            }
          } catch (e) {
            result.errors.add('User migration failed for $userId: $e');
            debugPrint('❌ User migration failed for $userId: $e');
          }
        }
      }
    } catch (e) {
      result.errors.add('User data migration failed: $e');
      debugPrint('❌ User data migration failed: $e');
    }
  }

  /// Clean up legacy storage keys
  static Future<void> _cleanupLegacyKeys(SharedPreferences prefs, MigrationResult result) async {
    try {
      final keysToRemove = [
        'guest_grading_count',
        'guest_limit_reset_date',
        'auth_session_v2',
        'auth_guest_id_v2',
        'auth_guest_data_v2',
        'auth_migration_completed_v2',
      ];
      
      // Remove specific legacy keys
      for (final key in keysToRemove) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          result.cleanedKeys.add(key);
          debugPrint('🧹 Removed legacy key: $key');
        }
      }
      
      // Remove legacy user action keys
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith('auth_user_actions_v2_')) {
          await prefs.remove(key);
          result.cleanedKeys.add(key);
          debugPrint('🧹 Removed legacy user key: $key');
        }
      }
      
      debugPrint('✅ Legacy cleanup completed: ${result.cleanedKeys.length} keys removed');
    } catch (e) {
      result.errors.add('Cleanup failed: $e');
      debugPrint('❌ Cleanup failed: $e');
    }
  }

  /// Get comprehensive storage overview
  static Future<Map<String, dynamic>> _getStorageOverview(SharedPreferences prefs) async {
    final allKeys = prefs.getKeys();
    
    final legacyGuestKeys = <String>[];
    final legacyUserKeys = <String>[];
    final unifiedKeys = <String>[];
    final otherKeys = <String>[];
    
    for (final key in allKeys) {
      if (key.startsWith('guest_')) {
        legacyGuestKeys.add(key);
      } else if (key.startsWith('auth_user_actions_v2_')) {
        legacyUserKeys.add(key);
      } else if (key.startsWith('unified_usage_v3_')) {
        unifiedKeys.add(key);
      } else if (key.startsWith('auth_')) {
        otherKeys.add(key);
      }
    }
    
    return {
      'legacyGuestKeys': legacyGuestKeys,
      'legacyUserKeys': legacyUserKeys,
      'unifiedKeys': unifiedKeys,
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
      verification.remainingLegacyKeys = overview['legacyGuestKeys'].length + 
                                        overview['legacyUserKeys'].length;
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
      
      debugPrint('📋 Migration verification completed:');
      debugPrint('  - Verified users: ${verification.verifiedUsers.length}');
      debugPrint('  - Remaining legacy keys: ${verification.remainingLegacyKeys}');
      debugPrint('  - Warnings: ${verification.warnings.length}');
      debugPrint('  - Errors: ${verification.errors.length}');
      
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
    
    buffer.writeln('📊 STORAGE MIGRATION REPORT');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    buffer.writeln('🔄 MIGRATION SUMMARY:');
    buffer.writeln('  ✅ Success: ${result.success}');
    buffer.writeln('  👥 Migrated Users: ${result.migratedUsers.length}');
    buffer.writeln('  🧹 Cleaned Keys: ${result.cleanedKeys.length}');
    buffer.writeln('  ❌ Errors: ${result.errors.length}');
    buffer.writeln();
    
    if (result.migratedUsers.isNotEmpty) {
      buffer.writeln('👥 MIGRATED USERS:');
      for (final user in result.migratedUsers) {
        buffer.writeln('  - ${user['userId']} (${user['type']})');
      }
      buffer.writeln();
    }
    
    buffer.writeln('🔍 VERIFICATION SUMMARY:');
    buffer.writeln('  ✅ Success: ${verification.success}');
    buffer.writeln('  👤 Verified Users: ${verification.verifiedUsers.length}');
    buffer.writeln('  🏚️ Remaining Legacy Keys: ${verification.remainingLegacyKeys}');
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
    
    buffer.writeln('🏁 Migration completed at: ${DateTime.now()}');
    
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

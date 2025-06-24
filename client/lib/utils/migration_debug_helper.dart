import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import 'enhanced_safe_map_converter.dart';

/// Debug helper for tracking guest data migration issues
class MigrationDebugHelper {
  /// Debug the current state of guest data before migration
  static Future<void> debugGuestDataState() async {
    try {
      debugPrint('🔍 MIGRATION DEBUG: Checking guest data state...');

      // Check Hive storage
      final flashcardData = StorageService.getFlashcardSets();
      final interviewData = StorageService.getInterviewQuestions();

      debugPrint('📦 Hive Flashcard Data:');
      if (flashcardData != null) {
        debugPrint('  - Count: ${flashcardData.length}');
        debugPrint('  - Type: ${flashcardData.runtimeType}');
        if (flashcardData.isNotEmpty) {
          debugPrint('  - First item type: ${flashcardData.first.runtimeType}');
          // 🔧 FIXED: Use Enhanced SafeMapConverter to avoid LinkedMap issues
          final firstItem = EnhancedSafeMapConverter.safeConvert(flashcardData.first);
          if (firstItem != null) {
            debugPrint('  - First item keys: ${firstItem.keys.toList()}');
          } else {
            debugPrint('  - First item could not be safely converted');
          }
        }
      } else {
        debugPrint('  - No flashcard data found');
      }

      debugPrint('📦 Hive Interview Data:');
      if (interviewData != null) {
        debugPrint('  - Count: ${interviewData.length}');
        debugPrint('  - Type: ${interviewData.runtimeType}');
      } else {
        debugPrint('  - No interview data found');
      }

      // Check SharedPreferences for any existing migration data
      final prefs = await SharedPreferences.getInstance();
      final allKeys =
          prefs.getKeys().where((key) => key.contains('migrated')).toList();

      debugPrint('🗄️ Existing Migration Keys:');
      for (final key in allKeys) {
        debugPrint('  - $key');
      }
    } catch (e) {
      debugPrint('❌ Migration debug failed: $e');
    }
  }

  /// Debug the migration result for a specific user
  static Future<void> debugMigrationResult(String userId) async {
    try {
      debugPrint(
        '🔍 MIGRATION DEBUG: Checking migration result for user $userId...',
      );

      final prefs = await SharedPreferences.getInstance();

      // Check if migration flag exists
      final hasMigrated =
          prefs.getBool('user_has_migrated_data_$userId') ?? false;
      debugPrint('✅ Migration flag exists: $hasMigrated');

      // Check if migrated data exists
      final backupKey = 'user_migrated_data_$userId';
      final dataString = prefs.getString(backupKey);

      if (dataString != null) {
        debugPrint('✅ Migrated data found:');
        try {
          // 🔧 FIXED: Use Enhanced SafeMapConverter for JSON decoding
          final data = EnhancedSafeMapConverter.jsonCycleConvert(dataString);
          if (data != null) {
            debugPrint('  - Data keys: ${data.keys.toList()}');
            if (data['flashcards'] != null) {
              debugPrint('  - Flashcard sets: ${data['flashcards'].length}');
              debugPrint('  - Migration timestamp: ${data['migrated_at']}');
              debugPrint('  - Migration source: ${data['migration_source']}');
            }
          } else {
            debugPrint('❌ Failed to safely decode migrated data');
          }
        } catch (e) {
          debugPrint('❌ Failed to parse migrated data: $e');
        }
      } else {
        debugPrint('❌ No migrated data found for user $userId');
      }

      // Check migration status flag
      final migrationFlag =
          prefs.getBool('data_migrated_for_user_$userId') ?? false;
      debugPrint('✅ Data migration flag: $migrationFlag');
    } catch (e) {
      debugPrint('❌ Migration result debug failed: $e');
    }
  }

  /// Verify that migrated data can be properly loaded
  static Future<void> verifyMigratedDataLoading(String userId) async {
    try {
      debugPrint(
        '🔍 MIGRATION DEBUG: Verifying migrated data loading for user $userId...',
      );

      final migratedData = await StorageService.getUserMigratedData(userId);

      if (migratedData != null) {
        debugPrint('✅ Migrated data retrieved successfully:');
        debugPrint('  - Data type: ${migratedData.runtimeType}');
        debugPrint('  - Keys: ${migratedData.keys.toList()}');

        if (migratedData['flashcards'] != null) {
          final flashcards = migratedData['flashcards'];
          debugPrint('  - Flashcards type: ${flashcards.runtimeType}');
          debugPrint(
            '  - Flashcards count: ${flashcards is List ? flashcards.length : 'N/A'}',
          );

          if (flashcards is List && flashcards.isNotEmpty) {
            final firstSet = flashcards.first;
            debugPrint('  - First set type: ${firstSet.runtimeType}');
            if (firstSet is Map) {
              debugPrint('  - First set keys: ${firstSet.keys.toList()}');

              if (firstSet['flashcards'] != null) {
                final cards = firstSet['flashcards'];
                debugPrint(
                  '  - Cards in first set: ${cards is List ? cards.length : 'N/A'}',
                );
              }
            } else {
              debugPrint('  - First set is not a Map');
            }
          }
        }
      } else {
        debugPrint('❌ No migrated data found for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Migrated data verification failed: $e');
    }
  }

  /// Complete debug report for migration troubleshooting
  static Future<void> generateMigrationReport(String? userId) async {
    debugPrint('📊 MIGRATION DEBUG REPORT');
    debugPrint('=' * 50);

    await debugGuestDataState();

    if (userId != null) {
      debugPrint('\n🔍 User-specific migration analysis:');
      await debugMigrationResult(userId);
      await verifyMigratedDataLoading(userId);
    }

    debugPrint('=' * 50);
  }
}

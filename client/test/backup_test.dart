import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_flashcard_app/services/migration_backup_service.dart';

void main() {
  group('Task 1.3 Migration Backup System Tests', () {
    late MigrationBackupService backupService;
    
    setUp(() {
      backupService = MigrationBackupService();
      SharedPreferences.setMockInitialValues({});
    });
    
    tearDown(() async {
      // Clean up any test backups
      final backups = await backupService.listBackups();
      for (final backup in backups) {
        await backupService.deleteBackup(backup.id);
      }
    });
    
    group('Backup Creation Tests', () {
      test('should create backup with sample data', () async {
        // Setup test data
        SharedPreferences.setMockInitialValues({
          'interview_questions': '[{"id":"1","text":"Test question","category":"technical"}]',
          'flashcard_sets': ['{"id":"1","title":"Test set"}'],
          'recently_viewed_items': '[{"id":"1","type":"question"}]',
          'user_preference_1': 'test_value',
        });
        
        final result = await backupService.createFullBackup(label: 'test_backup');
        
        expect(result.isSuccess, isTrue);
        expect(result.metadata, isNotNull);
        expect(result.metadata!.label, equals('test_backup'));
        expect(result.metadata!.dataTypes.length, greaterThan(0));
      });
      
      test('should create backup with empty data', () async {
        SharedPreferences.setMockInitialValues({});
        
        final result = await backupService.createFullBackup(label: 'empty_backup');
        
        expect(result.isSuccess, isTrue);
        expect(result.metadata, isNotNull);
        expect(result.metadata!.label, equals('empty_backup'));
      });
      
      test('should include all data types in backup', () async {
        SharedPreferences.setMockInitialValues({
          'interview_questions': '[{"id":"1","text":"Test"}]',
          'flashcard_sets': ['{"id":"1","title":"Test"}'],
          'recently_viewed_items': '[{"id":"1"}]',
          'user_progress_1': 'progress_data',
          'question_cache_1': 'cache_data',
          'activity_streak': '5',
          'theme_preference': 'dark',
        });
        
        final result = await backupService.createFullBackup(label: 'comprehensive_backup');
        
        expect(result.isSuccess, isTrue);
        expect(result.metadata!.dataTypes, contains('interview_questions'));
        expect(result.metadata!.dataTypes, contains('flashcard_sets'));
        expect(result.metadata!.dataTypes, contains('recent_views'));
        expect(result.metadata!.dataTypes, contains('progress_data'));
        expect(result.metadata!.dataTypes, contains('cache_data'));
        expect(result.metadata!.dataTypes, contains('user_preferences'));
      });
    });
    
    group('Backup Validation Tests', () {
      test('should validate valid backup', () async {
        SharedPreferences.setMockInitialValues({
          'interview_questions': '[{"id":"1","text":"Test question"}]',
        });
        
        final createResult = await backupService.createFullBackup(label: 'valid_backup');
        expect(createResult.isSuccess, isTrue);
        
        final validationResult = await backupService.validateBackup(createResult.metadata!.id);
        expect(validationResult.isValid, isTrue);
      });
      
      test('should detect corrupted backup', () async {
        // Create a backup first
        SharedPreferences.setMockInitialValues({
          'interview_questions': '[{"id":"1","text":"Test"}]',
        });
        
        final createResult = await backupService.createFullBackup(label: 'test_backup');
        expect(createResult.isSuccess, isTrue);
        
        // Manually corrupt the backup data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(createResult.metadata!.id, 'invalid_json{');
        
        final validationResult = await backupService.validateBackup(createResult.metadata!.id);
        expect(validationResult.isValid, isFalse);
        expect(validationResult.error, isNotNull);
      });
      
      test('should fail validation for non-existent backup', () async {
        final validationResult = await backupService.validateBackup('non_existent_backup');
        expect(validationResult.isValid, isFalse);
        expect(validationResult.error, contains('not found'));
      });
    });
    
    group('Backup Listing Tests', () {
      test('should list multiple backups', () async {
        SharedPreferences.setMockInitialValues({
          'test_data': 'value',
        });
        
        // Create multiple backups
        await backupService.createFullBackup(label: 'backup_1');
        await backupService.createFullBackup(label: 'backup_2');
        await backupService.createFullBackup(label: 'backup_3');
        
        final backups = await backupService.listBackups();
        
        expect(backups.length, equals(3));
        expect(backups.any((b) => b.label == 'backup_1'), isTrue);
        expect(backups.any((b) => b.label == 'backup_2'), isTrue);
        expect(backups.any((b) => b.label == 'backup_3'), isTrue);
      });
      
      test('should sort backups by timestamp (newest first)', () async {
        SharedPreferences.setMockInitialValues({
          'test_data': 'value',
        });
        
        // Create backups with delays to ensure different timestamps
        await backupService.createFullBackup(label: 'old_backup');
        await Future.delayed(const Duration(milliseconds: 10));
        await backupService.createFullBackup(label: 'new_backup');
        
        final backups = await backupService.listBackups();
        
        expect(backups.length, equals(2));
        expect(backups.first.label, equals('new_backup'));
        expect(backups.last.label, equals('old_backup'));
      });
      
      test('should return empty list when no backups exist', () async {
        final backups = await backupService.listBackups();
        expect(backups, isEmpty);
      });
    });
    
    group('Backup Restoration Tests', () {
      test('should restore data from backup', () async {
        // Setup initial data
        final originalData = {
          'interview_questions': '[{"id":"1","text":"Original question"}]',
          'flashcard_sets': ['{"id":"1","title":"Original set"}'],
          'user_preference': 'original_value',
        };
        
        SharedPreferences.setMockInitialValues(originalData);
        
        // Create backup
        final backupResult = await backupService.createFullBackup(label: 'restore_test');
        expect(backupResult.isSuccess, isTrue);
        
        // Modify data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('interview_questions', '[{"id":"2","text":"Modified question"}]');
        await prefs.setString('user_preference', 'modified_value');
        
        // Restore from backup
        final restoreResult = await backupService.restoreFromBackup(backupResult.metadata!.id);
        expect(restoreResult.isSuccess, isTrue);
        
        // Verify data was restored
        final restoredQuestions = prefs.getString('interview_questions');
        final restoredPreference = prefs.getString('user_preference');
        
        expect(restoredQuestions, equals('[{"id":"1","text":"Original question"}]'));
        expect(restoredPreference, equals('original_value'));
      });
      
      test('should create safety backup before restore', () async {
        SharedPreferences.setMockInitialValues({
          'test_data': 'initial_value',
        });
        
        // Create initial backup
        final backupResult = await backupService.createFullBackup(label: 'initial_backup');
        expect(backupResult.isSuccess, isTrue);
        
        // Modify data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('test_data', 'modified_value');
        
        // Count backups before restore
        final backupsBeforeRestore = await backupService.listBackups();
        final countBefore = backupsBeforeRestore.length;
        
        // Restore (should create safety backup)
        final restoreResult = await backupService.restoreFromBackup(backupResult.metadata!.id);
        expect(restoreResult.isSuccess, isTrue);
        
        // Check that additional backup was created
        final backupsAfterRestore = await backupService.listBackups();
        expect(backupsAfterRestore.length, equals(countBefore + 1));
        
        // Check for safety backup
        final safetyBackup = backupsAfterRestore.firstWhere(
          (b) => b.label.contains('pre_restore_safety'),
        );
        expect(safetyBackup, isNotNull);
      });
      
      test('should fail restore for non-existent backup', () async {
        final restoreResult = await backupService.restoreFromBackup('non_existent');
        expect(restoreResult.isSuccess, isFalse);
        expect(restoreResult.error, contains('not found'));
      });
    });
    
    group('Backup Deletion Tests', () {
      test('should delete backup successfully', () async {
        SharedPreferences.setMockInitialValues({
          'test_data': 'value',
        });
        
        final createResult = await backupService.createFullBackup(label: 'delete_test');
        expect(createResult.isSuccess, isTrue);
        
        // Verify backup exists
        final backupsBeforeDelete = await backupService.listBackups();
        expect(backupsBeforeDelete.length, equals(1));
        
        // Delete backup
        final deleteResult = await backupService.deleteBackup(createResult.metadata!.id);
        expect(deleteResult, isTrue);
        
        // Verify backup is gone
        final backupsAfterDelete = await backupService.listBackups();
        expect(backupsAfterDelete.length, equals(0));
      });
      
      test('should return false for non-existent backup deletion', () async {
        final deleteResult = await backupService.deleteBackup('non_existent');
        expect(deleteResult, isFalse);
      });
    });
    
    group('Backup Cleanup Tests', () {
      test('should keep only maximum number of backups', () async {
        SharedPreferences.setMockInitialValues({
          'test_data': 'value',
        });
        
        // Create more backups than the maximum (assuming max is 10)
        for (int i = 0; i < 15; i++) {
          await backupService.createFullBackup(label: 'backup_$i');
          // Small delay to ensure different timestamps
          await Future.delayed(const Duration(milliseconds: 1));
        }
        
        final backups = await backupService.listBackups();
        
        // Should have cleaned up to maximum number (10)
        expect(backups.length, lessThanOrEqualTo(10));
        
        // Should keep the most recent ones
        expect(backups.first.label, contains('backup_14'));
      });
    });
    
    group('Data Size Calculation Tests', () {
      test('should calculate backup data size correctly', () async {
        final testData = {
          'interview_questions': '[{"id":"1","text":"Test question with some content"}]',
          'flashcard_sets': ['{"id":"1","title":"Test flashcard set"}'],
          'user_preference': 'test_preference_value',
        };
        
        SharedPreferences.setMockInitialValues(testData);
        
        final result = await backupService.createFullBackup(label: 'size_test');
        expect(result.isSuccess, isTrue);
        
        final metadata = result.metadata!;
        expect(metadata.dataSize, greaterThan(0));
        expect(metadata.formattedSize, isNotEmpty);
        
        // Size should be reasonable for test data
        expect(metadata.dataSize, lessThan(10000)); // Less than 10KB for test data
      });
    });
    
    group('Integration Tests', () {
      test('should work with realistic data scenario', () async {
        // Setup realistic data similar to actual app usage
        final realisticData = {
          'interview_questions': '''[
            {"id":"1","text":"What is machine learning?","category":"technical","categoryId":"machine_learning","difficulty":"entry","isDraft":false},
            {"id":"2","text":"Explain neural networks","category":"technical","categoryId":"machine_learning","difficulty":"mid","isDraft":false}
          ]''',
          'flashcard_sets': [
            '{"id":"set1","title":"ML Basics","rating":4.5,"flashcards":[{"id":"f1","question":"What is ML?","answer":"Machine Learning"}]}',
            '{"id":"set2","title":"Statistics","rating":4.0,"flashcards":[{"id":"f2","question":"What is mean?","answer":"Average"}]}'
          ],
          'recently_viewed_items': '[{"id":"1","type":"question","timestamp":"2024-01-01T00:00:00.000Z"}]',
          'user_daily_goal': '10',
          'user_weekly_streak': '5',
          'theme_preference': 'dark',
          'question_cache_ml_1': '{"cached_data":"test"}',
        };
        
        SharedPreferences.setMockInitialValues(realisticData);
        
        // Test complete backup and restore cycle
        final backupResult = await backupService.createFullBackup(label: 'realistic_test');
        expect(backupResult.isSuccess, isTrue);
        expect(backupResult.metadata!.dataTypes.length, greaterThanOrEqualTo(5));
        
        // Validate backup
        final validationResult = await backupService.validateBackup(backupResult.metadata!.id);
        expect(validationResult.isValid, isTrue);
        
        // Modify some data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_daily_goal', '15');
        await prefs.remove('recently_viewed_items');
        
        // Restore and verify
        final restoreResult = await backupService.restoreFromBackup(backupResult.metadata!.id);
        expect(restoreResult.isSuccess, isTrue);
        
        expect(prefs.getString('user_daily_goal'), equals('10'));
        expect(prefs.getString('recently_viewed_items'), isNotNull);
      });
    });
  });
}
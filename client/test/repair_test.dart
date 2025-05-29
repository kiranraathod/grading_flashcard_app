import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_flashcard_app/services/data_repair_service.dart';
import 'package:flutter_flashcard_app/services/data_validation_service.dart';

/// Comprehensive test suite for Task 1.2: Data Repair Service
/// 
/// These tests validate that the data repair implementation correctly fixes
/// corruption patterns identified by the validation system.
void main() {
  group('Task 1.2 Data Repair Tests', () {
    late SharedPreferences mockPrefs;
    late DataRepairService repairService;
    late DataValidationService validationService;

    setUp(() async {
      // Initialize mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      repairService = DataRepairService();
      validationService = DataValidationService();
    });

    tearDown(() async {
      // Clean up after each test
      await mockPrefs.clear();
    });

    group('Critical Repairs - Missing categoryId', () {
      test('should repair missing categoryId fields in interview questions', () async {
        // Arrange: Create questions without categoryId
        final corruptedQuestions = [
          {
            'id': 'test-1',
            'text': 'What is machine learning?',
            'category': 'technical',
            'subtopic': 'ML Basics',
            'difficulty': 'entry',
            'answer': 'ML is a type of AI...',
            // Missing categoryId - should be repaired
          },
          {
            'id': 'test-2',
            'text': 'Explain neural networks',
            'category': 'applied',
            'subtopic': 'Deep Learning',
            'difficulty': 'mid',
            'answer': 'Neural networks are...',
            'categoryId': null, // Null categoryId - should be repaired
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(corruptedQuestions));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Repairs should be successful
        expect(result.wasSuccessful, isTrue);
        expect(result.repairs.length, greaterThanOrEqualTo(2));
        
        // Verify specific repairs
        final categoryIdRepairs = result.repairs
            .where((repair) => repair.contains('Added missing categoryId'))
            .toList();
        expect(categoryIdRepairs.length, equals(2));
        
        // Verify the actual data was repaired
        final repairedJson = mockPrefs.getString('interview_questions');
        final repairedQuestions = jsonDecode(repairedJson!) as List;
        
        expect(repairedQuestions[0]['categoryId'], equals('data_analysis')); // technical -> data_analysis
        expect(repairedQuestions[1]['categoryId'], equals('machine_learning')); // applied -> machine_learning
      });

      test('should use correct category mapping for categoryId repair', () async {
        // Arrange: Create questions with various legacy categories
        final questionsWithLegacyCategories = [
          {'id': '1', 'category': 'technical', 'text': 'Q1', 'subtopic': 'S1', 'difficulty': 'entry'},
          {'id': '2', 'category': 'applied', 'text': 'Q2', 'subtopic': 'S2', 'difficulty': 'entry'},
          {'id': '3', 'category': 'behavioral', 'text': 'Q3', 'subtopic': 'S3', 'difficulty': 'entry'},
          {'id': '4', 'category': 'case', 'text': 'Q4', 'subtopic': 'S4', 'difficulty': 'entry'},
          {'id': '5', 'category': 'job', 'text': 'Q5', 'subtopic': 'S5', 'difficulty': 'entry'},
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithLegacyCategories));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Check correct mapping
        final repairedJson = mockPrefs.getString('interview_questions');
        final repairedQuestions = jsonDecode(repairedJson!) as List;
        
        expect(repairedQuestions[0]['categoryId'], equals('data_analysis'));    // technical
        expect(repairedQuestions[1]['categoryId'], equals('machine_learning')); // applied
        expect(repairedQuestions[2]['categoryId'], equals('python'));          // behavioral
        expect(repairedQuestions[3]['categoryId'], equals('statistics'));      // case
        expect(repairedQuestions[4]['categoryId'], equals('web_development')); // job
        
        expect(result.wasSuccessful, isTrue);
      });
    });

    group('Boolean Type Repairs', () {
      test('should convert string booleans to proper boolean values', () async {
        // Arrange: Create questions with string booleans
        final questionsWithStringBooleans = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test',
            'difficulty': 'entry',
            'isDraft': 'false',     // String boolean
            'isStarred': 'true',    // String boolean
            'isCompleted': 'false', // String boolean
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithStringBooleans));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Boolean fields should be converted
        expect(result.wasSuccessful, isTrue);
        
        final booleanRepairs = result.repairs
            .where((repair) => repair.contains('Fixed boolean field'))
            .toList();
        expect(booleanRepairs.length, equals(3));
        
        // Verify actual data
        final repairedJson = mockPrefs.getString('interview_questions');
        final repairedQuestions = jsonDecode(repairedJson!) as List;
        final question = repairedQuestions[0];
        
        expect(question['isDraft'], isA<bool>());
        expect(question['isStarred'], isA<bool>());
        expect(question['isCompleted'], isA<bool>());
        expect(question['isDraft'], equals(false));
        expect(question['isStarred'], equals(true));
        expect(question['isCompleted'], equals(false));
      });
    });

    group('Invalid Enum Repairs', () {
      test('should fix invalid difficulty enum values', () async {
        // Arrange: Create questions with invalid difficulty values
        final questionsWithInvalidDifficulty = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test',
            'difficulty': 'invalid_difficulty', // Invalid enum
          },
          {
            'id': 'test-2',
            'text': 'Test question 2',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test',
            'difficulty': 'expert', // Invalid enum (should be 'senior')
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithInvalidDifficulty));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Difficulty values should be fixed
        expect(result.wasSuccessful, isTrue);
        
        final difficultyRepairs = result.repairs
            .where((repair) => repair.contains('Fixed invalid difficulty'))
            .toList();
        expect(difficultyRepairs.length, equals(2));
        
        // Verify actual data - both should default to 'entry'
        final repairedJson = mockPrefs.getString('interview_questions');
        final repairedQuestions = jsonDecode(repairedJson!) as List;
        
        expect(repairedQuestions[0]['difficulty'], equals('entry'));
        expect(repairedQuestions[1]['difficulty'], equals('entry'));
      });
    });

    group('Missing Required Fields Repairs', () {
      test('should add missing required fields with appropriate defaults', () async {
        // Arrange: Create questions with missing required fields
        final questionsWithMissingFields = [
          {
            'id': 'test-1',
            'category': 'technical',
            'categoryId': 'data_analysis',
            // Missing 'text', 'subtopic', 'difficulty'
          },
          {
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test',
            'difficulty': 'entry',
            // Missing 'id'
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithMissingFields));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Missing fields should be added
        expect(result.wasSuccessful, isTrue);
        
        final fieldRepairs = result.repairs
            .where((repair) => repair.contains('Fixed missing/empty field'))
            .toList();
        expect(fieldRepairs.length, greaterThanOrEqualTo(4)); // text, subtopic, difficulty, id
        
        // Verify actual data
        final repairedJson = mockPrefs.getString('interview_questions');
        final repairedQuestions = jsonDecode(repairedJson!) as List;
        
        // First question should have all required fields
        expect(repairedQuestions[0]['text'], isNotNull);
        expect(repairedQuestions[0]['subtopic'], isNotNull);
        expect(repairedQuestions[0]['difficulty'], isNotNull);
        
        // Second question should have generated ID
        expect(repairedQuestions[1]['id'], isNotNull);
        expect(repairedQuestions[1]['id'].toString(), contains('repair_'));
      });
    });

    group('Flashcard Set Repairs', () {
      test('should repair flashcard sets with missing required fields', () async {
        // Arrange: Create corrupted flashcard sets
        final corruptedSets = [
          jsonEncode({
            // Missing 'id' field
            'title': 'Test Set',
            'flashcards': [
              {
                'id': '1',
                'question': 'Q1',
                'answer': 'A1',
              }
            ],
          }),
          jsonEncode({
            'id': 'set-2',
            // Missing 'title' field
            'flashcards': [
              {
                // Missing 'id' field in flashcard
                'question': 'Q2',
                'answer': 'A2',
              }
            ],
          })
        ];

        await mockPrefs.setStringList('flashcard_sets', corruptedSets);

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Flashcard sets should be repaired
        expect(result.wasSuccessful, isTrue);
        
        // Verify repairs were applied
        final setRepairs = result.repairs
            .where((repair) => repair.contains('flashcard_sets'))
            .toList();
        expect(setRepairs.length, greaterThan(0));
        
        // Verify actual data
        final repairedSets = mockPrefs.getStringList('flashcard_sets');
        expect(repairedSets, isNotNull);
        expect(repairedSets!.length, equals(2));
        
        final set1 = jsonDecode(repairedSets[0]);
        expect(set1['id'], isNotNull); // Should have generated ID
        expect(set1['title'], equals('Test Set'));
        
        final set2 = jsonDecode(repairedSets[1]);
        expect(set2['id'], equals('set-2'));
        expect(set2['title'], isNotNull); // Should have generated title
      });
    });

    group('Integration with Validation', () {
      test('should resolve blocking issues identified by validation', () async {
        // Arrange: Create data with known validation failures
        final problematicQuestions = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - validation blocker
            'subtopic': 'Test',
            'difficulty': 'invalid', // Invalid enum - validation error
            'isDraft': 'false',      // String boolean - validation warning
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(problematicQuestions));

        // Verify initial validation shows blocking issues
        final preRepairValidation = await validationService.validateAllStoredData();
        expect(preRepairValidation.hasBlockingIssues, isTrue);
        expect(preRepairValidation.criticalErrors.length, greaterThan(0));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Post-repair validation should show no blocking issues
        expect(result.wasSuccessful, isTrue);
        expect(result.postRepairValidation, isNotNull);
        expect(result.postRepairValidation!.hasBlockingIssues, isFalse);
        expect(result.postRepairValidation!.criticalErrors.length, equals(0));
        
        // Double-check with fresh validation
        final finalValidation = await validationService.validateAllStoredData();
        expect(finalValidation.hasBlockingIssues, isFalse);
      });
    });

    group('Backup Creation', () {
      test('should create backup before repair operations', () async {
        // Arrange: Set up data to repair
        final testData = [
          {
            'id': 'test-1',
            'category': 'technical',
            'text': 'Test',
            'subtopic': 'Test',
            'difficulty': 'entry',
            // Missing categoryId for repair
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(testData));

        // Act: Run repair
        final result = await repairService.repairAllData();

        // Assert: Backup should be created
        expect(result.wasSuccessful, isTrue);
        
        final backupInfo = result.info
            .where((info) => info.contains('Created repair backup'))
            .toList();
        expect(backupInfo.length, equals(1));
        
        // Verify backup exists in SharedPreferences
        final allKeys = mockPrefs.getKeys();
        final backupKeys = allKeys.where((key) => key.startsWith('repair_backup_')).toList();
        expect(backupKeys.length, equals(1));
        
        // Verify backup contains original data
        final backupData = jsonDecode(mockPrefs.getString(backupKeys.first)!);
        expect(backupData['interview_questions'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle corrupted JSON gracefully', () async {
        // Arrange: Set corrupted JSON
        await mockPrefs.setString('interview_questions', 'invalid{json}structure');

        // Act: Run repair (should not crash)
        final result = await repairService.repairAllData();

        // Assert: Should handle error gracefully
        expect(result, isNotNull);
        expect(result.errors.length, greaterThan(0));
        expect(result.wasSuccessful, isFalse);
        
        final jsonErrors = result.errors
            .where((error) => error.contains('Failed to repair'))
            .toList();
        expect(jsonErrors.length, greaterThan(0));
      });

      test('should handle empty data gracefully', () async {
        // Arrange: No data to repair
        // Act: Run repair on empty data
        final result = await repairService.repairAllData();

        // Assert: Should complete without errors
        expect(result.wasSuccessful, isTrue);
        expect(result.info.length, greaterThan(0));
        
        final noDataInfo = result.info
            .where((info) => info.contains('No') && info.contains('to repair'))
            .toList();
        expect(noDataInfo.length, greaterThan(0));
      });
    });

    group('Repair Needed Check', () {
      test('should correctly identify when repairs are needed', () async {
        // Arrange: Create data with issues
        final problematicData = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - should need repair
            'subtopic': 'Test',
            'difficulty': 'entry',
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(problematicData));

        // Act: Check if repair is needed
        final needed = await repairService.repairNeeded();

        // Assert: Should indicate repair is needed
        expect(needed, isTrue);
      });

      test('should correctly identify when no repairs are needed', () async {
        // Arrange: Create valid data
        final validData = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis', // Present and valid
            'subtopic': 'Test',
            'difficulty': 'entry',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(validData));

        // Act: Check if repair is needed
        final needed = await repairService.repairNeeded();

        // Assert: Should indicate no repair needed
        expect(needed, isFalse);
      });
    });
  });
}

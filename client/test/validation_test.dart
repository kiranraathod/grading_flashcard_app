import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_flashcard_app/services/data_validation_service.dart';
import 'package:flutter_flashcard_app/services/debug_service.dart';

/// Comprehensive test suite for Task 1.1: Data Validation System
/// 
/// These tests validate that the SharedPreferences data validation
/// implementation correctly identifies corruption patterns and migration blockers.
void main() {
  group('Task 1.1 Validation Tests', () {
    late SharedPreferences mockPrefs;
    late DataValidationService validationService;

    setUp(() async {
      // Initialize mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      validationService = DataValidationService();
    });

    tearDown(() async {
      // Clean up after each test
      await mockPrefs.clear();
    });

    group('DataValidationService - Critical Error Detection', () {
      test('should detect missing categoryId fields as critical errors', () async {
        // Arrange: Create interview questions without categoryId
        final questionsWithoutCategoryId = [
          {
            'id': 'test-1',
            'text': 'Test question without categoryId',
            'category': 'technical',
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
            // Missing categoryId field - should trigger critical error
          },
          {
            'id': 'test-2', 
            'text': 'Another test question',
            'category': 'applied',
            'subtopic': 'Test Topic 2',
            'difficulty': 'mid',
            'answer': 'Test answer 2',
            'categoryId': null, // Null categoryId - should trigger critical error
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithoutCategoryId));

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect critical errors for missing categoryId
        expect(report.criticalErrors.length, greaterThanOrEqualTo(2));
        expect(report.hasBlockingIssues, isTrue);
        expect(report.migrationStatus, contains('BLOCKED'));
        
        // Verify specific error messages
        final categoryIdErrors = report.criticalErrors
            .where((error) => error.message.contains('Missing categoryId field'))
            .toList();
        expect(categoryIdErrors.length, equals(2));
      });

      test('should detect boolean fields stored as strings', () async {
        // Arrange: Create data with string booleans instead of proper booleans
        final questionsWithStringBooleans = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
            'isDraft': 'false', // String instead of boolean
            'isStarred': 'true',  // String instead of boolean
            'isCompleted': 'false', // String instead of boolean
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithStringBooleans));

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect boolean type warnings
        final booleanWarnings = report.warnings
            .where((warning) => warning.message.contains('should be boolean'))
            .toList();
        expect(booleanWarnings.length, greaterThanOrEqualTo(3)); // isDraft, isStarred, isCompleted
      });

      test('should detect invalid difficulty enum values', () async {
        // Arrange: Create questions with invalid difficulty values
        final questionsWithInvalidDifficulty = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test Topic',
            'difficulty': 'invalid_difficulty', // Invalid enum value
            'answer': 'Test answer',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithInvalidDifficulty));

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect invalid difficulty error
        final difficultyErrors = report.errors
            .where((error) => error.message.contains('Invalid difficulty value'))
            .toList();
        expect(difficultyErrors.length, equals(1));
      });

      test('should provide category mapping suggestions', () async {
        // Arrange: Create question without categoryId but with legacy category
        final questionsNeedingSuggestions = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical', // Legacy category
            // Missing categoryId - should get suggestion
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsNeedingSuggestions));

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should provide mapping suggestions
        final suggestions = report.suggestions
            .where((suggestion) => suggestion.message.contains('Suggested categoryId'))
            .toList();
        expect(suggestions.length, equals(1));
        expect(suggestions.first.message, contains('data_analysis')); // Expected mapping for 'technical'
      });
    });

    group('DataValidationService - Flashcard Validation', () {
      test('should validate flashcard set structure', () async {
        // Arrange: Create flashcard sets with structure issues
        final flashcardSetsWithIssues = [
          jsonEncode({
            // Missing 'id' field
            'title': 'Test Set',
            'description': 'Test Description',
            'flashcards': [
              {
                'id': '1',
                'question': 'Test Question',
                'answer': 'Test Answer',
                'isCompleted': false,
              }
            ],
            'isDraft': false,
            'rating': 4.5,
          }),
          jsonEncode({
            'id': 'set-2',
            'title': 'Test Set 2',
            'description': 'Test Description 2',
            'flashcards': 'invalid_structure', // Should be array
            'isDraft': 'false', // Should be boolean
            'rating': 'invalid_rating', // Should be number
          })
        ];

        await mockPrefs.setStringList('flashcard_sets', flashcardSetsWithIssues);

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect flashcard set structure issues
        expect(report.errors.length, greaterThan(0));
        expect(report.warnings.length, greaterThan(0));

        // Check for specific error types
        final structureErrors = report.errors
            .where((error) => error.location.contains('flashcard_sets'))
            .toList();
        expect(structureErrors.length, greaterThan(0));
      });

      test('should detect missing flashcard required fields', () async {
        // Arrange: Create flashcard sets with missing required fields
        final flashcardSetsWithMissingFields = [
          jsonEncode({
            'id': 'set-1',
            'title': 'Test Set',
            'flashcards': [
              {
                // Missing 'id' field
                'question': 'Test Question',
                'answer': 'Test Answer',
              },
              {
                'id': '2',
                // Missing 'question' field
                'answer': 'Test Answer',
              }
            ],
          })
        ];

        await mockPrefs.setStringList('flashcard_sets', flashcardSetsWithMissingFields);

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect missing required field errors
        final missingFieldErrors = report.errors
            .where((error) => error.message.contains('Missing or empty required field'))
            .toList();
        expect(missingFieldErrors.length, greaterThanOrEqualTo(2));
      });
    });

    group('DataValidationService - Error Handling', () {
      test('should handle corrupted JSON gracefully', () async {
        // Arrange: Set corrupted JSON data
        await mockPrefs.setString('interview_questions', 'invalid_json_structure{[}');

        // Act: Run validation (should not throw exception)
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect JSON corruption error
        final jsonErrors = report.errors
            .where((error) => error.message.contains('Invalid JSON structure'))
            .toList();
        expect(jsonErrors.length, equals(1));
      });

      test('should handle empty data gracefully', () async {
        // Arrange: No data in SharedPreferences
        // Act: Run validation on empty data
        final report = await validationService.validateAllStoredData();

        // Assert: Should report warnings for missing data, not errors
        expect(report.warnings.length, greaterThan(0));
        expect(report.errors.length, equals(0));
        expect(report.criticalErrors.length, equals(0));
      });

      test('should handle validation system errors gracefully', () async {
        // Arrange: Create a scenario that might cause internal errors
        await mockPrefs.setString('interview_questions', '[]'); // Empty array
        await mockPrefs.setStringList('flashcard_sets', []); // Empty list

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should complete without throwing exceptions
        expect(report, isNotNull);
        expect(report.migrationStatus, isNotNull);
      });
    });

    group('DataValidationService - Migration Readiness', () {
      test('should report ready status when no blocking issues', () async {
        // Arrange: Create valid data with no issues
        final validQuestions = [
          {
            'id': 'test-1',
            'text': 'Valid test question',
            'category': 'technical',
            'categoryId': 'data_analysis', // Present and valid
            'subtopic': 'Test Topic',
            'difficulty': 'entry', // Valid enum value
            'answer': 'Test answer',
            'isDraft': false, // Proper boolean
            'isStarred': false, // Proper boolean  
            'isCompleted': false, // Proper boolean
          }
        ];

        final validFlashcardSets = [
          jsonEncode({
            'id': 'set-1',
            'title': 'Valid Test Set',
            'description': 'Test Description',
            'flashcards': [
              {
                'id': '1',
                'question': 'Test Question',
                'answer': 'Test Answer',
                'isCompleted': false,
              }
            ],
            'isDraft': false,
            'rating': 4.5,
          })
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(validQuestions));
        await mockPrefs.setStringList('flashcard_sets', validFlashcardSets);

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should report ready status
        expect(report.hasBlockingIssues, isFalse);
        expect(report.hasCriticalIssues, isFalse);
        expect(report.migrationStatus, equals('READY'));
      });

      test('should estimate fix time based on issue count', () async {
        // Arrange: Create data with known issues
        final questionsWithIssues = [
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - critical error (estimated 2 days)
            'subtopic': 'Test Topic',
            'difficulty': 'invalid', // Invalid enum - error (estimated 1 day)
            'answer': 'Test answer',
            'isDraft': 'false', // String boolean - warning (estimated 0.2 days)
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithIssues));

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should estimate reasonable fix time
        final estimatedDays = report.toJson()['estimated_fix_days'] as int;
        expect(estimatedDays, greaterThan(0));
        expect(estimatedDays, lessThanOrEqualTo(14)); // Should be reasonable
      });
    });

    group('DebugService Tests', () {
      test('should provide migration readiness check', () async {
        // Arrange: Create valid data
        final validQuestions = [
          {
            'id': 'test-1',
            'text': 'Valid question',
            'category': 'technical',
            'categoryId': 'data_analysis',
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(validQuestions));

        // Act: Check migration readiness
        final isReady = await DebugService.isReadyForMigration();

        // Assert: Should return true for valid data
        expect(isReady, isTrue);
      });

      test('should return false for migration readiness with blocking issues', () async {
        // Arrange: Create data with critical errors
        final questionsWithCriticalIssues = [
          {
            'id': 'test-1',
            'text': 'Question with issues',
            'category': 'technical',
            // Missing categoryId - critical blocker
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithCriticalIssues));

        // Act: Check migration readiness
        final isReady = await DebugService.isReadyForMigration();

        // Assert: Should return false for blocking issues
        expect(isReady, isFalse);
      });

      test('should provide validation summary', () async {
        // Arrange: Create data with mixed issues
        final questionsWithMixedIssues = [
          {
            'id': 'test-1',
            'text': 'Question with issues',
            'category': 'technical',
            // Missing categoryId - critical
            'subtopic': 'Test Topic',
            'difficulty': 'invalid', // Invalid difficulty - error
            'answer': 'Test answer',
            'isDraft': 'false', // String boolean - warning
          }
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(questionsWithMixedIssues));

        // Act: Get validation summary
        final summary = await DebugService.getValidationSummary();

        // Assert: Should contain status and issue counts
        expect(summary, contains('Status:'));
        expect(summary, contains('Issues:'));
        expect(summary, contains('critical'));
        expect(summary, contains('errors'));
        expect(summary, contains('warnings'));
      });
    });

    group('Integration Tests', () {
      test('should work with realistic data corruption scenario', () async {
        // Arrange: Create realistic corrupted data scenario
        final corruptedQuestions = [
          // Question 1: Missing categoryId (critical)
          {
            'id': 'q1',
            'text': 'What is machine learning?',
            'category': 'technical',
            'subtopic': 'ML Basics',
            'difficulty': 'entry',
            'answer': 'ML is a type of AI...',
            'isDraft': false,
            'isStarred': 'true', // String boolean (warning)
            'isCompleted': false,
          },
          // Question 2: Multiple issues
          {
            'id': 'q2',
            'text': 'Explain neural networks',
            'category': 'applied',
            'categoryId': '', // Empty categoryId (critical)
            'subtopic': 'Deep Learning',
            'difficulty': 'expert', // Invalid difficulty (error)
            'answer': 'Neural networks are...',
            'isDraft': 'false', // String boolean (warning)
            'isStarred': false,
            'isCompleted': 'true', // String boolean (warning)
          },
          // Question 3: Valid question for comparison
          {
            'id': 'q3',
            'text': 'What is Python?',
            'category': 'technical',
            'categoryId': 'python',
            'subtopic': 'Programming',
            'difficulty': 'entry',
            'answer': 'Python is a programming language...',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ];

        final corruptedFlashcardSets = [
          // Set with missing ID
          jsonEncode({
            'title': 'Python Basics',
            'description': 'Learn Python fundamentals',
            'flashcards': [
              {
                'id': '1',
                'question': 'What is a variable?',
                'answer': 'A container for data',
                'isCompleted': 'false', // String boolean
              }
            ],
            'isDraft': false,
            'rating': 'excellent', // Invalid rating type
          }),
          // Valid set for comparison
          jsonEncode({
            'id': 'set-2',
            'title': 'Data Structures',
            'description': 'Learn about data structures',
            'flashcards': [
              {
                'id': '1',
                'question': 'What is an array?',
                'answer': 'A collection of elements',
                'isCompleted': false,
              }
            ],
            'isDraft': false,
            'rating': 4.2,
          })
        ];

        await mockPrefs.setString('interview_questions', jsonEncode(corruptedQuestions));
        await mockPrefs.setStringList('flashcard_sets', corruptedFlashcardSets);

        // Act: Run validation
        final report = await validationService.validateAllStoredData();

        // Assert: Should detect all expected issues
        expect(report.criticalErrors.length, greaterThanOrEqualTo(2)); // Missing categoryId fields
        expect(report.errors.length, greaterThanOrEqualTo(3)); // Invalid difficulty, missing ID, invalid rating
        expect(report.warnings.length, greaterThanOrEqualTo(4)); // String booleans
        expect(report.hasBlockingIssues, isTrue);
        expect(report.migrationStatus, contains('BLOCKED'));

        // Verify specific issue detection
        expect(report.criticalErrors.any((e) => e.message.contains('Missing categoryId field')), isTrue);
        expect(report.errors.any((e) => e.message.contains('Invalid difficulty value')), isTrue);
        expect(report.warnings.any((w) => w.message.contains('should be boolean')), isTrue);
      });
    });
  });
}

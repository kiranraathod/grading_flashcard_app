import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_flashcard_app/screens/data_validation_screen.dart';

/// Widget tests for the DataValidationScreen
/// Tests the UI components and user interactions for Task 1.1
void main() {
  group('DataValidationScreen Widget Tests', () {
    
    setUp(() async {
      // Initialize mock SharedPreferences for widget tests
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display loading indicator when validation is running', (WidgetTester tester) async {
      // Arrange: Create the widget
      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      // Act: Initial pump shows loading state
      await tester.pump();

      // Assert: Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Validating stored data...'), findsOneWidget);
    });

    testWidgets('should display validation results after completion', (WidgetTester tester) async {
      // Arrange: Set up mock data with issues
      SharedPreferences.setMockInitialValues({
        'interview_questions': jsonEncode([
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - critical error
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
          }
        ]),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      // Act: Wait for validation to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Allow async operations
      await tester.pumpAndSettle(); // Wait for all animations

      // Assert: Should show migration status
      expect(find.text('Migration Status:'), findsOneWidget);
      expect(find.text('BLOCKED'), findsOneWidget);
    });

    testWidgets('should show ready status for valid data', (WidgetTester tester) async {
      // Arrange: Set up valid mock data
      SharedPreferences.setMockInitialValues({
        'interview_questions': jsonEncode([
          {
            'id': 'test-1',
            'text': 'Valid test question',
            'category': 'technical',
            'categoryId': 'data_analysis', // Valid categoryId
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
            'isDraft': false,
            'isStarred': false,
            'isCompleted': false,
          }
        ]),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      // Act: Wait for validation to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Should show ready status
      expect(find.textContaining('READY'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display issue counts in summary card', (WidgetTester tester) async {
      // Arrange: Set up data with known issues
      SharedPreferences.setMockInitialValues({
        'interview_questions': jsonEncode([
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - critical error
            'subtopic': 'Test Topic',
            'difficulty': 'invalid', // Invalid difficulty - error
            'answer': 'Test answer',
            'isDraft': 'false', // String boolean - warning
          }
        ]),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      // Act: Wait for validation to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Should display issue count chips
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Errors'), findsOneWidget);
      expect(find.text('Warnings'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
    });

    testWidgets('should allow expanding issue sections', (WidgetTester tester) async {
      // Arrange: Set up data with critical errors
      SharedPreferences.setMockInitialValues({
        'interview_questions': jsonEncode([
          {
            'id': 'test-1',
            'text': 'Test question',
            'category': 'technical',
            // Missing categoryId - should create expandable section
            'subtopic': 'Test Topic',
            'difficulty': 'entry',
            'answer': 'Test answer',
          }
        ]),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      // Act: Wait for validation and find expansion tile
      await tester.pump();
      await tester.pumpAndSettle();

      // Find and tap the critical errors expansion tile
      final criticalErrorsTile = find.byType(ExpansionTile).first;
      expect(criticalErrorsTile, findsOneWidget);
      
      await tester.tap(criticalErrorsTile);
      await tester.pumpAndSettle();

      // Assert: Should show expanded issue details
      expect(find.textContaining('Missing categoryId field'), findsOneWidget);
    });

    testWidgets('should have refresh functionality', (WidgetTester tester) async {
      // Arrange: Create the widget
      await tester.pumpWidget(
        MaterialApp(
          home: const DataValidationScreen(),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Act: Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pump();

      // Assert: Should show loading indicator again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

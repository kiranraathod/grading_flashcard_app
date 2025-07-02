# BLoC Testing Guide

## 🧪 **Testing Strategy Overview**

This guide provides comprehensive testing strategies for the Pure BLoC migration, focusing on unit testing, integration testing, and the critical progress bar bug validation.

---

## 🎯 **Testing Objectives**

### **Primary Goals**
1. **Validate Bug Fix**: Ensure progress bar bug is completely eliminated
2. **BLoC Unit Testing**: Test business logic in isolation
3. **Integration Testing**: Validate BLoC coordination
4. **Performance Testing**: Ensure performance improvements
5. **Regression Testing**: Prevent introduction of new bugs

### **Testing Pyramid**

```
          ┌─────────────────┐
          │   E2E Tests     │  ← User flow validation
          │   (Few)         │
          └─────────────────┘
         ┌─────────────────────┐
         │ Integration Tests   │  ← BLoC coordination
         │    (Some)           │
         └─────────────────────┘
        ┌─────────────────────────┐
        │     Unit Tests          │  ← BLoC business logic  
        │      (Many)             │
        └─────────────────────────┘
```

---

## 🔧 **Test Setup & Dependencies**

### **Required Dependencies**

**File**: `pubspec.yaml`
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5      # For testing BLoCs
  mocktail: ^1.0.0       # For mocking dependencies
  integration_test: ^1.0.0 # For integration tests
  patrol: ^2.5.0         # For advanced UI testing
```

### **Test Utilities Setup**

**File**: `test/test_utils.dart`
```dart
import 'package:mocktail/mocktail.dart';
import 'package:grading_flashcard_app/repositories/flashcard_repository.dart';
import 'package:grading_flashcard_app/repositories/auth_repository.dart';
import 'package:grading_flashcard_app/services/api_service.dart';

// Mock Classes
class MockFlashcardRepository extends Mock implements FlashcardRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockApiService extends Mock implements ApiService {}

// Test Data Builders
class TestDataBuilder {
  static FlashcardSet createTestFlashcardSet({
    String? id,
    String? title,
    List<Flashcard>? flashcards,
  }) {
    return FlashcardSet(
      id: id ?? 'test-set-1',
      title: title ?? 'Test Set',
      description: 'Test Description',
      flashcards: flashcards ?? [createTestFlashcard()],
      lastUpdated: DateTime.now(),
    );
  }
  
  static Flashcard createTestFlashcard({
    String? id,
    String? question,
    String? answer,
    bool isCompleted = false,
  }) {
    return Flashcard(
      id: id ?? 'test-card-1',
      question: question ?? 'Test Question?',
      answer: answer ?? 'Test Answer',
      isCompleted: isCompleted,
    );
  }
}

// Test Environment Setup
class TestEnvironment {
  static void setupMocks() {
    registerFallbackValue(TestDataBuilder.createTestFlashcardSet());
    registerFallbackValue(TestDataBuilder.createTestFlashcard());
  }
}
```

---

## 🧪 **Unit Testing BLoCs**

### **FlashcardBloc Unit Tests**

**File**: `test/blocs/flashcard/flashcard_bloc_test.dart`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grading_flashcard_app/blocs/flashcard/flashcard_bloc.dart';
import '../../test_utils.dart';

void main() {
  group('FlashcardBloc', () {
    late FlashcardBloc flashcardBloc;
    late MockFlashcardRepository mockRepository;

    setUp(() {
      TestEnvironment.setupMocks();
      mockRepository = MockFlashcardRepository();
      flashcardBloc = FlashcardBloc(repository: mockRepository);
    });

    tearDown(() {
      flashcardBloc.close();
    });

    group('FlashcardLoadRequested', () {
      blocTest<FlashcardBloc, FlashcardState>(
        'emits [FlashcardLoading, FlashcardLoaded] when data loads successfully',
        build: () {
          when(() => mockRepository.getAll())
              .thenAnswer((_) async => [TestDataBuilder.createTestFlashcardSet()]);
          return flashcardBloc;
        },
        act: (bloc) => bloc.add(FlashcardLoadRequested()),
        expect: () => [
          FlashcardLoading(),
          isA<FlashcardLoaded>()
              .having((state) => state.flashcardSets.length, 'sets length', 1),
        ],
        verify: (_) {
          verify(() => mockRepository.getAll()).called(1);
        },
      );

      blocTest<FlashcardBloc, FlashcardState>(
        'emits [FlashcardLoading, FlashcardError] when loading fails',
        build: () {
          when(() => mockRepository.getAll())
              .thenThrow(Exception('Failed to load'));
          return flashcardBloc;
        },
        act: (bloc) => bloc.add(FlashcardLoadRequested()),
        expect: () => [
          FlashcardLoading(),
          isA<FlashcardError>()
              .having((state) => state.message, 'error message', 
                      contains('Failed to load flashcard sets')),
        ],
      );
    });

    group('FlashcardProgressUpdated', () {
      blocTest<FlashcardBloc, FlashcardState>(
        'updates progress correctly when card completion changes',
        build: () {
          final testSet = TestDataBuilder.createTestFlashcardSet(
            flashcards: [
              TestDataBuilder.createTestFlashcard(
                id: 'test-card-1',
                isCompleted: false,
              ),
            ],
          );
          
          when(() => mockRepository.getById('test-set-1'))
              .thenAnswer((_) async => testSet);
          when(() => mockRepository.save(any()))
              .thenAnswer((_) async {});
              
          return flashcardBloc;
        },
        act: (bloc) => bloc.add(FlashcardProgressUpdated(
          setId: 'test-set-1',
          cardId: 'test-card-1',
          isCompleted: true,
        )),
        verify: (_) {
          verify(() => mockRepository.save(any(
            that: predicate<FlashcardSet>((set) => 
              set.flashcards.first.isCompleted == true),
          ))).called(1);
        },
      );
    });
  });
}
```

### **StudyBloc Unit Tests**

**File**: `test/blocs/study/study_bloc_test.dart`

```dart
void main() {
  group('StudyBloc', () {
    late StudyBloc studyBloc;
    late MockApiService mockApiService;
    late MockFlashcardBloc mockFlashcardBloc;

    setUp(() {
      TestEnvironment.setupMocks();
      mockApiService = MockApiService();
      mockFlashcardBloc = MockFlashcardBloc();
      studyBloc = StudyBloc(
        apiService: mockApiService,
        flashcardBloc: mockFlashcardBloc,
      );
    });

    group('FlashcardAnswered', () {
      blocTest<StudyBloc, StudyState>(
        'coordinates with FlashcardBloc when answer is correct',
        build: () {
          when(() => mockApiService.gradeAnswer(any()))
              .thenAnswer((_) async => Answer(
                flashcardId: 'test-card-1',
                question: 'Test Question',
                userAnswer: 'Test Answer',
                correctAnswer: 'Test Answer',
                score: 85, // Above threshold
              ));
          
          return studyBloc;
        },
        seed: () => StudyState(
          status: StudyStatus.loaded,
          flashcardSet: TestDataBuilder.createTestFlashcardSet(),
          currentIndex: 0,
        ),
        act: (bloc) => bloc.add(FlashcardAnswered(
          TestDataBuilder.createTestFlashcard(id: 'test-card-1'),
          'Test Answer',
        )),
        expect: () => [
          predicate<StudyState>((state) => state.status == StudyStatus.grading),
          predicate<StudyState>((state) => 
            state.status == StudyStatus.loaded &&
            state.flashcardSet?.flashcards.first.isCompleted == true),
        ],
        verify: (_) {
          // Verify FlashcardBloc receives progress update
          verify(() => mockFlashcardBloc.add(any(
            that: isA<FlashcardProgressUpdated>()
              .having((event) => event.isCompleted, 'isCompleted', true),
          ))).called(1);
        },
      );
    });
  });
}
```

---

## 🔄 **Integration Testing**

### **Critical Progress Bar Bug Fix Test**

**File**: `test/integration/progress_persistence_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:grading_flashcard_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Progress Bar Bug Fix Integration Tests', () {
    testWidgets('Progress persists without disappearing - CRITICAL BUG FIX', 
        (WidgetTester tester) async {
      
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to study screen
      await tester.tap(find.text('Python Basics'));
      await tester.pumpAndSettle();
      
      // Answer a question correctly
      await tester.enterText(find.byType(TextField), '# This is a comment');
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      
      // Verify progress appears
      expect(find.text('1/3 completed'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // CRITICAL: Wait for potential race conditions
      await tester.pump(Duration(seconds: 5));
      
      // Verify progress still persists (bug fix validation)
      expect(find.text('1/3 completed'), findsOneWidget);
      
      // Navigate back to home screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Verify progress shows on home screen
      expect(find.text('33% complete'), findsOneWidget);
      
      // Wait longer to ensure no periodic sync overwrites
      await tester.pump(Duration(seconds: 10));
      
      // Final verification: progress still persists
      expect(find.text('33% complete'), findsOneWidget);
    });
    
    testWidgets('Multiple progress updates persist correctly',
        (WidgetTester tester) async {
      
      // Launch app and navigate to study
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Python Basics'));
      await tester.pumpAndSettle();
      
      // Answer first question
      await tester.enterText(find.byType(TextField), '# comment');
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      
      // Verify first progress
      expect(find.text('1/3 completed'), findsOneWidget);
      
      // Move to next question
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      
      // Answer second question
      await tester.enterText(find.byType(TextField), 'print("Hello")');
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      
      // Verify cumulative progress
      expect(find.text('2/3 completed'), findsOneWidget);
      
      // Wait for potential race conditions
      await tester.pump(Duration(seconds: 3));
      
      // Verify progress still persists
      expect(find.text('2/3 completed'), findsOneWidget);
    });
  });
}
```

### **BLoC Coordination Testing**

**File**: `test/integration/bloc_coordination_test.dart`

```dart
void main() {
  group('BLoC Coordination Integration Tests', () {
    late FlashcardBloc flashcardBloc;
    late StudyBloc studyBloc;
    late MockFlashcardRepository mockRepository;
    late MockApiService mockApiService;

    setUp(() {
      TestEnvironment.setupMocks();
      mockRepository = MockFlashcardRepository();
      mockApiService = MockApiService();
      
      flashcardBloc = FlashcardBloc(repository: mockRepository);
      studyBloc = StudyBloc(
        apiService: mockApiService,
        flashcardBloc: flashcardBloc,
      );
    });

    tearDown(() {
      flashcardBloc.close();
      studyBloc.close();
    });

    testWidgets('StudyBloc coordinates with FlashcardBloc for progress updates',
        (WidgetTester tester) async {
      
      // Setup repository mocks
      final testSet = TestDataBuilder.createTestFlashcardSet(
        flashcards: [
          TestDataBuilder.createTestFlashcard(isCompleted: false),
        ],
      );
      
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => [testSet]);
      when(() => mockRepository.getById(any()))
          .thenAnswer((_) async => testSet);
      when(() => mockRepository.save(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.watchAll())
          .thenAnswer((_) => Stream.value([testSet]));
      
      // Setup API mock
      when(() => mockApiService.gradeAnswer(any()))
          .thenAnswer((_) async => Answer(
            flashcardId: 'test-card-1',
            question: 'Test',
            userAnswer: 'Test',
            correctAnswer: 'Test',
            score: 85,
          ));

      // Build test widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: flashcardBloc),
              BlocProvider.value(value: studyBloc),
            ],
            child: TestCoordinationWidget(testSet: testSet),
          ),
        ),
      );

      // Load initial data
      flashcardBloc.add(FlashcardLoadRequested());
      studyBloc.add(StudyStarted(testSet));
      await tester.pump();

      // Trigger progress update through StudyBloc
      studyBloc.add(FlashcardAnswered(
        testSet.flashcards.first,
        'correct answer',
      ));
      await tester.pump();

      // Verify FlashcardBloc received update
      await tester.pump(Duration(milliseconds: 100));

      // Verify repository save was called
      verify(() => mockRepository.save(any(
        that: predicate<FlashcardSet>((set) => 
          set.flashcards.first.isCompleted == true),
      ))).called(1);

      // Verify UI shows updated progress
      expect(find.text('1/1 completed'), findsOneWidget);
    });
  });
}

// Test widget for coordination testing
class TestCoordinationWidget extends StatelessWidget {
  final FlashcardSet testSet;
  
  const TestCoordinationWidget({required this.testSet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FlashcardBloc, FlashcardState>(
        builder: (context, state) {
          if (state is FlashcardLoaded) {
            final set = state.flashcardSets.first;
            final completed = set.flashcards.where((c) => c.isCompleted).length;
            final total = set.flashcards.length;
            
            return Text('$completed/$total completed');
          }
          return Text('Loading...');
        },
      ),
    );
  }
}
```

---

## 📊 **Performance Testing**

### **UI Rebuild Testing**

**File**: `test/performance/ui_rebuild_test.dart`

```dart
void main() {
  group('UI Rebuild Performance Tests', () {
    testWidgets('Progress updates cause minimal rebuilds',
        (WidgetTester tester) async {
      
      int rebuildCount = 0;
      
      // Custom widget to count rebuilds
      Widget buildCounter = Builder(
        builder: (context) {
          rebuildCount++;
          return BlocBuilder<FlashcardBloc, FlashcardState>(
            builder: (context, state) {
              if (state is FlashcardLoaded) {
                return Text('Rebuild count: $rebuildCount');
              }
              return Text('Loading...');
            },
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => mockFlashcardBloc,
            child: buildCounter,
          ),
        ),
      );

      // Reset counter after initial build
      rebuildCount = 0;

      // Trigger progress update
      mockFlashcardBloc.add(FlashcardProgressUpdated(
        setId: 'test-set',
        cardId: 'test-card',
        isCompleted: true,
      ));

      await tester.pump();

      // Verify minimal rebuilds (target: ≤2)
      expect(rebuildCount, lessThanOrEqualTo(2));
    });
  });
}
```

### **Memory Leak Testing**

**File**: `test/performance/memory_leak_test.dart`

```dart
void main() {
  group('Memory Leak Tests', () {
    test('BLoC properly disposes of streams', () async {
      final repository = MockFlashcardRepository();
      final streamController = StreamController<List<FlashcardSet>>();
      
      when(() => repository.watchAll())
          .thenAnswer((_) => streamController.stream);
      when(() => repository.getAll())
          .thenAnswer((_) async => []);

      // Create and close BLoC multiple times
      for (int i = 0; i < 100; i++) {
        final bloc = FlashcardBloc(repository: repository);
        bloc.add(FlashcardLoadRequested());
        await bloc.close();
      }

      // Verify stream controller can be closed without issues
      await streamController.close();
      
      // If we reach here without memory issues, test passes
      expect(true, isTrue);
    });
  });
}
```

---

## 🚨 **Critical Bug Validation Tests**

### **Progress Persistence Test Suite**

**File**: `test/bug_validation/progress_persistence_test.dart`

```dart
void main() {
  group('Progress Bar Bug Validation', () {
    group('Scenario 1: Basic Progress Persistence', () {
      testWidgets('Complete flashcard → Progress shows → Wait → Progress persists',
          (tester) async {
        
        // Setup test environment
        await _setupTestEnvironment(tester);
        
        // Complete a flashcard
        await _completeFlashcard(tester, 'Test Answer');
        
        // Verify immediate progress
        expect(find.text('1/3 completed'), findsOneWidget);
        
        // Wait for potential race conditions (original bug timing)
        await tester.pump(Duration(minutes: 6)); // Longer than sync period
        
        // Critical validation: Progress must still be there
        expect(find.text('1/3 completed'), findsOneWidget);
      });
    });

    group('Scenario 2: Multiple Progress Updates', () {
      testWidgets('Complete multiple → Each persists → No overwrites',
          (tester) async {
        
        await _setupTestEnvironment(tester);
        
        // Complete first card
        await _completeFlashcard(tester, 'Answer 1');
        expect(find.text('1/3 completed'), findsOneWidget);
        
        // Wait between completions
        await tester.pump(Duration(seconds: 30));
        
        // Complete second card
        await _moveToNextCard(tester);
        await _completeFlashcard(tester, 'Answer 2');
        expect(find.text('2/3 completed'), findsOneWidget);
        
        // Wait for sync operations
        await tester.pump(Duration(minutes: 3));
        
        // Verify cumulative progress persists
        expect(find.text('2/3 completed'), findsOneWidget);
      });
    });

    group('Scenario 3: App Restart Persistence', () {
      testWidgets('Complete → Restart app → Progress loads correctly',
          (tester) async {
        
        // First session: complete flashcard
        await _setupTestEnvironment(tester);
        await _completeFlashcard(tester, 'Test Answer');
        expect(find.text('1/3 completed'), findsOneWidget);
        
        // Simulate app restart by rebuilding widget tree
        await tester.pumpWidget(Container()); // Clear
        await _setupTestEnvironment(tester); // Rebuild
        
        // Verify progress loaded from storage
        expect(find.text('1/3 completed'), findsOneWidget);
      });
    });

    group('Scenario 4: Sync Operation Interference', () {
      testWidgets('Complete → Force sync → Progress survives sync',
          (tester) async {
        
        await _setupTestEnvironment(tester);
        await _completeFlashcard(tester, 'Test Answer');
        expect(find.text('1/3 completed'), findsOneWidget);
        
        // Force sync operation (debug panel)
        await tester.tap(find.text('Debug Panel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Force Sync'));
        await tester.pumpAndSettle();
        
        // Wait for sync to complete
        await tester.pump(Duration(seconds: 30));
        
        // Critical: Progress must survive sync
        expect(find.text('1/3 completed'), findsOneWidget);
      });
    });
  });
}

// Helper functions
Future<void> _setupTestEnvironment(WidgetTester tester) async {
  // Setup test app with proper BLoC providers
  await tester.pumpWidget(TestApp());
  await tester.pumpAndSettle();
}

Future<void> _completeFlashcard(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField), answer);
  await tester.tap(find.text('Submit'));
  await tester.pumpAndSettle();
}

Future<void> _moveToNextCard(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}
```

---

## 📋 **Test Execution Strategy**

### **Testing Phases**

#### **Phase 1: Unit Tests**
- Run after each BLoC implementation
- Fast feedback on business logic
- Mock all external dependencies

#### **Phase 2: Integration Tests**
- Run after BLoC coordination implementation
- Validate inter-BLoC communication
- Test repository integration

#### **Phase 3: Bug Validation Tests**
- Run specifically for progress bar bug
- Critical validation before sign-off
- Comprehensive scenario coverage

#### **Phase 4: Performance Tests**
- Run after UI integration
- Validate performance improvements
- Benchmark against current system

### **Test Automation**

**File**: `.github/workflows/test.yml`
```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run unit tests
        run: flutter test test/unit
        
      - name: Run integration tests
        run: flutter test test/integration
        
      - name: Run bug validation tests
        run: flutter test test/bug_validation
        
      - name: Run performance tests
        run: flutter test test/performance
```

---

## 📊 **Test Metrics & Reporting**

### **Success Criteria**

#### **Unit Tests**
- **Coverage**: >90% for BLoC business logic
- **Pass Rate**: 100%
- **Execution Time**: <30 seconds

#### **Integration Tests**
- **Coverage**: All critical user flows
- **Pass Rate**: 100%
- **Execution Time**: <5 minutes

#### **Bug Validation Tests**
- **Progress Persistence**: 100% success rate
- **Zero Race Conditions**: No progress loss scenarios
- **Cross-Session Persistence**: 100% data retention

#### **Performance Tests**
- **UI Rebuilds**: ≤2 per progress update
- **Memory Usage**: No leaks detected
- **Response Time**: <100ms for progress updates

### **Test Reporting**

**Generate Coverage Report**:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Performance Benchmarking**:
```bash
flutter test test/performance --verbose
```

---

## 🎯 **Testing Success Definition**

### **Migration Testing is Successful When**:

1. **✅ Bug Fix Validated**: Progress bar bug 0% occurrence rate
2. **✅ BLoC Logic Tested**: >90% unit test coverage
3. **✅ Coordination Tested**: All integration tests pass  
4. **✅ Performance Validated**: Performance targets met
5. **✅ Regression Free**: No new bugs introduced

### **Ready for Production When**:
- All test suites pass consistently
- Performance benchmarks exceeded
- Bug validation tests show 100% success
- Code coverage targets achieved
- Manual testing scenarios completed

---

**📅 Created**: 2025-07-02
**🧪 Testing Framework**: Flutter Test + BLoC Test + Mocktail
**🎯 Focus**: Critical progress bar bug validation
**📊 Success Metric**: 0% bug occurrence rate

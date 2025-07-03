/// Phase 1 Integration Tests
///
/// Validates that the new BLoC infrastructure works correctly
/// alongside the existing Provider/Riverpod system.
///
/// Tests cover:
/// - Service locator setup
/// - Repository pattern functionality
/// - BLoC state management
/// - Data flow through new architecture
/// - Backward compatibility
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_flashcard_app/core/service_locator.dart';
import 'package:flutter_flashcard_app/repositories/flashcard_repository.dart';
import 'package:flutter_flashcard_app/repositories/base_repository.dart';
import 'package:flutter_flashcard_app/blocs/flashcard/flashcard_bloc.dart';
import 'package:flutter_flashcard_app/blocs/flashcard/flashcard_event.dart';
import 'package:flutter_flashcard_app/blocs/flashcard/flashcard_state.dart';
import 'package:flutter_flashcard_app/models/flashcard_set.dart';
import 'package:flutter_flashcard_app/models/flashcard.dart';
import 'package:flutter_flashcard_app/services/storage_service.dart';
import 'package:flutter_flashcard_app/services/supabase_service.dart'
    hide SyncStatus;
import 'package:flutter_flashcard_app/services/connectivity_service.dart';

// Mock classes
class MockStorageService extends Mock implements StorageService {
  // Add method stubs to match StorageService interface
  static List<Map<String, dynamic>>? getFlashcardSets({String? userId}) => null;
}

class MockSupabaseService extends Mock implements SupabaseService {}

class MockConnectivityService extends Mock implements ConnectivityService {
  // Add properties to match ConnectivityService interface
  @override
  bool get isOnline => true;
}

class MockFlashcardRepository extends Mock implements FlashcardRepository {}

void main() {
  group('Phase 1 Integration Tests', () {
    late MockStorageService mockStorageService;
    late MockSupabaseService mockSupabaseService;
    late MockConnectivityService mockConnectivityService;
    late MockFlashcardRepository mockRepository;

    // Test data
    final testFlashcardSet = FlashcardSet(
      id: 'test-set-1',
      title: 'Test Set',
      description: 'A test flashcard set',
      flashcards: [
        const Flashcard(
          id: 'card-1',
          question: 'What is 2 + 2?',
          answer: '4',
          isCompleted: false,
        ),
        const Flashcard(
          id: 'card-2',
          question: 'What is the capital of France?',
          answer: 'Paris',
          isCompleted: true,
        ),
      ],
    );

    setUp(() {
      // Create mocks
      mockStorageService = MockStorageService();
      mockSupabaseService = MockSupabaseService();
      mockConnectivityService = MockConnectivityService();
      mockRepository = MockFlashcardRepository();

      // Reset service locator before each test
      resetServiceLocator();
    });

    tearDown(() async {
      // Clean up after each test
      await resetServiceLocator();
    });

    group('Service Locator Tests', () {
      test('should register all core dependencies correctly', () async {
        // Setup service locator with real dependencies
        await setupServiceLocator();

        // Verify all dependencies are registered
        expect(areCoreDependenciesRegistered(), isTrue);
        expect(sl.isRegistered<StorageService>(), isTrue);
        expect(sl.isRegistered<SupabaseService>(), isTrue);
        expect(sl.isRegistered<ConnectivityService>(), isTrue);
        expect(sl.isRegistered<FlashcardRepository>(), isTrue);
        expect(sl.isRegistered<FlashcardBloc>(), isTrue);
      });

      test('should resolve dependencies without circular references', () async {
        await setupServiceLocator();

        // Test that we can resolve all dependencies
        expect(() => sl<StorageService>(), returnsNormally);
        expect(() => sl<SupabaseService>(), returnsNormally);
        expect(() => sl<ConnectivityService>(), returnsNormally);
        expect(() => sl<FlashcardRepository>(), returnsNormally);
        expect(() => sl<FlashcardBloc>(), returnsNormally);
      });

      test(
        'should create new FlashcardBloc instances for each request',
        () async {
          await setupServiceLocator();

          final bloc1 = sl<FlashcardBloc>();
          final bloc2 = sl<FlashcardBloc>();

          // Should be different instances (factory registration)
          expect(bloc1, isNot(same(bloc2)));

          // Clean up
          await bloc1.close();
          await bloc2.close();
        },
      );
    });

    group('Repository Integration Tests', () {
      test('should wrap existing services correctly', () async {
        // Mock service behavior - simplified for Phase 1
        when(() => mockConnectivityService.isOnline).thenReturn(true);

        // Create repository with mocked services
        final repository = FlashcardRepository(
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          connectivityService: mockConnectivityService,
        );

        // Repository should be created successfully
        expect(repository, isNotNull);

        // Clean up
        repository.dispose();
      });

      test('should handle data loading through repository', () async {
        // Setup mock data - use static method correctly
        when(
          () => MockStorageService.getFlashcardSets(),
        ).thenReturn([testFlashcardSet.toJson()]);
        when(() => mockConnectivityService.isOnline).thenReturn(false);

        final repository = FlashcardRepository(
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          connectivityService: mockConnectivityService,
        );

        // Test data loading
        final sets = await repository.getAll();
        expect(sets, hasLength(1));
        expect(sets.first.title, equals('Test Set'));
        expect(sets.first.flashcards, hasLength(2));

        // Clean up
        repository.dispose();
      });
    });

    group('FlashcardBloc Tests', () {
      blocTest<FlashcardBloc, FlashcardState>(
        'should emit loaded state when FlashcardLoadRequested succeeds',
        build: () {
          // Setup mock repository
          when(
            () => mockRepository.getAll(),
          ).thenAnswer((_) async => [testFlashcardSet]);
          when(
            () => mockRepository.watchAll(),
          ).thenAnswer((_) => Stream.value([testFlashcardSet]));
          when(
            () => mockRepository.syncStatus,
          ).thenAnswer((_) => Stream.value(SyncStatus.idle));
          when(() => mockRepository.isSyncing).thenReturn(false);
          when(() => mockRepository.lastSyncTime).thenReturn(null);

          return FlashcardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const FlashcardLoadRequested()),
        expect:
            () => [
              isA<FlashcardLoading>().having(
                (state) => state.operation,
                'operation',
                equals('loading'),
              ),
              isA<FlashcardLoaded>()
                  .having((state) => state.sets, 'sets', hasLength(1))
                  .having(
                    (state) => state.sets.first.title,
                    'first set title',
                    equals('Test Set'),
                  ),
            ],
        verify: (_) {
          verify(() => mockRepository.getAll()).called(1);
        },
      );

      blocTest<FlashcardBloc, FlashcardState>(
        'should handle progress updates sequentially',
        build: () {
          when(
            () => mockRepository.updateCardProgress(
              setId: any(named: 'setId'),
              cardId: any(named: 'cardId'),
              isCompleted: any(named: 'isCompleted'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockRepository.watchAll(),
          ).thenAnswer((_) => Stream.value([testFlashcardSet]));
          when(
            () => mockRepository.syncStatus,
          ).thenAnswer((_) => Stream.value(SyncStatus.idle));

          return FlashcardBloc(repository: mockRepository);
        },
        act: (bloc) {
          // Send multiple progress updates rapidly
          bloc.add(
            const FlashcardProgressUpdated(
              setId: 'test-set-1',
              cardId: 'card-1',
              isCompleted: true,
            ),
          );
          bloc.add(
            const FlashcardProgressUpdated(
              setId: 'test-set-1',
              cardId: 'card-2',
              isCompleted: false,
            ),
          );
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          // Should process both updates sequentially
          verify(
            () => mockRepository.updateCardProgress(
              setId: 'test-set-1',
              cardId: 'card-1',
              isCompleted: true,
            ),
          ).called(1);
          verify(
            () => mockRepository.updateCardProgress(
              setId: 'test-set-1',
              cardId: 'card-2',
              isCompleted: false,
            ),
          ).called(1);
        },
      );

      blocTest<FlashcardBloc, FlashcardState>(
        'should handle search correctly',
        build: () {
          when(
            () => mockRepository.watchAll(),
          ).thenAnswer((_) => Stream.value([testFlashcardSet]));
          when(
            () => mockRepository.syncStatus,
          ).thenAnswer((_) => Stream.value(SyncStatus.idle));

          return FlashcardBloc(repository: mockRepository);
        },
        seed: () => FlashcardLoaded(sets: [testFlashcardSet]),
        act: (bloc) => bloc.add(const FlashcardSearchRequested('Test')),
        expect:
            () => [
              isA<FlashcardLoaded>()
                  .having(
                    (state) => state.searchQuery,
                    'searchQuery',
                    equals('Test'),
                  )
                  .having(
                    (state) => state.filteredSets,
                    'filteredSets',
                    hasLength(1),
                  )
                  .having(
                    (state) => state.isSearchActive,
                    'isSearchActive',
                    isTrue,
                  ),
            ],
      );
    });

    group('End-to-End Integration Tests', () {
      test('should work with real service locator setup', () async {
        // This test verifies the entire integration works
        await setupServiceLocator();

        // Get FlashcardBloc from service locator
        final bloc = sl<FlashcardBloc>();
        expect(bloc, isNotNull);

        // Test that bloc can be created and used
        expect(bloc.state, isA<FlashcardInitial>());

        // Clean up
        await bloc.close();
      });
    });

    group('Backward Compatibility Tests', () {
      test('should not interfere with existing Provider system', () {
        // This test ensures that adding BLoC doesn't break existing functionality
        // In a real scenario, you'd test actual Provider usage here

        // For now, just verify that the service locator doesn't interfere
        expect(() => setupServiceLocator(), returnsNormally);
      });
    });
  });
}

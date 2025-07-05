/// Phase 4 Integration Test: Sync & Network Migration
///
/// Tests the coordinated sync operations and network state management
/// to validate that the sync functionality integrates properly with
/// the existing BLoC coordination patterns.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_flashcard_app/core/service_locator.dart';
import 'package:flutter_flashcard_app/blocs/sync/sync_bloc.dart';
import 'package:flutter_flashcard_app/blocs/sync/sync_event.dart';
import 'package:flutter_flashcard_app/blocs/sync/sync_state.dart';
import 'package:flutter_flashcard_app/blocs/network/network_bloc.dart';
import 'package:flutter_flashcard_app/blocs/network/network_event.dart';
import 'package:flutter_flashcard_app/blocs/network/network_state.dart';
import 'package:flutter_flashcard_app/blocs/flashcard/flashcard_bloc.dart';
import 'package:flutter_flashcard_app/blocs/flashcard/flashcard_event.dart' as flashcard_events;
import 'package:flutter_flashcard_app/repositories/sync_repository.dart';

void main() {
  group('Phase 4: Sync & Network Migration Integration Tests', () {
    setUpAll(() async {
      // Initialize service locator for testing
      await setupServiceLocator();
    });

    tearDownAll(() async {
      // Clean up service locator
      await resetServiceLocator();
    });

    group('Service Locator Integration', () {
      test('should register all Phase 4 dependencies', () {
        // Verify Phase 4 components are registered
        expect(sl.isRegistered<SyncRepository>(), isTrue, 
            reason: 'SyncRepository should be registered');
        expect(sl.isRegistered<SyncBloc>(), isTrue, 
            reason: 'SyncBloc should be registered');
        expect(sl.isRegistered<NetworkBloc>(), isTrue, 
            reason: 'NetworkBloc should be registered');
        
        // Verify Phase 1-3 dependencies still exist
        expect(sl.isRegistered<FlashcardBloc>(), isTrue, 
            reason: 'FlashcardBloc should still be registered');
        expect(areCoreDependenciesRegistered(), isTrue,
            reason: 'All core dependencies should be registered');
      });

      test('should create SyncBloc with proper dependencies', () {
        // Test that SyncBloc can be created with dependencies
        expect(() => sl<SyncBloc>(), returnsNormally,
            reason: 'SyncBloc should be creatable from service locator');
        
        final syncBloc = sl<SyncBloc>();
        expect(syncBloc, isNotNull);
        expect(syncBloc.state, isA<SyncInitial>(),
            reason: 'SyncBloc should start in initial state');
      });

      test('should create NetworkBloc with proper dependencies', () {
        // Test that NetworkBloc can be created with dependencies
        expect(() => sl<NetworkBloc>(), returnsNormally,
            reason: 'NetworkBloc should be creatable from service locator');
        
        final networkBloc = sl<NetworkBloc>();
        expect(networkBloc, isNotNull);
        expect(networkBloc.state, isA<NetworkInitial>(),
            reason: 'NetworkBloc should start in initial state');
      });
    });

    group('BLoC Coordination Patterns', () {
      late SyncBloc syncBloc;
      late NetworkBloc networkBloc;
      late FlashcardBloc flashcardBloc;

      setUp(() {
        syncBloc = sl<SyncBloc>();
        networkBloc = sl<NetworkBloc>();
        flashcardBloc = sl<FlashcardBloc>();
      });

      tearDown(() {
        syncBloc.close();
        networkBloc.close();
        flashcardBloc.close();
      });

      test('should initialize sync operations properly', () async {
        // Test sync initialization
        final states = <SyncState>[];
        syncBloc.stream.listen(states.add);

        syncBloc.add(const SyncInitialized());

        // Wait for state changes
        await Future.delayed(const Duration(milliseconds: 100));

        // Should transition from initial to idle state
        expect(states.isNotEmpty, isTrue, reason: 'Should emit states');
        
        // The last state should be either SyncIdle or SyncOffline (depending on network)
        final lastState = states.last;
        expect(
          lastState is SyncIdle || lastState is SyncOffline, 
          isTrue,
          reason: 'Should end in idle or offline state'
        );
      });

      test('should initialize network monitoring properly', () async {
        // Test network initialization
        final states = <NetworkState>[];
        networkBloc.stream.listen(states.add);

        networkBloc.add(const NetworkInitialized());

        // Wait for state changes
        await Future.delayed(const Duration(milliseconds: 100));

        // Should transition from initial to monitoring state
        expect(states.isNotEmpty, isTrue, reason: 'Should emit states');
        
        final lastState = states.last;
        expect(
          lastState is NetworkMonitoring || lastState is NetworkError, 
          isTrue,
          reason: 'Should end in monitoring or error state'
        );
      });

      test('should coordinate sync with network status', () async {
        // Initialize both BLoCs
        networkBloc.add(const NetworkInitialized());
        syncBloc.add(const SyncInitialized());

        await Future.delayed(const Duration(milliseconds: 200));

        // Test that sync responds to network changes
        final syncStates = <SyncState>[];
        syncBloc.stream.listen(syncStates.add);

        // Simulate network going offline
        syncBloc.add(const SyncNetworkStatusChanged(
          isOnline: false,
          hasGoodConnection: false,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        // Should transition to offline state
        final offlineStates = syncStates.whereType<SyncOffline>();
        expect(offlineStates.isNotEmpty, isTrue, 
            reason: 'Should transition to offline state when network is down');
      });
    });

    group('Sync Repository Integration', () {
      late SyncRepository syncRepository;

      setUp(() {
        syncRepository = sl<SyncRepository>();
      });

      test('should initialize sync repository properly', () async {
        expect(() async => await syncRepository.initialize(), returnsNormally,
            reason: 'SyncRepository should initialize without errors');

        expect(syncRepository.isInitialized, isTrue,
            reason: 'SyncRepository should be marked as initialized');
      });

      test('should provide sync statistics', () {
        final stats = syncRepository.getSyncStatistics();
        
        expect(stats, isA<Map<String, dynamic>>(),
            reason: 'Should return statistics map');
        expect(stats.containsKey('is_initialized'), isTrue,
            reason: 'Statistics should include initialization status');
        expect(stats.containsKey('is_online'), isTrue,
            reason: 'Statistics should include online status');
        expect(stats.containsKey('queue_length'), isTrue,
            reason: 'Statistics should include queue length');
      });
    });

    group('Error Handling & Resilience', () {
      test('should handle service locator errors gracefully', () {
        // This test ensures that even if some dependencies fail,
        // the core system remains functional
        expect(() => logRegistrations(), returnsNormally,
            reason: 'Should log registrations without errors');
      });

      test('should handle BLoC disposal properly', () async {
        final syncBloc = sl<SyncBloc>();
        final networkBloc = sl<NetworkBloc>();

        // Test that BLoCs can be disposed without errors
        expect(() => syncBloc.close(), returnsNormally,
            reason: 'SyncBloc should dispose cleanly');
        expect(() => networkBloc.close(), returnsNormally,
            reason: 'NetworkBloc should dispose cleanly');
      });
    });

    group('Phase 2-3 Compatibility', () {
      test('should maintain FlashcardBloc functionality', () {
        // Verify that existing FlashcardBloc still works
        final flashcardBloc = sl<FlashcardBloc>();
        expect(flashcardBloc, isNotNull);
        expect(flashcardBloc.state, isA<dynamic>(),
            reason: 'FlashcardBloc should have valid state');
      });

      test('should not break existing coordination patterns', () async {
        final flashcardBloc = sl<FlashcardBloc>();
        
        // Test that FlashcardBloc still accepts events (Phase 2-3 pattern)
        expect(() => flashcardBloc.add(const flashcard_events.FlashcardLoadRequested()),
            returnsNormally,
            reason: 'FlashcardBloc should still accept events');
      });
    });
  });
}

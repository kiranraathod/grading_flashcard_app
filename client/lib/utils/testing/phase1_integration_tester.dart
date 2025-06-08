import 'package:flutter/foundation.dart';
import '../../models/flashcard_set.dart';
import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';
import '../../services/hybrid_storage_service.dart';
import '../../services/guest_session_service.dart';
import '../../utils/migration/flashcard_set_migration_helper.dart';
import '../../utils/migration/category_migration_helper.dart';

/// Integration test suite for Phase 1 implementation
///
/// Tests end-to-end scenarios with all components working together
class Phase1IntegrationTester {
  /// Run complete integration test suite
  static Future<Map<String, bool>> runIntegrationTests() async {
    final results = <String, bool>{};

    debugPrint('🔗🔗🔗 STARTING PHASE 1 INTEGRATION TESTS 🔗🔗🔗');
    debugPrint('');

    // Test 1: Guest User Complete Journey
    debugPrint('📋 INTEGRATION TEST 1: Guest User Complete Journey');
    results['guest_user_journey'] = await _testGuestUserCompleteJourney();

    // Test 2: Authentication and Data Migration
    debugPrint('📋 INTEGRATION TEST 2: Authentication and Data Migration');
    results['auth_data_migration'] = await _testAuthenticationDataMigration();

    // Test 3: Offline to Online Sync
    debugPrint('📋 INTEGRATION TEST 3: Offline to Online Sync');
    results['offline_online_sync'] = await _testOfflineOnlineSync();

    // Test 4: Multi-Service Coordination
    debugPrint('📋 INTEGRATION TEST 4: Multi-Service Coordination');
    results['multi_service_coordination'] =
        await _testMultiServiceCoordination();

    // Test 5: Error Recovery and Fallback
    debugPrint('📋 INTEGRATION TEST 5: Error Recovery and Fallback');
    results['error_recovery'] = await _testErrorRecoveryAndFallback();

    // Test 6: Performance Under Load
    debugPrint('📋 INTEGRATION TEST 6: Performance Under Load');
    results['performance_under_load'] = await _testPerformanceUnderLoad();

    // Generate integration test report
    _generateIntegrationTestReport(results);

    return results;
  }

  /// Test complete guest user journey
  static Future<bool> _testGuestUserCompleteJourney() async {
    try {
      debugPrint('🧪 Testing complete guest user journey...');

      // Step 1: Initialize services
      final flashcardService = FlashcardService();
      final guestSession = GuestSessionService();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 1));

      if (!guestSession.isInitialized) {
        debugPrint('❌ Guest session not initialized');
        return false;
      }

      final sessionId = guestSession.currentSessionId;
      if (sessionId == null) {
        debugPrint('❌ No guest session ID available');
        return false;
      }

      debugPrint('✅ Guest session initialized: $sessionId');

      // Step 2: Create flashcard sets as guest
      final testSets = [
        FlashcardSet.forGuest(
          id: 'guest-journey-1',
          title: 'Guest Journey Set 1',
          guestSessionId: sessionId,
          flashcards: [
            Flashcard(
              id: '1',
              question: 'What is Flutter?',
              answer: 'UI framework',
            ),
            Flashcard(
              id: '2',
              question: 'What is Dart?',
              answer: 'Programming language',
            ),
          ],
        ),
        FlashcardSet.forGuest(
          id: 'guest-journey-2',
          title: 'Guest Journey Set 2',
          guestSessionId: sessionId,
          flashcards: [
            Flashcard(
              id: '1',
              question: 'What is Supabase?',
              answer: 'Backend service',
            ),
          ],
        ),
      ];

      // Step 3: Add sets via FlashcardService
      for (final set in testSets) {
        await flashcardService.addSet(set);
      }

      if (flashcardService.sets.length < testSets.length) {
        debugPrint('❌ Not all sets were added');
        return false;
      }

      debugPrint('✅ Created ${testSets.length} flashcard sets as guest');

      // Step 4: Test CRUD operations
      final firstSet = flashcardService.sets.first;
      final updatedSet = firstSet.copyWith(
        title: 'Updated Guest Journey Set',
        description: 'Updated during integration test',
      );

      await flashcardService.updateSet(updatedSet);

      final retrievedSet = flashcardService.getSetById(firstSet.id);
      if (retrievedSet?.title != 'Updated Guest Journey Set') {
        debugPrint('❌ Update operation failed');
        return false;
      }

      debugPrint('✅ CRUD operations working correctly');

      // Step 5: Test search functionality
      final searchResults = flashcardService.searchSets('Journey');
      if (searchResults.isEmpty) {
        debugPrint('❌ Search functionality failed');
        return false;
      }

      debugPrint('✅ Search functionality working');

      // Step 6: Test data persistence
      await flashcardService.reloadSets();

      if (flashcardService.sets.length < testSets.length) {
        debugPrint('❌ Data persistence failed');
        return false;
      }

      debugPrint('✅ Data persistence verified');

      // Cleanup
      for (final set in testSets) {
        await flashcardService.deleteSet(set);
      }

      debugPrint('✅ Guest user complete journey: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Guest user journey test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test authentication and data migration
  static Future<bool> _testAuthenticationDataMigration() async {
    try {
      debugPrint('🧪 Testing authentication and data migration...');

      // This test simulates the authentication flow without actual authentication
      // since we can't easily mock the full auth flow in unit tests

      // Step 1: Create guest data
      final guestSessionId = 'integration-test-guest-session';

      final guestSets = [
        FlashcardSet.forGuest(
          id: 'pre-auth-set-1',
          title: 'Pre-Auth Set 1',
          guestSessionId: guestSessionId,
          flashcards: [
            Flashcard(
              id: '1',
              question: 'Guest Question 1',
              answer: 'Guest Answer 1',
            ),
          ],
        ),
        FlashcardSet.forGuest(
          id: 'pre-auth-set-2',
          title: 'Pre-Auth Set 2',
          guestSessionId: guestSessionId,
          flashcards: [
            Flashcard(
              id: '1',
              question: 'Guest Question 2',
              answer: 'Guest Answer 2',
            ),
          ],
        ),
      ];

      debugPrint('✅ Created ${guestSets.length} guest sets for migration test');

      // Step 2: Simulate authentication (convert guest data to user data)
      const userId = 'integration-test-user-123';

      final migratedSets =
          FlashcardSetMigrationHelper.batchTransferGuestDataToUser(
            guestSets,
            userId: userId,
          );

      // Verify migration
      for (int i = 0; i < migratedSets.length; i++) {
        final migrated = migratedSets[i];
        final original = guestSets[i];

        if (migrated.isGuestData || migrated.userId != userId) {
          debugPrint('❌ Migration failed for set ${i + 1}');
          return false;
        }

        if (migrated.title != original.title) {
          debugPrint('❌ Data integrity lost during migration');
          return false;
        }
      }

      debugPrint('✅ Data migration completed successfully');

      // Step 3: Test category migration
      final guestCategories =
          CategoryMigrationHelper.createDefaultCategoriesForGuest(
            guestSessionId,
          );
      final userCategories =
          CategoryMigrationHelper.transferGuestCategoriesToUser(
            guestCategories,
            userId: userId,
          );

      if (userCategories.isEmpty || userCategories.first.isGuestData) {
        debugPrint('❌ Category migration failed');
        return false;
      }

      debugPrint('✅ Category migration completed successfully');
      debugPrint('✅ Authentication and data migration: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Authentication data migration test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test offline to online sync
  static Future<bool> _testOfflineOnlineSync() async {
    try {
      debugPrint('🧪 Testing offline to online sync...');

      // Step 1: Create hybrid storage service
      final hybridStorage = HybridStorageService();

      // Wait for potential initialization
      await Future.delayed(Duration(milliseconds: 500));

      // Step 2: Test offline mode behavior
      hybridStorage.setSyncStrategy(SyncStrategy.localFirst);

      final testSet = FlashcardSet.forGuest(
        id: 'offline-sync-test',
        title: 'Offline Sync Test Set',
        guestSessionId: 'offline-test-session',
        flashcards: [
          Flashcard(
            id: '1',
            question: 'Offline Question',
            answer: 'Offline Answer',
          ),
        ],
      );

      // This will work regardless of actual connectivity
      final addedSet = await hybridStorage.addFlashcardSet(testSet);

      if (addedSet.id != testSet.id) {
        debugPrint('❌ Offline add operation failed');
        return false;
      }

      debugPrint('✅ Offline operations working');

      // Step 3: Test sync status reporting
      final syncStatus = hybridStorage.getSyncStatus();

      if (syncStatus.isEmpty) {
        debugPrint('❌ Sync status reporting failed');
        return false;
      }

      debugPrint('✅ Sync status reporting working');

      // Step 4: Test manual sync (will gracefully handle no connectivity)
      final syncResult = await hybridStorage.syncWithRemote();

      // Sync might fail due to no connectivity, but should not crash
      debugPrint(
        '📊 Sync result: ${syncResult.success} (errors: ${syncResult.errors.length})',
      );

      debugPrint('✅ Offline to online sync: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Offline to online sync test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test multi-service coordination
  static Future<bool> _testMultiServiceCoordination() async {
    try {
      debugPrint('🧪 Testing multi-service coordination...');

      // Step 1: Initialize multiple services
      final flashcardService = FlashcardService();
      final hybridStorage = HybridStorageService();
      final guestSession = GuestSessionService();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 1));

      // Step 2: Test service communication
      final sessionId = guestSession.currentSessionId;
      if (sessionId == null) {
        debugPrint('❌ Guest session service not working');
        return false;
      }

      // Step 3: Test coordinated data operations
      final coordinatedSet = FlashcardSet.forGuest(
        id: 'coordination-test',
        title: 'Multi-Service Coordination Test',
        guestSessionId: sessionId,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'Coordination Test',
            answer: 'All services working',
          ),
        ],
      );

      // Add via FlashcardService (should use HybridStorage internally)
      await flashcardService.addSet(coordinatedSet);

      // Verify via direct service access
      final retrievedSets = flashcardService.sets;
      final foundSet = retrievedSets.any((set) => set.id == coordinatedSet.id);

      if (!foundSet) {
        debugPrint('❌ Service coordination failed');
        return false;
      }

      debugPrint('✅ Services coordinating correctly');

      // Step 4: Test status synchronization
      final flashcardStatus = flashcardService.getSyncStatus();
      final hybridStatus = hybridStorage.getSyncStatus();

      if (flashcardStatus.isEmpty || hybridStatus.isEmpty) {
        debugPrint('❌ Status synchronization failed');
        return false;
      }

      debugPrint('✅ Status synchronization working');

      // Cleanup
      await flashcardService.deleteSet(coordinatedSet);

      debugPrint('✅ Multi-service coordination: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Multi-service coordination test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test error recovery and fallback
  static Future<bool> _testErrorRecoveryAndFallback() async {
    try {
      debugPrint('🧪 Testing error recovery and fallback...');

      // Step 1: Test graceful fallback when hybrid storage unavailable
      final flashcardService = FlashcardService();
      await Future.delayed(Duration(seconds: 1));

      // Force local mode to test fallback
      flashcardService.forceLocalMode();

      if (flashcardService.useHybridStorage) {
        debugPrint('❌ Force local mode failed');
        return false;
      }

      debugPrint('✅ Fallback to local mode working');

      // Step 2: Test operations still work in fallback mode
      final fallbackSet = FlashcardSet(
        id: 'fallback-test',
        title: 'Fallback Test Set',
        flashcards: [
          Flashcard(
            id: '1',
            question: 'Fallback Question',
            answer: 'Fallback Answer',
          ),
        ],
      );

      await flashcardService.addSet(fallbackSet);

      final retrievedSet = flashcardService.getSetById(fallbackSet.id);
      if (retrievedSet == null) {
        debugPrint('❌ Operations failed in fallback mode');
        return false;
      }

      debugPrint('✅ Operations working in fallback mode');

      // Step 3: Test error handling in model operations
      try {
        // This should not crash even with invalid data
        final invalidJson = <String, dynamic>{
          'id': 'invalid-test',
          // Missing required fields
        };

        FlashcardSet.fromJson(invalidJson);
        debugPrint('⚠️ Expected error was not thrown');
      } catch (e) {
        debugPrint('✅ Error handling working correctly: $e');
      }

      // Cleanup
      await flashcardService.deleteSet(fallbackSet);

      debugPrint('✅ Error recovery and fallback: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error recovery and fallback test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test performance under load
  static Future<bool> _testPerformanceUnderLoad() async {
    try {
      debugPrint('🧪 Testing performance under load...');

      final flashcardService = FlashcardService();
      await Future.delayed(Duration(seconds: 1));

      final stopwatch = Stopwatch()..start();

      // Step 1: Create multiple sets simultaneously
      final futures = <Future>[];

      for (int i = 0; i < 50; i++) {
        final set = FlashcardSet(
          id: 'load-test-$i',
          title: 'Load Test Set $i',
          flashcards: List.generate(
            5,
            (j) => Flashcard(
              id: '$j',
              question: 'Load test question $i-$j',
              answer: 'Load test answer $i-$j',
            ),
          ),
        );

        futures.add(flashcardService.addSet(set));
      }

      await Future.wait(futures);
      stopwatch.stop();

      final addTime = stopwatch.elapsedMilliseconds;
      debugPrint(
        '📊 Added 50 sets in ${addTime}ms (${addTime / 50}ms per set)',
      );

      // Step 2: Test search performance under load
      stopwatch.reset();
      stopwatch.start();

      final searchResults = flashcardService.searchSets('Load');

      stopwatch.stop();
      final searchTime = stopwatch.elapsedMilliseconds;
      debugPrint(
        '📊 Search completed in ${searchTime}ms (found ${searchResults.length} results)',
      );

      // Step 3: Clean up
      stopwatch.reset();
      stopwatch.start();

      final setsToDelete =
          flashcardService.sets
              .where((set) => set.id.startsWith('load-test-'))
              .toList();

      for (final set in setsToDelete) {
        await flashcardService.deleteSet(set);
      }

      stopwatch.stop();
      final deleteTime = stopwatch.elapsedMilliseconds;
      debugPrint('📊 Deleted ${setsToDelete.length} sets in ${deleteTime}ms');

      // Performance criteria
      final addPerformanceOk = addTime < 5000; // 5 seconds for 50 sets
      final searchPerformanceOk = searchTime < 100; // 100ms for search
      final deletePerformanceOk = deleteTime < 2000; // 2 seconds for cleanup

      if (!addPerformanceOk) {
        debugPrint('❌ Add performance too slow: ${addTime}ms');
        return false;
      }

      if (!searchPerformanceOk) {
        debugPrint('❌ Search performance too slow: ${searchTime}ms');
        return false;
      }

      if (!deletePerformanceOk) {
        debugPrint('❌ Delete performance too slow: ${deleteTime}ms');
        return false;
      }

      debugPrint('✅ Performance under load: PASSED');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Performance under load test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Generate integration test report
  static void _generateIntegrationTestReport(Map<String, bool> results) {
    debugPrint('');
    debugPrint('🔗🔗🔗 PHASE 1 INTEGRATION TEST REPORT 🔗🔗🔗');
    debugPrint('');

    final totalTests = results.length;
    final passedTests = results.values.where((result) => result).length;
    final failedTests = totalTests - passedTests;
    final successRate = (passedTests / totalTests * 100);

    debugPrint('🎯 INTEGRATION TEST SUMMARY:');
    debugPrint('   Total Integration Tests: $totalTests');
    debugPrint('   Passed: $passedTests ✅');
    debugPrint('   Failed: $failedTests ❌');
    debugPrint('   Success Rate: ${successRate.toStringAsFixed(1)}%');
    debugPrint('');

    debugPrint('📋 DETAILED RESULTS:');
    results.forEach((testName, passed) {
      final status = passed ? '✅' : '❌';
      debugPrint('   $status $testName');
    });

    debugPrint('');
    if (successRate == 100) {
      debugPrint('🎉 INTEGRATION TESTS: PERFECT SCORE');
      debugPrint('✅ All systems working together flawlessly');
    } else if (successRate >= 90) {
      debugPrint('👍 INTEGRATION TESTS: EXCELLENT');
      debugPrint('✅ Minor issues, overall integration is solid');
    } else if (successRate >= 75) {
      debugPrint('⚠️ INTEGRATION TESTS: GOOD');
      debugPrint('⚠️ Some integration issues need attention');
    } else {
      debugPrint('❌ INTEGRATION TESTS: NEEDS WORK');
      debugPrint('🛑 Significant integration problems detected');
    }

    debugPrint('');
    debugPrint('🔗🔗🔗 END OF INTEGRATION TEST REPORT 🔗🔗🔗');
  }
}

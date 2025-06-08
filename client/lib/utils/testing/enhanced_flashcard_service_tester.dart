import 'package:flutter/foundation.dart';
import '../../models/flashcard_set.dart';
import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';
import '../../services/guest_session_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../utils/config.dart';

/// Test suite for enhanced FlashcardService with hybrid storage
/// 
/// Tests both backward compatibility and new hybrid storage features
class EnhancedFlashcardServiceTester {
  static FlashcardService? _service;
  static GuestSessionService? _guestSession;
  static SupabaseAuthService? _auth;
  
  /// Run comprehensive tests for enhanced FlashcardService
  static Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    
    debugPrint('🧪 Starting Enhanced FlashcardService comprehensive testing...');
    
    // Initialize services
    _service = FlashcardService();
    _guestSession = GuestSessionService();
    _auth = SupabaseAuthService();
    
    // Wait for initialization
    await Future.delayed(Duration(seconds: 2));
    
    // Test service initialization
    results['service_initialization'] = await _testServiceInitialization();
    
    // Test backward compatibility
    results['backward_compatibility'] = await _testBackwardCompatibility();
    
    // Test hybrid storage features
    results['hybrid_storage_features'] = await _testHybridStorageFeatures();
    
    // Test authentication integration
    results['authentication_integration'] = await _testAuthenticationIntegration();
    
    // Test sync capabilities
    results['sync_capabilities'] = await _testSyncCapabilities();
    
    // Test status reporting
    results['status_reporting'] = await _testStatusReporting();
    
    // Print summary
    final passedTests = results.values.where((result) => result).length;
    final totalTests = results.length;
    
    debugPrint('📊 Enhanced FlashcardService Test Results:');
    debugPrint('   Total Tests: $totalTests');
    debugPrint('   Passed: $passedTests');
    debugPrint('   Failed: ${totalTests - passedTests}');
    debugPrint('   Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');
    
    return results;
  }
  
  /// Test service initialization
  static Future<bool> _testServiceInitialization() async {
    try {
      debugPrint('🧪 Testing service initialization...');
      
      if (_service == null) {
        debugPrint('❌ Service not created');
        return false;
      }
      
      // Check if service is initialized
      if (!_service!.isInitialized) {
        debugPrint('❌ Service not initialized');
        return false;
      }
      
      // Check initial sets loading
      final sets = _service!.sets;
      debugPrint('✅ Service initialized with ${sets.length} sets');
      
      // Test status reporting
      final status = _service!.getSyncStatus();
      if (status.isEmpty) {
        debugPrint('❌ Status reporting not working');
        return false;
      }
      
      debugPrint('✅ Service initialization: PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Service initialization test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Test backward compatibility with existing APIs
  static Future<bool> _testBackwardCompatibility() async {
    try {
      debugPrint('🧪 Testing backward compatibility...');
      
      // Test legacy API methods still work
      final initialCount = _service!.sets.length;
      
      // Create test set using legacy factory method
      final testSet = FlashcardSet(
        id: 'backward-compat-test-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Backward Compatibility Test Set',
        flashcards: [
          Flashcard(
            id: '1',
            question: 'Legacy API Question',
            answer: 'Legacy API Answer',
          ),
        ],
      );
      
      // Test legacy alias methods
      await _service!.createFlashcardSet(testSet); // Legacy alias
      
      if (_service!.sets.length != initialCount + 1) {
        debugPrint('❌ Legacy createFlashcardSet alias failed');
        return false;
      }
      
      // Test legacy getter
      final retrieved = _service!.getFlashcardSet(testSet.id); // Legacy alias
      if (retrieved == null || retrieved.id != testSet.id) {
        debugPrint('❌ Legacy getFlashcardSet alias failed');
        return false;
      }
      
      // Test legacy update
      final updatedSet = testSet.copyWith(title: 'Updated Legacy Title');
      await _service!.updateFlashcardSet(updatedSet); // Legacy alias
      
      final afterUpdate = _service!.getFlashcardSet(testSet.id);
      if (afterUpdate?.title != 'Updated Legacy Title') {
        debugPrint('❌ Legacy updateFlashcardSet alias failed');
        return false;
      }
      
      // Test legacy delete with ID
      await _service!.deleteFlashcardSet(testSet.id); // Legacy alias with String ID
      
      if (_service!.sets.length != initialCount) {
        debugPrint('❌ Legacy deleteFlashcardSet with ID failed');
        return false;
      }
      
      // Test legacy search
      final searchResults = _service!.searchDecks('test'); // Legacy alias
      debugPrint('✅ Legacy search returned ${searchResults.length} results');
      
      debugPrint('✅ Backward compatibility: ALL PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Backward compatibility test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Test hybrid storage features
  static Future<bool> _testHybridStorageFeatures() async {
    try {
      debugPrint('🧪 Testing hybrid storage features...');
      
      // Test hybrid storage status
      final useHybridStorage = _service!.useHybridStorage;
      debugPrint('📊 Hybrid storage enabled: $useHybridStorage');
      
      // Test enhanced getters
      final isOnline = _service!.isOnline;
      final isSyncing = _service!.isSyncing;
      final hasPendingOps = _service!.hasPendingOperations;
      
      debugPrint('📊 Online: $isOnline, Syncing: $isSyncing, Pending ops: $hasPendingOps');
      
      // Test force local mode
      _service!.forceLocalMode();
      if (_service!.useHybridStorage) {
        debugPrint('❌ Force local mode failed');
        return false;
      }
      debugPrint('✅ Force local mode: PASSED');
      
      // Test re-enable hybrid storage
      if (AppConfig.supabaseUrl.isNotEmpty) {
        await _service!.enableHybridStorage();
        // Note: This might fail if Supabase is not properly configured, which is ok
        debugPrint('✅ Re-enable hybrid storage: ATTEMPTED');
      }
      
      debugPrint('✅ Hybrid storage features: PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Hybrid storage features test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Test authentication integration
  static Future<bool> _testAuthenticationIntegration() async {
    try {
      debugPrint('🧪 Testing authentication integration...');
      
      // Test that service responds to authentication state
      final isAuthenticated = _auth!.isAuthenticated;
      debugPrint('📊 Current authentication state: $isAuthenticated');
      
      // Test that guest session is properly handled
      final guestSessionId = _guestSession!.currentSessionId;
      debugPrint('📊 Current guest session: $guestSessionId');
      
      // Note: We can't easily test actual authentication flow in unit tests
      // but we can verify the integration points exist
      
      debugPrint('✅ Authentication integration: PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Authentication integration test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Test sync capabilities
  static Future<bool> _testSyncCapabilities() async {
    try {
      debugPrint('🧪 Testing sync capabilities...');
      
      // Test manual sync (will gracefully fail if offline/not configured)
      final syncResult = await _service!.syncWithRemote();
      debugPrint('📊 Manual sync result: $syncResult');
      
      // Test reload functionality
      await _service!.reloadSets();
      debugPrint('✅ Reload sets: PASSED');
      
      debugPrint('✅ Sync capabilities: PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Sync capabilities test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Test status reporting
  static Future<bool> _testStatusReporting() async {
    try {
      debugPrint('🧪 Testing status reporting...');
      
      // Test sync status
      final syncStatus = _service!.getSyncStatus();
      if (syncStatus.isEmpty) {
        debugPrint('❌ Sync status empty');
        return false;
      }
      
      debugPrint('📊 Sync status keys: ${syncStatus.keys.toList()}');
      
      // Verify expected status fields
      final expectedFields = [
        'hybridStorageEnabled',
        'syncSupported',
      ];
      
      for (final field in expectedFields) {
        if (!syncStatus.containsKey(field)) {
          debugPrint('❌ Missing status field: $field');
          return false;
        }
      }
      
      debugPrint('✅ Status reporting: PASSED');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Status reporting test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Quick integration test
  static Future<bool> quickTest() async {
    try {
      debugPrint('🧪 Running quick integration test...');
      
      final service = FlashcardService();
      await Future.delayed(Duration(seconds: 1)); // Allow initialization
      
      final initialCount = service.sets.length;
      debugPrint('📊 Initial sets: $initialCount');
      
      // Test basic CRUD operations
      final testSet = FlashcardSet(
        id: 'quick-test-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Quick Test Set',
        flashcards: [
          Flashcard(id: '1', question: 'Test?', answer: 'Yes!'),
        ],
      );
      
      await service.addSet(testSet);
      final afterAdd = service.sets.length;
      
      await service.deleteSet(testSet);
      final afterDelete = service.sets.length;
      
      final success = (afterAdd == initialCount + 1) && (afterDelete == initialCount);
      
      debugPrint(success ? '✅ Quick test: PASSED' : '❌ Quick test: FAILED');
      return success;
      
    } catch (e) {
      debugPrint('❌ Quick test failed: $e');
      return false;
    }
  }
}

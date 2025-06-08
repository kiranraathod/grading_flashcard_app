import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'hybrid_storage_service.dart';
import 'guest_session_service.dart';
import 'supabase_auth_service.dart';
import 'reliable_operation_service.dart';
import '../utils/config.dart';
import 'dart:async';

class FlashcardService extends ChangeNotifier {
  final List<FlashcardSet> _sets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  final ReliableOperationService _reliableOps = ReliableOperationService();
  
  // ===== PHASE 1 ENHANCEMENT: HYBRID STORAGE INTEGRATION =====
  final HybridStorageService _hybridStorage = HybridStorageService();
  final GuestSessionService _guestSession = GuestSessionService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  
  // Enhanced state tracking
  bool _isInitialized = false;
  bool _useHybridStorage = false;
  DateTime? _lastLoadTime;
  
  // Enhanced getters
  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  bool get isInitialized => _isInitialized;
  bool get useHybridStorage => _useHybridStorage;
  DateTime? get lastLoadTime => _lastLoadTime;
  
  // Hybrid storage delegation getters
  bool get isSyncing => _hybridStorage.isSyncing;
  bool get isOnline => _hybridStorage.isOnline;
  bool get hasPendingOperations => _hybridStorage.hasPendingOperations;
  
  FlashcardService() {
    _initialize();
  }
  
  /// Enhanced initialization with hybrid storage support
  Future<void> _initialize() async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('🚀 Initializing enhanced FlashcardService...');
        
        // Initialize hybrid storage if Supabase is configured
        if (AppConfig.supabaseUrl.isNotEmpty) {
          try {
            await _hybridStorage.initialize();
            _useHybridStorage = true;
            debugPrint('✅ Hybrid storage enabled');
            
            // Listen to authentication changes for data migration
            _auth.addListener(_onAuthenticationChanged);
            
            // Listen to hybrid storage changes
            _hybridStorage.addListener(_onHybridStorageChanged);
            
          } catch (e) {
            debugPrint('⚠️ Hybrid storage initialization failed, using local storage: $e');
            _useHybridStorage = false;
          }
        } else {
          debugPrint('📱 Supabase not configured, using local storage only');
          _useHybridStorage = false;
        }
        
        // Load initial data
        await _loadSets();
        
        _isInitialized = true;
        debugPrint('✅ FlashcardService initialization complete');
      },
      operationName: 'flashcard_service_initialization',
    );
  }

  /// Enhanced load sets with hybrid storage support
  Future<void> _loadSets() async {
    await _reliableOps.withFallback(
      primary: () async {
        if (_useHybridStorage) {
          // Use hybrid storage (local + Supabase)
          debugPrint('📚 Loading flashcard sets via hybrid storage...');
          final hybridSets = await _hybridStorage.loadFlashcardSets();
          
          _sets.clear();
          _sets.addAll(hybridSets);
          _lastLoadTime = DateTime.now();
          
          debugPrint('✅ Loaded ${_sets.length} flashcard sets via hybrid storage');
        } else {
          // Fallback to original local storage method
          debugPrint('📱 Loading flashcard sets via local storage...');
          await _loadSetsFromLocalStorage();
        }
        
        notifyListeners();
      },
      fallback: () async {
        debugPrint('❌ Primary load failed, falling back to local storage');
        await _loadSetsFromLocalStorage();
      },
      operationName: 'load_flashcard_sets_enhanced',
    );
  }
  
  /// Original load method preserved for backward compatibility
  Future<void> _loadSetsFromLocalStorage() async {
    final setsData = StorageService.getFlashcardSets();

    if (setsData != null && setsData.isNotEmpty) {
      _sets.clear();
      for (final data in setsData) {
        _sets.add(FlashcardSet.fromJson(data));
      }
      _lastLoadTime = DateTime.now();
      debugPrint('✅ Loaded ${_sets.length} flashcard sets from local storage');
    } else {
      debugPrint('📭 No saved sets found, loading default data from server...');
      await _loadDefaultData();
    }
    
    notifyListeners();
  }

  /// Load default data with cascading fallback strategy
  Future<void> _loadDefaultData() async {
    await _reliableOps.withFallback(
      primary: () async {
        debugPrint('Loading default flashcard sets from server...');
        final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
        
        _sets.clear();
        _sets.addAll(defaultSets);
        
        debugPrint('Loaded ${defaultSets.length} default flashcard sets from server');
        notifyListeners();
      },
      fallback: () async {
        debugPrint('Server failed, creating minimal fallback data');
        _loadMinimalFallbackData();
      },
      operationName: 'load_default_flashcard_data',
    );
  }

  /// Create minimal fallback data safely
  void _loadMinimalFallbackData() {
    _reliableOps.safelySync(
      operation: () {
        debugPrint('Loading minimal fallback data...');
        _sets.clear();
        _loadMinimalServerFallback();
      },
      operationName: 'load_minimal_fallback_data',
    );
  }

  /// Attempt minimal server fallback with safe offline creation
  Future<void> _loadMinimalServerFallback() async {
    await _reliableOps.withFallback(
      primary: () async {
        debugPrint('Attempting to load minimal server fallback data...');
        final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
        
        if (defaultSets.isNotEmpty) {
          _sets.addAll(defaultSets);
          debugPrint('Loaded ${defaultSets.length} minimal sets from server fallback');
        } else {
          _createOfflineOnlyFallback();
        }
      },
      fallback: () async {
        debugPrint('Server fallback also failed, creating offline-only fallback');
        _createOfflineOnlyFallback();
      },
      operationName: 'load_minimal_server_fallback',
    );
    
    notifyListeners();
  }

  /// Create absolute minimal offline fallback
  void _createOfflineOnlyFallback() {
    _reliableOps.safelySync(
      operation: () {
        _sets.add(
          FlashcardSet(
            id: 'offline-minimal-001',
            title: 'Offline Mode (Limited)',
            description: 'Minimal content available in offline mode',
            isDraft: false,
            rating: 4.0,
            ratingCount: 0,
            flashcards: [
              Flashcard(
                id: '1',
                question: 'Welcome to FlashMaster',
                answer: 'This is a demo flashcard available in offline mode.',
                isCompleted: false,
              ),
            ],
          ),
        );
        debugPrint('Created minimal offline-only fallback set');
      },
      operationName: 'create_offline_fallback',
    );
  }

  /// Enhanced add set with hybrid storage support
  Future<void> addSet(FlashcardSet set) async {
    await _reliableOps.safely(
      operation: () async {
        if (_useHybridStorage) {
          // Use hybrid storage for authenticated/guest user support
          debugPrint('➕ Adding flashcard set via hybrid storage: ${set.title}');
          final addedSet = await _hybridStorage.addFlashcardSet(set);
          
          // Update local cache
          final existingIndex = _sets.indexWhere((s) => s.id == addedSet.id);
          if (existingIndex >= 0) {
            _sets[existingIndex] = addedSet;
          } else {
            _sets.add(addedSet);
          }
        } else {
          // Fallback to original local storage method
          debugPrint('➕ Adding flashcard set via local storage: ${set.title}');
          _sets.add(set);
          await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
        }
        
        notifyListeners();
        debugPrint('✅ Added flashcard set: ${set.title}');
      },
      operationName: 'add_flashcard_set_enhanced',
    );
  }

  /// Enhanced update set with hybrid storage support
  Future<void> updateSet(FlashcardSet updatedSet) async {
    await _reliableOps.safely(
      operation: () async {
        if (_useHybridStorage) {
          // Use hybrid storage for sync support
          debugPrint('✏️ Updating flashcard set via hybrid storage: ${updatedSet.title}');
          final resultSet = await _hybridStorage.updateFlashcardSet(updatedSet);
          
          // Update local cache
          final index = _sets.indexWhere((set) => set.id == updatedSet.id);
          if (index >= 0) {
            _sets[index] = resultSet;
          }
        } else {
          // Fallback to original local storage method
          debugPrint('✏️ Updating flashcard set via local storage: ${updatedSet.title}');
          final index = _sets.indexWhere((set) => set.id == updatedSet.id);
          if (index >= 0) {
            _sets[index] = updatedSet;
            await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
          }
        }
        
        notifyListeners();
        debugPrint('✅ Updated flashcard set: ${updatedSet.title}');
      },
      operationName: 'update_flashcard_set_enhanced',
    );
  }

  /// Enhanced delete set with hybrid storage support
  Future<void> deleteSet(FlashcardSet set) async {
    await _reliableOps.safely(
      operation: () async {
        if (_useHybridStorage) {
          // Use hybrid storage for sync support
          debugPrint('🗑️ Deleting flashcard set via hybrid storage: ${set.title}');
          await _hybridStorage.deleteFlashcardSet(set.id);
          
          // Update local cache
          _sets.removeWhere((s) => s.id == set.id);
        } else {
          // Fallback to original local storage method
          debugPrint('🗑️ Deleting flashcard set via local storage: ${set.title}');
          _sets.removeWhere((s) => s.id == set.id);
          await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
        }
        
        notifyListeners();
        debugPrint('✅ Deleted flashcard set: ${set.title}');
      },
      operationName: 'delete_flashcard_set_enhanced',
    );
  }

  /// Get set by ID with safe operation
  FlashcardSet? getSetById(String id) {
    return _reliableOps.safelySync(
      operation: () => _sets.firstWhere((set) => set.id == id),
      defaultValue: null,
      operationName: 'get_set_by_id',
    );
  }

  /// Search sets with default empty result
  List<FlashcardSet> searchSets(String query) {
    return _reliableOps.safelySync(
      operation: () {
        if (query.isEmpty) return _sets;
        return _sets.where((set) => 
          set.title.toLowerCase().contains(query.toLowerCase()) ||
          set.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      },
      defaultValue: <FlashcardSet>[],
      operationName: 'search_sets',
    ) ?? <FlashcardSet>[];
  }

  /// Search cards across all sets with default empty result
  List<Flashcard> searchCards(String query) {
    return _reliableOps.safelySync(
      operation: () {
        if (query.isEmpty) return <Flashcard>[];
        
        final cards = <Flashcard>[];
        for (final set in _sets) {
          for (final card in set.flashcards) {
            if (card.question.toLowerCase().contains(query.toLowerCase()) ||
                card.answer.toLowerCase().contains(query.toLowerCase())) {
              cards.add(card);
            }
          }
        }
        return cards;
      },
      defaultValue: <Flashcard>[],
      operationName: 'search_cards',
    ) ?? <Flashcard>[];
  }

  // ==============================================
  // PHASE 1 ENHANCEMENT: AUTHENTICATION INTEGRATION
  // ==============================================
  
  /// Handle authentication state changes for data migration
  void _onAuthenticationChanged() {
    if (_auth.isAuthenticated && _useHybridStorage) {
      debugPrint('🔐 User authenticated, checking for data migration...');
      _handleUserAuthentication();
    } else if (!_auth.isAuthenticated) {
      debugPrint('👤 User signed out, switching to guest mode...');
      _handleUserSignOut();
    }
  }
  
  /// Handle hybrid storage changes (sync status, connectivity, etc.)
  void _onHybridStorageChanged() {
    // Notify listeners when hybrid storage state changes
    notifyListeners();
  }
  
  /// Handle user authentication (potential data migration)
  Future<void> _handleUserAuthentication() async {
    await _reliableOps.safely(
      operation: () async {
        final userId = _auth.currentUser?.id;
        final guestSessionId = _guestSession.currentSessionId;
        
        if (userId != null && guestSessionId != null) {
          debugPrint('🔄 Starting data migration for new authenticated user...');
          
          // Trigger data migration via hybrid storage
          final migrationResult = await _hybridStorage.syncWithRemote();
          
          if (migrationResult.success) {
            debugPrint('✅ Data migration completed successfully');
            // Reload sets to get migrated data
            await _loadSets();
          } else {
            debugPrint('⚠️ Data migration had issues: ${migrationResult.errors}');
          }
        }
      },
      operationName: 'handle_user_authentication',
    );
  }
  
  /// Handle user sign out
  Future<void> _handleUserSignOut() async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('👤 Handling user sign out...');
        
        // Reload sets for guest session
        await _loadSets();
      },
      operationName: 'handle_user_sign_out',
    );
  }
  
  // ==============================================
  // ENHANCED PUBLIC METHODS
  // ==============================================
  
  /// Enhanced reload with hybrid storage support
  Future<void> reloadSets() async {
    if (_useHybridStorage) {
      // Force refresh hybrid storage
      await _hybridStorage.refresh();
    }
    
    await _reliableOps.safely(
      operation: () => _loadSets(),
      operationName: 'reload_sets_enhanced',
    );
  }
  
  /// Manual sync with remote storage (if available)
  Future<bool> syncWithRemote() async {
    if (!_useHybridStorage) {
      debugPrint('⚠️ Hybrid storage not available for sync');
      return false;
    }
    
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('🔄 Manual sync with remote storage...');
        final result = await _hybridStorage.syncWithRemote();
        
        if (result.success) {
          // Reload local cache after successful sync
          await _loadSets();
          debugPrint('✅ Manual sync completed successfully');
          return true;
        } else {
          debugPrint('❌ Manual sync failed: ${result.errors}');
          return false;
        }
      },
      fallback: () async {
        debugPrint('❌ Manual sync operation failed');
        return false;
      },
      operationName: 'manual_sync_with_remote',
    );
  }
  
  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    if (!_useHybridStorage) {
      return {
        'hybridStorageEnabled': false,
        'syncSupported': false,
        'localOnly': true,
      };
    }
    
    return {
      'hybridStorageEnabled': true,
      'syncSupported': true,
      'localOnly': false,
      'isOnline': isOnline,
      'isSyncing': isSyncing,
      'hasPendingOperations': hasPendingOperations,
      'lastLoadTime': lastLoadTime?.toIso8601String(),
      'hybridStorageStatus': _hybridStorage.getSyncStatus(),
    };
  }
  
  /// Force switch to local-only mode (for testing/debugging)
  void forceLocalMode() {
    if (_useHybridStorage) {
      debugPrint('🔧 Forcing local-only mode...');
      _useHybridStorage = false;
      _hybridStorage.removeListener(_onHybridStorageChanged);
      notifyListeners();
    }
  }
  
  /// Re-enable hybrid storage (if Supabase is configured)
  Future<void> enableHybridStorage() async {
    if (!_useHybridStorage && AppConfig.supabaseUrl.isNotEmpty) {
      try {
        debugPrint('🔧 Re-enabling hybrid storage...');
        await _hybridStorage.initialize();
        _useHybridStorage = true;
        _hybridStorage.addListener(_onHybridStorageChanged);
        await _loadSets();
        debugPrint('✅ Hybrid storage re-enabled successfully');
      } catch (e) {
        debugPrint('❌ Failed to re-enable hybrid storage: $e');
      }
    }
  }
  
  // ==============================================
  // COMPATIBILITY ALIASES (Backward Compatibility)
  // ==============================================
  
  /// Compatibility alias: updateFlashcardSet → updateSet
  Future<void> updateFlashcardSet(FlashcardSet set) => updateSet(set);
  
  /// Compatibility alias: deleteFlashcardSet (supports both String ID and FlashcardSet)
  Future<void> deleteFlashcardSet(dynamic setOrId) async {
    if (setOrId is String) {
      // Handle legacy String ID calls
      final set = getSetById(setOrId);
      if (set != null) {
        await deleteSet(set);
      }
    } else if (setOrId is FlashcardSet) {
      await deleteSet(setOrId);
    }
  }
  
  /// Compatibility alias: getFlashcardSet → getSetById
  FlashcardSet? getFlashcardSet(String id) => getSetById(id);
  
  /// Compatibility alias: createFlashcardSet → addSet
  Future<void> createFlashcardSet(FlashcardSet set) => addSet(set);
  
  /// Compatibility alias: searchDecks → searchSets
  List<FlashcardSet> searchDecks(String query) => searchSets(query);
  
  // ==============================================
  // CLEANUP AND DISPOSAL
  // ==============================================
  
  @override
  void dispose() {
    // Clean up listeners to prevent memory leaks
    if (_useHybridStorage) {
      _hybridStorage.removeListener(_onHybridStorageChanged);
    }
    _auth.removeListener(_onAuthenticationChanged);
    
    debugPrint('🧹 FlashcardService disposed');
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'reliable_operation_service.dart';
import 'dart:async';

class FlashcardService extends ChangeNotifier {
  final List<FlashcardSet> _sets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  final ReliableOperationService _reliableOps = ReliableOperationService();
  String? _currentUserId;
  
  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  String? get currentUserId => _currentUserId;
  
  FlashcardService() {
    _loadSets();
  }

  /// Reload data for a specific user (called after authentication)
  Future<void> reloadForUser(String? userId) async {
    debugPrint('🔄 FlashcardService: Reloading data for user: $userId');
    debugPrint('🔄 FlashcardService: Current sets count before reload: ${_sets.length}');
    _currentUserId = userId;
    await _loadSets();
    debugPrint('🔄 FlashcardService: Current sets count after reload: ${_sets.length}');
    
    // Debug progress status after reload
    for (int i = 0; i < _sets.length; i++) {
      final set = _sets[i];
      final completedCount = set.flashcards.where((card) => card.isCompleted).length;
      final progressPercent = set.flashcards.isNotEmpty 
          ? (completedCount / set.flashcards.length * 100).round() 
          : 0;
      debugPrint('🔄 Set ${i + 1}: "${set.title}" - Progress: $completedCount/${set.flashcards.length} ($progressPercent%)');
    }
  }

  /// Load sets with reliable operation patterns and user context
  Future<void> _loadSets() async {
    await _reliableOps.withFallback(
      primary: () async {
        // Check for user-specific migrated data first
        if (_currentUserId != null) {
          final migratedData = await StorageService.getUserMigratedData(_currentUserId!);
          if (migratedData != null && migratedData['flashcards'] != null) {
            debugPrint('📚 Loading migrated flashcard data for user: $_currentUserId');
            await _loadMigratedData(migratedData['flashcards']);
            return;
          }
        }
        
        // Fall back to regular storage loading
        final setsData = StorageService.getFlashcardSets(userId: _currentUserId);

        if (setsData != null && setsData.isNotEmpty) {
          _sets.clear();
          for (final data in setsData) {
            _sets.add(FlashcardSet.fromJson(data));
          }
          debugPrint('Loaded ${_sets.length} flashcard sets from storage using StorageService');
        } else {
          debugPrint('No saved sets found, loading default data from server...');
          await _loadDefaultData();
        }
        
        notifyListeners();
      },
      fallback: () async {
        debugPrint('Error loading flashcard sets, falling back to default data');
        await _loadDefaultData();
      },
      operationName: 'load_flashcard_sets',
    );
  }

  /// Load migrated data from guest session
  Future<void> _loadMigratedData(List<dynamic> migratedFlashcards) async {
    try {
      debugPrint('🔄 FlashcardService: Loading migrated data...');
      debugPrint('  - Migrated data type: ${migratedFlashcards.runtimeType}');
      debugPrint('  - Migrated data count: ${migratedFlashcards.length}');
      
      _sets.clear();
      for (final data in migratedFlashcards) {
        if (data is Map<String, dynamic>) {
          final flashcardSet = FlashcardSet.fromJson(data);
          _sets.add(flashcardSet);
          debugPrint('  - Loaded set: "${flashcardSet.title}" with ${flashcardSet.flashcards.length} cards');
          
          // Debug progress of migrated flashcards
          final completedCount = flashcardSet.flashcards.where((card) => card.isCompleted).length;
          final progressPercent = flashcardSet.flashcards.isNotEmpty 
              ? (completedCount / flashcardSet.flashcards.length * 100).round() 
              : 0;
          debugPrint('  - Progress: $completedCount/${flashcardSet.flashcards.length} ($progressPercent%)');
        } else {
          debugPrint('❌ Invalid migrated data type: ${data.runtimeType}');
        }
      }
      debugPrint('✅ Loaded ${_sets.length} migrated flashcard sets for user $_currentUserId');
      
      // Save the migrated data to regular storage for persistence
      await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load migrated data: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      // Fall back to default data
      await _loadDefaultData();
    }
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

  /// Reload sets with reliable operation
  Future<void> reloadSets() async {
    await _reliableOps.safely(
      operation: () => _loadSets(),
      operationName: 'reload_sets',
    );
  }

  /// Add set with reliable storage
  Future<void> addSet(FlashcardSet set) async {
    await _reliableOps.safely(
      operation: () async {
        _sets.add(set);
        await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
        notifyListeners();
        debugPrint('Added flashcard set: ${set.title}');
      },
      operationName: 'add_flashcard_set',
    );
  }

  /// Update set with reliable storage
  Future<void> updateSet(FlashcardSet updatedSet) async {
    await _reliableOps.safely(
      operation: () async {
        final index = _sets.indexWhere((set) => set.id == updatedSet.id);
        if (index >= 0) {
          _sets[index] = updatedSet;
          await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
          notifyListeners();
          debugPrint('Updated flashcard set: ${updatedSet.title}');
        }
      },
      operationName: 'update_flashcard_set',
    );
  }

  /// Delete set with reliable storage
  Future<void> deleteSet(FlashcardSet set) async {
    await _reliableOps.safely(
      operation: () async {
        _sets.removeWhere((s) => s.id == set.id);
        await StorageService.saveFlashcardSets(_sets.map((s) => s.toJson()).toList());
        notifyListeners();
        debugPrint('Deleted flashcard set: ${set.title}');
      },
      operationName: 'delete_flashcard_set',
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
}

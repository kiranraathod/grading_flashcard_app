import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'simple_error_handler.dart';
import 'supabase_service.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';  // ✅ ADD UUID IMPORT

class FlashcardService extends ChangeNotifier {
  static const _uuid = Uuid();  // ✅ ADD UUID INSTANCE
  final List<FlashcardSet> _sets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  String? _currentUserId;
  bool _isSyncing = false;
  
  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  String? get currentUserId => _currentUserId;
  bool get isSyncing => _isSyncing;
  
  FlashcardService() {
    _loadSets();
    
    // Listen to Supabase sync status
    _supabaseService.addListener(_onSyncStatusChanged);
  }
  
  void _onSyncStatusChanged() {
    if (_supabaseService.syncStatus == SyncStatus.synced) {
      _loadSetsFromCloud();
    }
    notifyListeners();
  }

  /// Ensure ID is valid UUID format, generate new one if needed
  String _ensureValidUuid(String id) {
    try {
      return Uuid.parse(id).toString();
    } catch (e) {
      return _uuid.v4();
    }
  }

  /// Store mapping between local string ID and cloud UUID
  Future<void> _storeUuidMapping(String localId, String cloudUuid) async {
    final mappings = await StorageService.getUuidMappings() ?? <String, String>{};
    mappings[localId] = cloudUuid;
    await StorageService.saveUuidMappings(mappings);
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
    
    // Initialize sync if user is authenticated
    if (_supabaseService.isAuthenticated && _supabaseService.isOnline) {
      await _syncWithCloud();
    }
  }

  /// Load sets with reliable operation patterns and user context
  Future<void> _loadSets() async {
    await SimpleErrorHandler.safe<void>(
      () async {
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
        
        // Try to sync with cloud if authenticated and online
        if (_supabaseService.isAuthenticated && _supabaseService.isOnline) {
          _syncWithCloud();
        }
      },
      fallbackOperation: () async {
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
    await SimpleErrorHandler.safe<void>(
      () async {
        debugPrint('Loading default flashcard sets from server...');
        final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
        
        _sets.clear();
        _sets.addAll(defaultSets);
        
        debugPrint('Loaded ${defaultSets.length} default flashcard sets from server');
        notifyListeners();
      },
      fallbackOperation: () async {
        debugPrint('Server failed, creating minimal fallback data');
        _loadMinimalFallbackData();
      },
      operationName: 'load_default_flashcard_data',
    );
  }

  /// Create minimal fallback data safely
  void _loadMinimalFallbackData() {
    try {
      debugPrint('Loading minimal fallback data...');
      _sets.clear();
      _loadMinimalServerFallback();
    } catch (e) {
      debugPrint('Error in minimal fallback data: $e');
      _createOfflineOnlyFallback();
    }
  }

  /// Attempt minimal server fallback with safe offline creation
  Future<void> _loadMinimalServerFallback() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        debugPrint('Attempting to load minimal server fallback data...');
        final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
        
        if (defaultSets.isNotEmpty) {
          _sets.addAll(defaultSets);
          debugPrint('Loaded ${defaultSets.length} minimal sets from server fallback');
        } else {
          _createOfflineOnlyFallback();
        }
      },
      fallbackOperation: () async {
        debugPrint('Server fallback also failed, creating offline-only fallback');
        _createOfflineOnlyFallback();
      },
      operationName: 'load_minimal_server_fallback',
    );
    
    notifyListeners();
  }

  /// Create absolute minimal offline fallback
  void _createOfflineOnlyFallback() {
    try {
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
    } catch (e) {
      debugPrint('Error creating offline fallback: $e');
    }
  }

  /// Reload sets with reliable operation
  Future<void> reloadSets() async {
    await SimpleErrorHandler.safe<void>(
      () => _loadSets(),
      operationName: 'reload_sets',
    );
  }

  /// Add set with reliable storage and sync
  Future<void> addSet(FlashcardSet set) async {
    await SimpleErrorHandler.safe<void>(
      () async {
        _sets.add(set);
        await _saveAndSync();
        debugPrint('Added flashcard set: ${set.title}');
      },
      operationName: 'add_flashcard_set',
    );
  }

  /// Update set with reliable storage and sync
  Future<void> updateSet(FlashcardSet updatedSet) async {
    await SimpleErrorHandler.safe<void>(
      () async {
        final index = _sets.indexWhere((set) => set.id == updatedSet.id);
        if (index >= 0) {
          _sets[index] = updatedSet;
          await _saveAndSync();
          debugPrint('Updated flashcard set: ${updatedSet.title}');
        }
      },
      operationName: 'update_flashcard_set',
    );
  }

  /// Delete set with reliable storage and sync
  Future<void> deleteSet(FlashcardSet set) async {
    await SimpleErrorHandler.safe<void>(
      () async {
        _sets.removeWhere((s) => s.id == set.id);
        await _saveAndSync();
        
        // Soft delete from cloud using is_deleted column
        if (_supabaseService.isAuthenticated) {
          try {
            String setUuid = _ensureValidUuid(set.id);
            await _supabaseService.client!
                .from('flashcard_sets')
                .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
                .eq('id', setUuid);
            debugPrint('✅ Soft deleted flashcard set from cloud: ${set.title}');
          } catch (e) {
            debugPrint('❌ Error soft deleting set from cloud: $e');
          }
        }
        
        debugPrint('Deleted flashcard set: ${set.title}');
      },
      operationName: 'delete_flashcard_set',
    );
  }

  /// Get set by ID with safe operation
  FlashcardSet? getSetById(String id) {
    try {
      return _sets.firstWhere((set) => set.id == id);
    } catch (e) {
      debugPrint('Error getting set by ID $id: $e');
      return null;
    }
  }

  /// Search sets with default empty result
  List<FlashcardSet> searchSets(String query) {
    try {
      if (query.isEmpty) return _sets;
      return _sets.where((set) => 
        set.title.toLowerCase().contains(query.toLowerCase()) ||
        set.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      debugPrint('Error searching sets: $e');
      return <FlashcardSet>[];
    }
  }

  /// Search cards across all sets with default empty result
  List<Flashcard> searchCards(String query) {
    try {
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
    } catch (e) {
      debugPrint('Error searching cards: $e');
      return <Flashcard>[];
    }
  }

  // ==============================================
  // SYNC FUNCTIONALITY
  // ==============================================
  
  Future<void> _loadSetsFromCloud() async {
    if (!_supabaseService.isAuthenticated) return;
    
    try {
      final response = await _supabaseService.client!
          .from('flashcard_sets')
          .select('*, flashcards(*)')
          .eq('user_id', _supabaseService.currentUserId!)
          .eq('is_deleted', false)
          .order('updated_at', ascending: false);
      
      final cloudSets = response.map<FlashcardSet>((json) {
        // Convert Supabase response to FlashcardSet
        final flashcards = (json['flashcards'] as List? ?? [])
            .map<Flashcard>((cardJson) => Flashcard.fromJson(cardJson))
            .toList();
            
        return FlashcardSet(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? '',
          flashcards: flashcards,
          lastUpdated: DateTime.parse(json['updated_at']),
        );
      }).toList();
      
      _sets.clear();
      _sets.addAll(cloudSets);
      
      // Save to local storage
      await StorageService.saveFlashcardSets(
        _sets.map((set) => set.toJson()).toList()
      );
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error loading sets from cloud: $e');
    }
  }
  
  Future<void> _syncWithCloud() async {
    if (_isSyncing || !_supabaseService.isAuthenticated) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Upload local changes to cloud
      for (final set in _sets) {
        if (_needsSync(set)) {
          await _uploadSetToCloud(set);
        }
      }
      
      // Download latest from cloud
      await _loadSetsFromCloud();
      
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  bool _needsSync(FlashcardSet set) {
    // Implement logic to determine if set needs syncing
    // This could be based on a local "dirty" flag or timestamp comparison
    return true; // Simplified for now
  }
  
  Future<void> _uploadSetToCloud(FlashcardSet set) async {
    try {
      // Generate UUID for set if it doesn't exist or isn't valid UUID
      String setUuid = _ensureValidUuid(set.id);
      
      // Upsert flashcard set with proper UUID
      await _supabaseService.client!
          .from('flashcard_sets')
          .upsert({
            'id': setUuid,
            'user_id': _supabaseService.currentUserId!,
            'title': set.title,
            'description': set.description,
            'is_draft': set.isDraft,
            'rating': set.rating,
            'rating_count': set.ratingCount,
            'flashcard_count': set.flashcards.length,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      // Upload flashcards with proper schema mapping
      for (int index = 0; index < set.flashcards.length; index++) {
        final flashcard = set.flashcards[index];
        String cardUuid = _ensureValidUuid(flashcard.id);
        
        // Insert/update flashcard (NO is_completed here)
        await _supabaseService.client!
            .from('flashcards')
            .upsert({
              'id': cardUuid,
              'set_id': setUuid,
              'question': flashcard.question,
              'answer': flashcard.answer,
              'order_index': index,
              'difficulty': 'medium',
              'updated_at': DateTime.now().toIso8601String(),
            });
        
        // Handle completion status in separate user_progress table
        if (flashcard.isCompleted || flashcard.isMarkedForReview) {
          await _supabaseService.client!
              .from('user_progress')
              .upsert({
                'user_id': _supabaseService.currentUserId!,
                'flashcard_id': cardUuid,
                'is_completed': flashcard.isCompleted,
                'is_marked_for_review': flashcard.isMarkedForReview,
                'updated_at': DateTime.now().toIso8601String(),
              });
        }
      }
      
      // Store UUID mapping for future reference
      await _storeUuidMapping(set.id, setUuid);
      
    } catch (e) {
      debugPrint('❌ Error uploading set to cloud: $e');
      rethrow;
    }
  }
  
  Future<void> _saveAndSync() async {
    // Save locally first (optimistic update)
    await StorageService.saveFlashcardSets(
      _sets.map((set) => set.toJson()).toList()
    );
    notifyListeners();
    
    // Then sync to cloud
    if (_supabaseService.isOnline && _supabaseService.isAuthenticated) {
      _syncWithCloud();
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

  /// Force refresh from cloud
  Future<void> refreshFromCloud() async {
    if (_supabaseService.isAuthenticated) {
      await _loadSetsFromCloud();
    }
  }
  
  @override
  void dispose() {
    _supabaseService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }
}

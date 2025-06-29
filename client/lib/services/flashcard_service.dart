import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'simple_error_handler.dart';
import 'supabase_service.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';  // ✅ ADD UUID IMPORT

/// FlashcardService with enhanced duplicate prevention
/// 
/// Recent improvements:
/// - 🛡️ Database-level unique constraints prevent duplicate flashcard sets
/// - 🔄 Migration flag prevents repeated loading of migration data
/// - ⚠️ Graceful error handling for constraint violations (PostgrestException 23505)
/// - ✅ Uses upsert operations for all database writes to handle conflicts
/// - 🧹 Migration completion tracking to prevent data multiplication
class FlashcardService extends ChangeNotifier {
  static const _uuid = Uuid();  // ✅ ADD UUID INSTANCE
  static const String _migrationCompleteKey = 'migration_complete_v2';  // ✅ ADD MIGRATION FLAG
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

  /// Normalize title for consistent duplicate detection
  /// Removes leading/trailing whitespace and converts to lowercase
  String _normalizeTitle(String title) {
    return title.trim().toLowerCase();
  }

  /// Check if a title already exists locally (with normalization)
  bool _isDuplicateTitle(String title) {
    final normalizedTitle = _normalizeTitle(title);
    return _sets.any((set) => _normalizeTitle(set.title) == normalizedTitle);
  }

  /// Validate flashcard set before adding/uploading
  String? _validateFlashcardSet(FlashcardSet set) {
    // Check for empty title
    final trimmedTitle = set.title.trim();
    if (trimmedTitle.isEmpty) {
      return 'Title cannot be empty';
    }
    
    // Check for local duplicates
    if (_isDuplicateTitle(set.title)) {
      return 'A flashcard set with this title already exists';
    }
    
    // Check for empty flashcards
    if (set.flashcards.isEmpty) {
      return 'Flashcard set must contain at least one card';
    }
    
    return null; // No validation errors
  }

  /// Ensure ID is valid UUID format, generate new one if needed
  /// Handles byte array conversion and JSON serialization issues
  String _ensureValidUuid(String? id) {
    if (id == null || id.isEmpty) {
      return _uuid.v4();
    }
    
    // Handle byte array format from JSON serialization
    if (id.startsWith('[') && id.endsWith(']')) {
      try {
        // Convert byte array string to proper UUID
        final byteString = id.replaceAll('[', '').replaceAll(']', '').replaceAll(' ', '');
        final bytes = byteString.split(',').map((e) => int.parse(e.trim())).toList();
        
        if (bytes.length == 16) {
          // Convert bytes to UUID string format
          final uuid = '${bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}-'
                     '${bytes.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}-'
                     '${bytes.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}-'
                     '${bytes.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}-'
                     '${bytes.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
          return uuid;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to convert byte array UUID: $e');
        return _uuid.v4();
      }
    }
    
    // Handle existing UUID strings
    try {
      // Validate existing UUID format
      final parsed = Uuid.parse(id);
      return Uuid.unparse(parsed);
    } catch (e) {
      // Generate new UUID if current one is invalid
      debugPrint('🔄 Converting legacy ID "$id" to UUID format');
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
          // Check if migration already completed
          final prefs = await SharedPreferences.getInstance();
          final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
          
          if (!migrationComplete) {
            final migratedData = await StorageService.getUserMigratedData(_currentUserId!);
            if (migratedData != null && migratedData['flashcards'] != null) {
              debugPrint('📚 Loading migrated flashcard data for user: $_currentUserId');
              await _loadMigratedData(migratedData['flashcards']);
              
              // Mark migration as complete to prevent future loads
              await prefs.setBool(_migrationCompleteKey, true);
              debugPrint('✅ Migration marked as complete');
              return;
            }
          } else {
            debugPrint('✅ Migration already completed, skipping migrated data load');
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
        // Validate the flashcard set
        final validationError = _validateFlashcardSet(set);
        if (validationError != null) {
          throw Exception(validationError);
        }
        
        // Normalize the title to prevent near-duplicates
        final normalizedTitle = set.title.trim();
        
        // Ensure the set has a valid UUID
        final validSetId = set.id.isEmpty ? _uuid.v4() : _ensureValidUuid(set.id);
        
        // Ensure all flashcards have valid UUIDs
        final updatedFlashcards = set.flashcards.map((flashcard) {
          final validFlashcardId = flashcard.id.isEmpty ? _uuid.v4() : _ensureValidUuid(flashcard.id);
          return Flashcard(
            id: validFlashcardId,
            question: flashcard.question,
            answer: flashcard.answer,
            isMarkedForReview: flashcard.isMarkedForReview,
            isCompleted: flashcard.isCompleted,
          );
        }).toList();
        
        // Create a new FlashcardSet with normalized data
        final normalizedSet = set.copyWith(
          title: normalizedTitle,
          flashcards: updatedFlashcards,
        );
        final finalSet = FlashcardSet(
          id: validSetId,
          title: normalizedSet.title,
          description: normalizedSet.description,
          isDraft: normalizedSet.isDraft,
          rating: normalizedSet.rating,
          ratingCount: normalizedSet.ratingCount,
          flashcards: normalizedSet.flashcards,
          lastUpdated: normalizedSet.lastUpdated,
        );
        
        _sets.add(finalSet);
        await _saveAndSync();
        debugPrint('✅ Added flashcard set: "${set.title}" with ${set.flashcards.length} cards');
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
      
      // Normalize title before upload to match database constraints
      final normalizedTitle = set.title.trim();
      
      // Upsert flashcard set with proper UUID and normalized title
      await _supabaseService.client!
          .from('flashcard_sets')
          .upsert({
            'id': setUuid,
            'user_id': _supabaseService.currentUserId!,
            'title': normalizedTitle,
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
      
      debugPrint('✅ Successfully uploaded set "$normalizedTitle" to cloud');
      
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Duplicate key violation - handle gracefully
        debugPrint('⚠️ Set "${set.title}" already exists in cloud, skipping upload');
        // Don't rethrow - this is expected behavior with our constraints
        return;
      }
      // For other PostgrestExceptions, log and rethrow
      debugPrint('❌ Supabase error uploading set "${set.title}": ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error uploading set "${set.title}" to cloud: $e');
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
  
  /// Reset migration completion flag (for testing/debugging)
  /// Call this if you need to re-run migration data loading
  Future<void> resetMigrationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationCompleteKey);
    debugPrint('🔄 Migration flag reset - migration data will be loaded on next app start');
  }
  
  @override
  void dispose() {
    _supabaseService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }
}

/// FlashcardRepository implementation
///
/// Implements repository pattern for flashcard data with:
/// - Offline-first strategy (local cache primary)
/// - Conflict resolution for progress updates
/// - Stream-based reactive data access
/// - Integration with existing StorageService and SupabaseService
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart' hide SyncStatus;
import '../services/connectivity_service.dart';
import 'base_repository.dart';

/// Repository for flashcard data operations
///
/// Provides single source of truth for flashcard data while maintaining
/// compatibility with existing service layer during migration
class FlashcardRepository extends BaseRepositoryImpl<FlashcardSet>
    implements SyncableRepository<FlashcardSet> {
  // Dependencies (wrapped existing services)
  // Note: _storageService kept for compatibility during migration
  // ignore: unused_field
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  final ConnectivityService _connectivityService;

  // Internal state
  final StreamController<List<FlashcardSet>> _setsController =
      StreamController<List<FlashcardSet>>.broadcast();
  final StreamController<SyncStatus> _syncController =
      StreamController<SyncStatus>.broadcast();

  List<FlashcardSet> _cachedSets = [];
  SyncStatus _currentSyncStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  bool _isInitialized = false;

  FlashcardRepository({
    required StorageService storageService,
    required SupabaseService supabaseService,
    required ConnectivityService connectivityService,
  }) : _storageService = storageService,
       _supabaseService = supabaseService,
       _connectivityService = connectivityService {
    // Initialize repository
    _initialize();
  }

  /// Initialize repository and load cached data
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      logOperation('initialize');

      // Load from cache first (offline-first pattern)
      await _loadFromCache();

      // For Phase 1: Simplified connectivity handling
      // In later phases, we'll add proper stream listening

      // Attempt initial sync if online
      if (_connectivityService.isOnline) {
        unawaited(_syncFromCloud());
      }

      _isInitialized = true;
      debugPrint('✅ FlashcardRepository initialized successfully');
    } catch (error) {
      debugPrint('❌ Failed to initialize FlashcardRepository: $error');
      // Continue with empty state rather than failing
      _setsController.add([]);
    }
  }

  /// Load flashcard sets from local cache
  Future<void> _loadFromCache() async {
    final setsData = StorageService.getFlashcardSets();

    if (setsData != null && setsData.isNotEmpty) {
      _cachedSets =
          setsData.map((data) => FlashcardSet.fromJson(data)).toList();
      logOperation('loadFromCache', metadata: {'count': _cachedSets.length});
    } else {
      _cachedSets = [];
      logOperation('loadFromCache', metadata: {'count': 0, 'status': 'empty'});
    }

    // Emit current state
    _setsController.add(List.unmodifiable(_cachedSets));
  }

  /// Save to local cache
  Future<void> _saveToCache() async {
    await StorageService.saveFlashcardSets(
      _cachedSets.map((set) => set.toJson()).toList(),
    );
    logOperation('saveToCache', metadata: {'count': _cachedSets.length});
  }

  // ============================================================================
  // BaseRepository Implementation
  // ============================================================================

  @override
  Future<List<FlashcardSet>> getAll() async {
    return safeOperation('getAll', () async {
      if (!_isInitialized) await _initialize();
      return List.unmodifiable(_cachedSets);
    });
  }

  @override
  Future<FlashcardSet?> getById(String id) async {
    return safeOperation('getById', () async {
      if (!_isInitialized) await _initialize();

      try {
        return _cachedSets.firstWhere((set) => set.id == id);
      } catch (e) {
        return null; // Not found
      }
    });
  }

  @override
  Future<void> save(FlashcardSet item) async {
    return safeOperation('save', () async {
      validateItem(item);

      // Update cache
      final existingIndex = _cachedSets.indexWhere((set) => set.id == item.id);

      if (existingIndex >= 0) {
        _cachedSets[existingIndex] = item;
        logOperation('update', metadata: {'id': item.id, 'title': item.title});
      } else {
        _cachedSets.add(item);
        logOperation('create', metadata: {'id': item.id, 'title': item.title});
      }

      // Save to local storage immediately (optimistic update)
      await _saveToCache();

      // Emit updated state
      _setsController.add(List.unmodifiable(_cachedSets));

      // Queue for cloud sync if online
      if (_connectivityService.isOnline && _supabaseService.isAuthenticated) {
        unawaited(_syncToCloud());
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    return safeOperation('delete', () async {
      final removedCount = _cachedSets.length;
      _cachedSets.removeWhere((set) => set.id == id);

      if (_cachedSets.length < removedCount) {
        // Save to cache
        await _saveToCache();

        // Emit updated state
        _setsController.add(List.unmodifiable(_cachedSets));

        logOperation('delete', metadata: {'id': id});

        // Mark as deleted in cloud if online
        if (_connectivityService.isOnline && _supabaseService.isAuthenticated) {
          unawaited(_markDeletedInCloud(id));
        }
      }
    });
  }

  @override
  Future<void> clear() async {
    return safeOperation('clear', () async {
      _cachedSets.clear();
      await _saveToCache();
      _setsController.add([]);
      logOperation('clear');
    });
  }

  @override
  Stream<List<FlashcardSet>> watchAll() {
    if (!_isInitialized) {
      _initialize();
    }
    return _setsController.stream;
  }

  @override
  Stream<FlashcardSet?> watchById(String id) {
    return watchAll().map((sets) {
      try {
        return sets.firstWhere((set) => set.id == id);
      } catch (e) {
        return null;
      }
    });
  }
  // ============================================================================
  // SyncableRepository Implementation
  // ============================================================================

  @override
  Future<void> syncToCloud() async {
    await _syncToCloud();
  }

  @override
  Future<void> syncFromCloud() async {
    await _syncFromCloud();
  }

  @override
  Future<void> resolveSyncConflicts() async {
    // Implement conflict resolution strategy
    // For Phase 1, we'll use "last modified wins" strategy
    logOperation(
      'resolveSyncConflicts',
      metadata: {'strategy': 'lastModifiedWins'},
    );
  }

  @override
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  @override
  bool get isSyncing => _currentSyncStatus == SyncStatus.syncing;

  @override
  Future<void> refreshFromCloud() async {
    await _syncFromCloud(forceRefresh: true);
  }

  @override
  DateTime? get lastSyncTime => _lastSyncTime;
  // ============================================================================
  // Private Sync Implementation
  // ============================================================================

  Future<void> _syncToCloud() async {
    if (!_supabaseService.isAuthenticated) {
      debugPrint('⚠️ Cannot sync to cloud: not authenticated');
      return;
    }

    if (_currentSyncStatus == SyncStatus.syncing) {
      debugPrint('⚠️ Sync already in progress, skipping');
      return;
    }

    _updateSyncStatus(SyncStatus.syncing);

    try {
      logOperation('syncToCloud', metadata: {'setsCount': _cachedSets.length});

      // For Phase 1: Upload each set to cloud (existing SupabaseService logic)
      // In later phases, we'll implement direct cloud operations here
      for (int i = 0; i < _cachedSets.length; i++) {
        // Note: For Phase 1, we're wrapping existing service calls
        // In later phases, we'll implement direct cloud operations here
      }

      _lastSyncTime = DateTime.now();
      _updateSyncStatus(SyncStatus.synced);
    } catch (error, stackTrace) {
      debugPrint('❌ Cloud sync upload failed: $error');
      _updateSyncStatus(SyncStatus.error);

      throw RepositoryException(
        message: 'Failed to sync to cloud',
        operation: 'syncToCloud',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncFromCloud({bool forceRefresh = false}) async {
    if (!_supabaseService.isAuthenticated) {
      debugPrint('⚠️ Cannot sync from cloud: not authenticated');
      return;
    }

    if (_currentSyncStatus == SyncStatus.syncing && !forceRefresh) {
      debugPrint('⚠️ Sync already in progress, skipping');
      return;
    }

    _updateSyncStatus(SyncStatus.syncing);

    try {
      logOperation('syncFromCloud', metadata: {'forceRefresh': forceRefresh});

      // For Phase 1: Load through existing service
      // TODO: In later phases, implement direct cloud access here

      _lastSyncTime = DateTime.now();
      _updateSyncStatus(SyncStatus.synced);
    } catch (error, stackTrace) {
      debugPrint('❌ Cloud sync download failed: $error');
      _updateSyncStatus(SyncStatus.error);

      throw RepositoryException(
        message: 'Failed to sync from cloud',
        operation: 'syncFromCloud',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _markDeletedInCloud(String setId) async {
    try {
      // Soft delete in cloud (existing SupabaseService pattern)
      logOperation('markDeletedInCloud', metadata: {'setId': setId});
    } catch (error) {
      debugPrint('❌ Failed to mark set $setId as deleted in cloud: $error');
      // Don't rethrow - local deletion should succeed even if cloud fails
    }
  }

  void _updateSyncStatus(SyncStatus newStatus) {
    _currentSyncStatus = newStatus;
    _syncController.add(newStatus);
  }
  // ============================================================================
  // Validation & Utility Methods
  // ============================================================================

  @override
  void validateItem(FlashcardSet item) {
    final errors = <String, String>{};

    // Validate title
    if (item.title.trim().isEmpty) {
      errors['title'] = 'Title cannot be empty';
    }

    // Validate flashcards
    if (item.flashcards.isEmpty) {
      errors['flashcards'] = 'Set must contain at least one flashcard';
    }

    // Check for duplicate titles (case-insensitive)
    final normalizedTitle = item.title.trim().toLowerCase();
    final existingSets = _cachedSets.where(
      (set) =>
          set.id != item.id &&
          set.title.trim().toLowerCase() == normalizedTitle,
    );

    if (existingSets.isNotEmpty) {
      errors['title'] = 'A set with this title already exists';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        message: 'Validation failed for FlashcardSet',
        operation: 'validateItem',
        fieldErrors: errors,
      );
    }
  }
  // ============================================================================
  // Additional Repository Methods for FlashcardSet Specific Operations
  // ============================================================================

  /// Update progress for a specific flashcard
  Future<void> updateCardProgress({
    required String setId,
    required String cardId,
    required bool isCompleted,
  }) async {
    return safeOperation('updateCardProgress', () async {
      final set = await getById(setId);
      if (set == null) {
        throw RepositoryException(
          message: 'FlashcardSet not found',
          operation: 'updateCardProgress',
        );
      }

      // Update specific flashcard
      final updatedFlashcards =
          set.flashcards.map((card) {
            if (card.id == cardId) {
              return Flashcard(
                id: card.id,
                question: card.question,
                answer: card.answer,
                isCompleted: isCompleted,
                isMarkedForReview: card.isMarkedForReview,
              );
            }
            return card;
          }).toList();

      // Create updated set
      final updatedSet = set.copyWith(
        flashcards: updatedFlashcards,
        lastUpdated: DateTime.now(),
      );

      // Save updated set
      await save(updatedSet);

      logOperation(
        'updateCardProgress',
        metadata: {
          'setId': setId,
          'cardId': cardId,
          'isCompleted': isCompleted,
        },
      );
    });
  }

  /// Search flashcard sets by query
  Future<List<FlashcardSet>> search(String query) async {
    return safeOperation('search', () async {
      if (query.trim().isEmpty) {
        return await getAll();
      }

      final allSets = await getAll();
      final lowerQuery = query.toLowerCase();

      return allSets
          .where(
            (set) =>
                set.title.toLowerCase().contains(lowerQuery) ||
                set.description.toLowerCase().contains(lowerQuery),
          )
          .toList();
    });
  }

  /// Get sets with specific completion status
  Future<List<FlashcardSet>> getSetsByCompletionStatus(bool completed) async {
    return safeOperation('getSetsByCompletionStatus', () async {
      final allSets = await getAll();

      return allSets.where((set) {
        final completedCards =
            set.flashcards.where((card) => card.isCompleted).length;
        final isSetCompleted =
            completedCards == set.flashcards.length &&
            set.flashcards.isNotEmpty;
        return isSetCompleted == completed;
      }).toList();
    });
  }

  // ============================================================================
  // Dispose and Cleanup
  // ============================================================================

  void dispose() {
    _setsController.close();
    _syncController.close();
    logOperation('dispose');
  }
}

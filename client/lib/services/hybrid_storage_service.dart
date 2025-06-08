import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/flashcard_set.dart';
import '../models/category.dart' as models;
import 'storage_service.dart';
import 'supabase/supabase_data_service.dart';
import 'guest_session_service.dart';
import 'supabase_auth_service.dart';
import 'reliable_operation_service.dart';
import '../utils/migration/flashcard_set_migration_helper.dart';
import '../utils/migration/category_migration_helper.dart';

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final List<String> errors;
  final DateTime timestamp;
  final SyncDirection direction;
  
  SyncResult({
    required this.success,
    required this.itemsSynced,
    required this.errors,
    required this.direction,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'SyncResult(success: $success, items: $itemsSynced, direction: $direction, errors: ${errors.length})';
  }
}

enum SyncDirection { localToRemote, remoteToLocal, bidirectional }
enum SyncStrategy { localFirst, remoteFirst, manualSync, migrationSync }

/// HybridStorageService provides intelligent local+remote storage with sync capabilities
/// 
/// This service combines the reliability of local storage with the persistence and 
/// sharing capabilities of Supabase, implementing a local-first approach with 
/// background synchronization when connectivity is available.
class HybridStorageService extends ChangeNotifier {
  // Singleton pattern consistent with other services
  static final HybridStorageService _instance = HybridStorageService._internal();
  factory HybridStorageService() => _instance;
  HybridStorageService._internal();

  // Dependencies
  final SupabaseDataService _remoteStorage = SupabaseDataService();
  final GuestSessionService _guestSession = GuestSessionService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  final ReliableOperationService _reliableOps = ReliableOperationService();
  final Connectivity _connectivity = Connectivity();
  
  // State
  bool _isInitialized = false;
  SyncStrategy _currentStrategy = SyncStrategy.localFirst;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  final List<String> _pendingOperations = [];
  
  // Cache
  List<FlashcardSet>? _cachedSets;
  List<models.Category>? _cachedCategories;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _remoteStorage.isReady;
  bool get isSyncing => _isSyncing;
  SyncStrategy get currentStrategy => _currentStrategy;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;
  List<String> get pendingOperations => List.unmodifiable(_pendingOperations);
  
  /// Initialize the hybrid storage service
  Future<void> initialize() async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('🔧 Initializing HybridStorageService...');
        
        // Initialize remote storage
        await _remoteStorage.initialize();
        
        // Set up connectivity monitoring
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
        
        _isInitialized = true;
        debugPrint('✅ HybridStorageService: Initialized successfully');
        
        // Perform initial sync if online
        if (isOnline) {
          _performBackgroundSync();
        }
        
        notifyListeners();
      },
      operationName: 'hybrid_storage_initialization',
    );
  }
  
  // ===== FLASHCARD SETS OPERATIONS =====
  
  /// Load flashcard sets with intelligent caching and sync
  Future<List<FlashcardSet>> loadFlashcardSets() async {
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('📚 Loading flashcard sets with hybrid strategy: $_currentStrategy');
        
        // Check cache first
        if (_isCacheValid() && _cachedSets != null) {
          debugPrint('✅ Returning cached flashcard sets (${_cachedSets!.length} items)');
          return _cachedSets!;
        }
        
        List<FlashcardSet> sets;
        
        switch (_currentStrategy) {
          case SyncStrategy.localFirst:
            sets = await _loadLocalFirst();
            break;
          case SyncStrategy.remoteFirst:
            sets = await _loadRemoteFirst();
            break;
          case SyncStrategy.manualSync:
            sets = await _loadLocalOnly();
            break;
          case SyncStrategy.migrationSync:
            sets = await _loadForMigration();
            break;
        }
        
        // Update cache
        _cachedSets = sets;
        _cacheTimestamp = DateTime.now();
        
        debugPrint('✅ Loaded ${sets.length} flashcard sets');
        return sets;
      },
      fallback: () async {
        debugPrint('❌ Failed to load flashcard sets, attempting local-only');
        return await _loadLocalOnly();
      },
      operationName: 'load_flashcard_sets',
    );
  }
  
  /// Save flashcard sets with sync strategy
  Future<void> saveFlashcardSets(List<FlashcardSet> sets) async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('💾 Saving ${sets.length} flashcard sets with hybrid strategy');
        
        // Always save to local storage first (local-first approach)
        await StorageService.saveFlashcardSets(
          sets.map((set) => set.toJson()).toList(),
        );
        
        // Update cache
        _cachedSets = List<FlashcardSet>.from(sets);
        _cacheTimestamp = DateTime.now();
        
        // Sync to remote if online
        if (isOnline && !_isSyncing) {
          _performBackgroundSync();
        } else {
          // Add to pending operations
          _pendingOperations.add('save_flashcard_sets_${DateTime.now().millisecondsSinceEpoch}');
        }
        
        notifyListeners();
        debugPrint('✅ Saved flashcard sets locally');
      },
      operationName: 'save_flashcard_sets',
    );
  }
  
  /// Add a single flashcard set
  Future<FlashcardSet> addFlashcardSet(FlashcardSet set) async {
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('➕ Adding flashcard set: ${set.title}');
        
        // Determine ownership and migrate if necessary
        final processedSet = await _prepareSetForCurrentUser(set);
        
        // Save to local storage first
        final currentSets = await loadFlashcardSets();
        final updatedSets = [...currentSets, processedSet];
        await saveFlashcardSets(updatedSets);
        
        // Try to save to remote if online
        if (isOnline) {
          try {
            final remoteSet = await _remoteStorage.createFlashcardSet(processedSet);
            debugPrint('✅ Successfully synced new set to remote storage');
            return remoteSet;
          } catch (e) {
            debugPrint('⚠️ Failed to sync to remote, saved locally: $e');
          }
        }
        
        return processedSet;
      },
      fallback: () async {
        debugPrint('❌ Failed to add flashcard set, returning original');
        return set;
      },
      operationName: 'add_flashcard_set',
    );
  }
  
  /// Update a flashcard set
  Future<FlashcardSet> updateFlashcardSet(FlashcardSet set) async {
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('✏️ Updating flashcard set: ${set.title}');
        
        // Update in local storage first
        final currentSets = await loadFlashcardSets();
        final index = currentSets.indexWhere((s) => s.id == set.id);
        
        if (index >= 0) {
          final updatedSets = [...currentSets];
          updatedSets[index] = set.copyWith(updatedAt: DateTime.now());
          await saveFlashcardSets(updatedSets);
          
          // Try to sync to remote if online
          if (isOnline) {
            try {
              final remoteSet = await _remoteStorage.updateFlashcardSet(updatedSets[index]);
              debugPrint('✅ Successfully synced updated set to remote storage');
              return remoteSet;
            } catch (e) {
              debugPrint('⚠️ Failed to sync update to remote, saved locally: $e');
            }
          }
          
          return updatedSets[index];
        } else {
          throw Exception('FlashcardSet not found: ${set.id}');
        }
      },
      fallback: () async {
        debugPrint('❌ Failed to update flashcard set, returning original');
        return set;
      },
      operationName: 'update_flashcard_set',
    );
  }
  
  /// Delete a flashcard set
  Future<void> deleteFlashcardSet(String id) async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('🗑️ Deleting flashcard set: $id');
        
        // Remove from local storage first
        final currentSets = await loadFlashcardSets();
        final updatedSets = currentSets.where((set) => set.id != id).toList();
        await saveFlashcardSets(updatedSets);
        
        // Try to delete from remote if online
        if (isOnline) {
          try {
            await _remoteStorage.deleteFlashcardSet(id);
            debugPrint('✅ Successfully deleted set from remote storage');
          } catch (e) {
            debugPrint('⚠️ Failed to delete from remote, deleted locally: $e');
          }
        }
      },
      operationName: 'delete_flashcard_set',
    );
  }
  
  // ===== CATEGORY OPERATIONS =====
  
  /// Load categories with hybrid strategy
  Future<List<models.Category>> loadCategories() async {
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('📁 Loading categories with hybrid strategy');
        
        // Check cache first
        if (_isCacheValid() && _cachedCategories != null) {
          debugPrint('✅ Returning cached categories (${_cachedCategories!.length} items)');
          return _cachedCategories!;
        }
        
        List<models.Category> categories;
        
        // Try remote first for categories as they're smaller and more static
        if (isOnline) {
          try {
            categories = await _remoteStorage.getCategories();
            debugPrint('✅ Loaded ${categories.length} categories from remote storage');
          } catch (e) {
            debugPrint('⚠️ Failed to load categories from remote, falling back to local: $e');
            categories = await _loadLocalCategories();
          }
        } else {
          categories = await _loadLocalCategories();
        }
        
        // If no categories exist, create defaults
        if (categories.isEmpty) {
          categories = _createDefaultCategories();
          await _saveLocalCategories(categories);
        }
        
        // Update cache
        _cachedCategories = categories;
        _cacheTimestamp = DateTime.now();
        
        return categories;
      },
      fallback: () async {
        debugPrint('❌ Failed to load categories, creating defaults');
        return _createDefaultCategories();
      },
      operationName: 'load_categories',
    );
  }
  
  /// Add a category
  Future<models.Category> addCategory(models.Category category) async {
    return await _reliableOps.withFallback(
      primary: () async {
        debugPrint('➕ Adding category: ${category.name}');
        
        // Determine ownership and migrate if necessary
        final processedCategory = await _prepareCategoryForCurrentUser(category);
        
        // Save to local storage first
        final currentCategories = await loadCategories();
        final updatedCategories = [...currentCategories, processedCategory];
        await _saveLocalCategories(updatedCategories);
        
        // Try to save to remote if online
        if (isOnline) {
          try {
            final remoteCategory = await _remoteStorage.createCategory(processedCategory);
            debugPrint('✅ Successfully synced new category to remote storage');
            return remoteCategory;
          } catch (e) {
            debugPrint('⚠️ Failed to sync category to remote, saved locally: $e');
          }
        }
        
        return processedCategory;
      },
      fallback: () async {
        debugPrint('❌ Failed to add category, returning original');
        return category;
      },
      operationName: 'add_category',
    );
  }
  
  // ===== SYNC OPERATIONS =====
  
  /// Perform manual sync with remote storage
  Future<SyncResult> syncWithRemote({SyncDirection direction = SyncDirection.bidirectional}) async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping');
      return SyncResult(success: false, itemsSynced: 0, errors: ['Sync already in progress'], direction: direction);
    }
    
    return await _reliableOps.withFallback(
      primary: () async {
        _isSyncing = true;
        notifyListeners();
        
        try {
          debugPrint('🔄 Starting manual sync with direction: $direction');
          
          final errors = <String>[];
          int itemsSynced = 0;
          
          if (!isOnline) {
            throw Exception('No internet connection available');
          }
          
          switch (direction) {
            case SyncDirection.localToRemote:
              itemsSynced = await _syncLocalToRemote(errors);
              break;
            case SyncDirection.remoteToLocal:
              itemsSynced = await _syncRemoteToLocal(errors);
              break;
            case SyncDirection.bidirectional:
              final upSynced = await _syncLocalToRemote(errors);
              final downSynced = await _syncRemoteToLocal(errors);
              itemsSynced = upSynced + downSynced;
              break;
          }
          
          _lastSyncTime = DateTime.now();
          _clearPendingOperations();
          
          final result = SyncResult(
            success: errors.isEmpty,
            itemsSynced: itemsSynced,
            errors: errors,
            direction: direction,
          );
          
          debugPrint('✅ Sync completed: $result');
          return result;
          
        } finally {
          _isSyncing = false;
          notifyListeners();
        }
      },
      fallback: () async {
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: false,
          itemsSynced: 0,
          errors: ['Sync operation failed'],
          direction: direction,
        );
      },
      operationName: 'sync_with_remote',
    );
  }
  
  /// Set sync strategy
  void setSyncStrategy(SyncStrategy strategy) {
    if (_currentStrategy != strategy) {
      debugPrint('📋 Changing sync strategy: $_currentStrategy → $strategy');
      _currentStrategy = strategy;
      
      // Clear cache when strategy changes
      _invalidateCache();
      
      notifyListeners();
    }
  }
  
  // ===== PRIVATE HELPER METHODS =====
  
  /// Load flashcard sets with local-first strategy
  Future<List<FlashcardSet>> _loadLocalFirst() async {
    try {
      // Try local storage first
      final localData = StorageService.getFlashcardSets();
      
      if (localData != null && localData.isNotEmpty) {
        final localSets = localData.map((json) => FlashcardSet.fromJson(json)).toList();
        debugPrint('✅ Loaded ${localSets.length} sets from local storage');
        
        // Background sync if online
        if (isOnline) {
          _performBackgroundSync();
        }
        
        return localSets;
      } else {
        debugPrint('📭 No local data found, trying remote...');
        return await _loadRemoteFirst();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading local data: $e');
      return await _loadRemoteFirst();
    }
  }
  
  /// Load flashcard sets with remote-first strategy
  Future<List<FlashcardSet>> _loadRemoteFirst() async {
    if (isOnline) {
      try {
        final remoteSets = await _remoteStorage.getFlashcardSets();
        debugPrint('✅ Loaded ${remoteSets.length} sets from remote storage');
        
        // Update local storage with remote data
        await StorageService.saveFlashcardSets(
          remoteSets.map((set) => set.toJson()).toList(),
        );
        
        return remoteSets;
      } catch (e) {
        debugPrint('⚠️ Error loading remote data: $e');
        return await _loadLocalOnly();
      }
    } else {
      return await _loadLocalOnly();
    }
  }
  
  /// Load flashcard sets from local storage only
  Future<List<FlashcardSet>> _loadLocalOnly() async {
    try {
      final localData = StorageService.getFlashcardSets();
      
      if (localData != null && localData.isNotEmpty) {
        final localSets = localData.map((json) => FlashcardSet.fromJson(json)).toList();
        debugPrint('✅ Loaded ${localSets.length} sets from local storage only');
        return localSets;
      } else {
        debugPrint('📭 No local data available');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error loading local data: $e');
      return [];
    }
  }
  
  /// Load flashcard sets for migration (includes legacy data migration)
  Future<List<FlashcardSet>> _loadForMigration() async {
    try {
      final localData = StorageService.getFlashcardSets();
      
      if (localData != null && localData.isNotEmpty) {
        final sets = <FlashcardSet>[];
        
        for (final json in localData) {
          try {
            // Check if this is legacy data that needs migration
            if (FlashcardSetMigrationHelper.needsMigration(json)) {
              debugPrint('🔄 Migrating legacy set: ${json['title']}');
              
              final legacySet = FlashcardSet.fromJson(json);
              final migratedSet = await _prepareSetForCurrentUser(legacySet);
              sets.add(migratedSet);
            } else {
              // Already migrated data
              sets.add(FlashcardSet.fromJson(json));
            }
          } catch (e) {
            debugPrint('⚠️ Error processing set during migration: $e');
          }
        }
        
        debugPrint('✅ Loaded ${sets.length} sets for migration');
        return sets;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error loading data for migration: $e');
      return [];
    }
  }
  
  /// Load categories from local storage
  Future<List<models.Category>> _loadLocalCategories() async {
    try {
      // Note: Categories are not currently stored locally in the original system
      // This is a placeholder for future local category caching
      debugPrint('📭 Local category storage not implemented, creating defaults');
      return _createDefaultCategories();
    } catch (e) {
      debugPrint('❌ Error loading local categories: $e');
      return _createDefaultCategories();
    }
  }
  
  /// Save categories to local storage
  Future<void> _saveLocalCategories(List<models.Category> categories) async {
    try {
      // Note: Placeholder for future local category caching
      debugPrint('💾 Local category storage not implemented');
    } catch (e) {
      debugPrint('❌ Error saving local categories: $e');
    }
  }
  
  /// Create default categories for current user
  List<models.Category> _createDefaultCategories() {
    if (_auth.isAuthenticated) {
      return CategoryMigrationHelper.createDefaultCategoriesForUser(_auth.currentUser!.id);
    } else if (_guestSession.currentSessionId != null) {
      return CategoryMigrationHelper.createDefaultCategoriesForGuest(_guestSession.currentSessionId!);
    } else {
      debugPrint('⚠️ No user or guest session available for default categories');
      return [];
    }
  }
  
  /// Prepare flashcard set for current user (handle ownership)
  Future<FlashcardSet> _prepareSetForCurrentUser(FlashcardSet set) async {
    if (_auth.isAuthenticated) {
      // Convert to authenticated user format
      return set.copyAsAuthenticatedUserData(_auth.currentUser!.id);
    } else if (_guestSession.currentSessionId != null) {
      // Convert to guest format
      return set.copyAsGuestData(_guestSession.currentSessionId!);
    } else {
      // No valid session, return as-is (will be handled by validation)
      return set;
    }
  }
  
  /// Prepare category for current user (handle ownership)
  Future<models.Category> _prepareCategoryForCurrentUser(models.Category category) async {
    if (_auth.isAuthenticated) {
      // Convert to authenticated user format
      return category.copyAsAuthenticatedUserData(_auth.currentUser!.id);
    } else if (_guestSession.currentSessionId != null) {
      // Convert to guest format
      return category.copyAsGuestData(_guestSession.currentSessionId!);
    } else {
      // No valid session, return as-is
      return category;
    }
  }
  
  /// Sync local data to remote storage
  Future<int> _syncLocalToRemote(List<String> errors) async {
    int itemsSynced = 0;
    
    try {
      // Sync flashcard sets
      final localSets = await _loadLocalOnly();
      
      for (final set in localSets) {
        try {
          await _remoteStorage.createFlashcardSet(set);
          itemsSynced++;
        } catch (e) {
          errors.add('Failed to sync set "${set.title}": $e');
        }
      }
      
      // Note: Categories sync would go here when local storage is implemented
      
      debugPrint('✅ Synced $itemsSynced items to remote');
    } catch (e) {
      errors.add('Local to remote sync failed: $e');
    }
    
    return itemsSynced;
  }
  
  /// Sync remote data to local storage
  Future<int> _syncRemoteToLocal(List<String> errors) async {
    int itemsSynced = 0;
    
    try {
      // Sync flashcard sets
      final remoteSets = await _remoteStorage.getFlashcardSets();
      
      if (remoteSets.isNotEmpty) {
        await StorageService.saveFlashcardSets(
          remoteSets.map((set) => set.toJson()).toList(),
        );
        itemsSynced += remoteSets.length;
      }
      
      // Note: Categories sync would go here when local storage is implemented
      
      debugPrint('✅ Synced $itemsSynced items from remote');
    } catch (e) {
      errors.add('Remote to local sync failed: $e');
    }
    
    return itemsSynced;
  }
  
  /// Perform background sync (non-blocking)
  void _performBackgroundSync() {
    if (_isSyncing || !isOnline) return;
    
    // Perform sync in background without blocking UI
    Future.delayed(Duration(milliseconds: 500), () async {
      try {
        await syncWithRemote(direction: SyncDirection.bidirectional);
      } catch (e) {
        debugPrint('⚠️ Background sync failed: $e');
      }
    });
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = isOnline;
    // Check if any connection type is available (not none)
    final isNowOnline = results.any((result) => result != ConnectivityResult.none) && _remoteStorage.isReady;
    
    if (!wasOnline && isNowOnline) {
      debugPrint('🌐 Connection restored, triggering background sync');
      _performBackgroundSync();
    } else if (wasOnline && !isNowOnline) {
      debugPrint('📱 Connection lost, switching to offline mode');
    }
    
    notifyListeners();
  }
  
  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }
  
  /// Invalidate cache
  void _invalidateCache() {
    _cachedSets = null;
    _cachedCategories = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ Cache invalidated');
  }
  
  /// Clear pending operations
  void _clearPendingOperations() {
    if (_pendingOperations.isNotEmpty) {
      debugPrint('✅ Cleared ${_pendingOperations.length} pending operations');
      _pendingOperations.clear();
    }
  }
  
  // ===== PUBLIC UTILITY METHODS =====
  
  /// Force refresh data (bypass cache)
  Future<void> refresh() async {
    _invalidateCache();
    notifyListeners();
    debugPrint('🔄 Forced refresh initiated');
  }
  
  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isOnline': isOnline,
      'isSyncing': _isSyncing,
      'strategy': _currentStrategy.toString(),
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'pendingOperations': _pendingOperations.length,
      'cacheValid': _isCacheValid(),
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
    };
  }
  
  /// Clear all local data (for testing/debugging)
  Future<void> clearLocalData() async {
    await _reliableOps.safely(
      operation: () async {
        await StorageService.clear();
        _invalidateCache();
        _clearPendingOperations();
        notifyListeners();
        debugPrint('🗑️ All local data cleared');
      },
      operationName: 'clear_local_data',
    );
  }
  
  /// Export sync diagnostics
  Map<String, dynamic> exportDiagnostics() {
    return {
      'service_info': {
        'initialized': _isInitialized,
        'online': isOnline,
        'syncing': _isSyncing,
        'strategy': _currentStrategy.toString(),
      },
      'sync_info': {
        'last_sync': _lastSyncTime?.toIso8601String(),
        'pending_operations': _pendingOperations.length,
        'pending_operations_list': _pendingOperations,
      },
      'cache_info': {
        'valid': _isCacheValid(),
        'timestamp': _cacheTimestamp?.toIso8601String(),
        'sets_cached': _cachedSets?.length,
        'categories_cached': _cachedCategories?.length,
      },
      'storage_info': {
        'local_ready': true, // StorageService is always ready
        'remote_ready': _remoteStorage.isReady,
        'auth_status': _auth.isAuthenticated,
        'guest_session': _guestSession.currentSessionId,
      },
    };
  }
}

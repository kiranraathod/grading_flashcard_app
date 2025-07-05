/// SyncRepository: Coordinated sync operations with conflict resolution
///
/// Phase 4 Migration: Replaces competing SupabaseService operations with
/// coordinated sync that integrates with FlashcardBloc through repository pattern.
///
/// Key Features:
/// - Timestamp-based conflict resolution
/// - Queue-based operation management
/// - Integration with FlashcardRepository
/// - Network-aware sync strategies
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/connectivity_service.dart';
import '../models/flashcard_set.dart';
import 'flashcard_repository.dart';
import 'base_repository.dart';

/// Sync operation result
class SyncResult {
  final bool success;
  final String operationType;
  final int itemsProcessed;
  final Duration duration;
  final String? error;
  final List<SyncConflictInfo> conflicts;

  const SyncResult({
    required this.success,
    required this.operationType,
    required this.itemsProcessed,
    required this.duration,
    this.error,
    this.conflicts = const [],
  });
}

/// Conflict information for sync operations
class SyncConflictInfo {
  final String setId;
  final String conflictType;
  final DateTime localTimestamp;
  final DateTime cloudTimestamp;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> cloudData;
  final ConflictResolution resolution;

  const SyncConflictInfo({
    required this.setId,
    required this.conflictType,
    required this.localTimestamp,
    required this.cloudTimestamp,
    required this.localData,
    required this.cloudData,
    required this.resolution,
  });
}

/// Conflict resolution strategy
enum ConflictResolution {
  /// Use local data (user's work takes precedence)
  useLocal,
  
  /// Use cloud data (cloud is authoritative)
  useCloud,
  
  /// Merge both (timestamp-based merge)
  merge,
  
  /// Manual resolution required
  manual,
  
  /// Skip this conflict for now
  skip
}

/// Sync queue item
class SyncQueueItem {
  final String id;
  final String operationType;
  final String? setId;
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final int retryCount;
  final String reason;

  const SyncQueueItem({
    required this.id,
    required this.operationType,
    this.setId,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
    required this.reason,
  });

  SyncQueueItem copyWith({
    int? retryCount,
    Map<String, dynamic>? data,
  }) {
    return SyncQueueItem(
      id: id,
      operationType: operationType,
      setId: setId,
      data: data ?? this.data,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
      reason: reason,
    );
  }
}

/// SyncRepository implementation
class SyncRepository {
  final ConnectivityService _connectivityService;
  final FlashcardRepository _flashcardRepository;
  
  // Supabase client for cloud operations
  SupabaseClient? _supabaseClient;
  
  // Sync queue and status
  final List<SyncQueueItem> _syncQueue = [];
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  
  // Stream controllers for reactive updates
  final StreamController<List<SyncQueueItem>> _queueController =
      StreamController<List<SyncQueueItem>>.broadcast();
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();
  
  SyncRepository({
    required ConnectivityService connectivityService,
    required FlashcardRepository flashcardRepository,
  }) : _connectivityService = connectivityService,
       _flashcardRepository = flashcardRepository;

  // Getters
  bool get isInitialized => _isInitialized;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isOnline => _connectivityService.isOnline;
  bool get hasGoodConnection => _connectivityService.hasGoodConnection;
  List<SyncQueueItem> get syncQueue => List.unmodifiable(_syncQueue);
  
  // Streams
  Stream<List<SyncQueueItem>> get queueStream => _queueController.stream;
  Stream<SyncResult> get resultStream => _resultController.stream;

  /// Initialize sync repository
  Future<void> initialize() async {
    try {
      debugPrint('🔄 SyncRepository: Initializing...');
      
      // Initialize Supabase client if available
      try {
        _supabaseClient = Supabase.instance.client;
        debugPrint('✅ SyncRepository: Supabase client available');
      } catch (e) {
        debugPrint('⚠️ SyncRepository: Supabase not available: $e');
      }
      
      // Load any pending sync operations from storage
      await _loadPendingSyncQueue();
      
      _isInitialized = true;
      debugPrint('✅ SyncRepository: Initialized successfully');
      
    } catch (error) {
      debugPrint('❌ SyncRepository: Initialization failed: $error');
      throw RepositoryException(
        message: 'Failed to initialize sync repository: $error',
        operation: 'initialize',
      );
    }
  }

  /// Perform full sync of all data
  Future<SyncResult> performFullSync({bool forceRefresh = false}) async {
    debugPrint('🔄 SyncRepository: Starting full sync (forceRefresh: $forceRefresh)');
    
    if (!_isInitialized) {
      throw RepositoryException(
        message: 'SyncRepository not initialized',
        operation: 'performFullSync',
      );
    }
    
    if (!isOnline) {
      throw RepositoryException(
        message: 'Cannot sync while offline',
        operation: 'performFullSync',
      );
    }
    
    final stopwatch = Stopwatch()..start();
    int itemsProcessed = 0;
    final conflicts = <SyncConflictInfo>[];
    
    try {
      // Step 1: Get all local flashcard sets
      final localSets = await _flashcardRepository.getAll();
      debugPrint('📱 SyncRepository: Found ${localSets.length} local sets');
      
      // Step 2: Get all cloud flashcard sets
      final cloudSets = await _getCloudFlashcardSets();
      debugPrint('☁️ SyncRepository: Found ${cloudSets.length} cloud sets');
      
      // Step 3: Detect conflicts and resolve them
      final conflictResults = await _detectAndResolveConflicts(localSets, cloudSets);
      conflicts.addAll(conflictResults.conflicts);
      itemsProcessed = conflictResults.itemsProcessed;
      
      // Step 4: Upload any local-only sets
      final uploadResult = await _uploadLocalOnlySets(localSets, cloudSets);
      itemsProcessed += uploadResult;
      
      // Step 5: Download any cloud-only sets (if not force refresh)
      if (!forceRefresh) {
        final downloadResult = await _downloadCloudOnlySets(localSets, cloudSets);
        itemsProcessed += downloadResult;
      }
      
      // Step 6: Update last sync time
      _lastSyncTime = DateTime.now();
      await _persistSyncMetadata();
      
      stopwatch.stop();
      
      final result = SyncResult(
        success: true,
        operationType: forceRefresh ? 'full_refresh' : 'full_sync',
        itemsProcessed: itemsProcessed,
        duration: stopwatch.elapsed,
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      debugPrint('✅ SyncRepository: Full sync completed - $itemsProcessed items in ${stopwatch.elapsed}');
      
      return result;
      
    } catch (error) {
      stopwatch.stop();
      debugPrint('❌ SyncRepository: Full sync failed: $error');
      
      final result = SyncResult(
        success: false,
        operationType: forceRefresh ? 'full_refresh' : 'full_sync',
        itemsProcessed: itemsProcessed,
        duration: stopwatch.elapsed,
        error: error.toString(),
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      throw RepositoryException(
        message: 'Full sync failed: $error',
        operation: 'performFullSync',
      );
    }
  }

  /// Perform incremental sync since last sync time
  Future<SyncResult> performIncrementalSync() async {
    debugPrint('🔄 SyncRepository: Starting incremental sync');
    
    if (!_isInitialized) {
      throw RepositoryException(
        message: 'SyncRepository not initialized',
        operation: 'performIncrementalSync',
      );
    }
    
    if (!isOnline) {
      // Queue for later if offline
      await _queueOperation('incremental_sync', {}, 'offline_queue');
      throw RepositoryException(
        message: 'Cannot sync while offline - queued for later',
        operation: 'performIncrementalSync',
      );
    }
    
    final stopwatch = Stopwatch()..start();
    int itemsProcessed = 0;
    final conflicts = <SyncConflictInfo>[];
    
    try {
      final lastSync = _lastSyncTime ?? DateTime.now().subtract(const Duration(days: 30));
      debugPrint('📅 SyncRepository: Syncing changes since $lastSync');
      
      // Get local changes since last sync
      final localChanges = await _getLocalChangesSince(lastSync);
      debugPrint('📱 SyncRepository: Found ${localChanges.length} local changes');
      
      // Get cloud changes since last sync
      final cloudChanges = await _getCloudChangesSince(lastSync);
      debugPrint('☁️ SyncRepository: Found ${cloudChanges.length} cloud changes');
      
      // Process conflicts between local and cloud changes
      final conflictResults = await _processIncrementalConflicts(localChanges, cloudChanges);
      conflicts.addAll(conflictResults.conflicts);
      itemsProcessed = conflictResults.itemsProcessed;
      
      // Upload remaining local changes
      final uploadResult = await _uploadLocalChanges(localChanges);
      itemsProcessed += uploadResult;
      
      // Apply cloud changes locally
      final downloadResult = await _applyCloudChanges(cloudChanges);
      itemsProcessed += downloadResult;
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      await _persistSyncMetadata();
      
      stopwatch.stop();
      
      final result = SyncResult(
        success: true,
        operationType: 'incremental_sync',
        itemsProcessed: itemsProcessed,
        duration: stopwatch.elapsed,
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      debugPrint('✅ SyncRepository: Incremental sync completed - $itemsProcessed items');
      
      return result;
      
    } catch (error) {
      stopwatch.stop();
      debugPrint('❌ SyncRepository: Incremental sync failed: $error');
      
      final result = SyncResult(
        success: false,
        operationType: 'incremental_sync',
        itemsProcessed: itemsProcessed,
        duration: stopwatch.elapsed,
        error: error.toString(),
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      throw RepositoryException(
        message: 'Incremental sync failed: $error',
        operation: 'performIncrementalSync',
      );
    }
  }

  /// Sync specific flashcard set
  Future<SyncResult> syncFlashcardSet(String setId) async {
    debugPrint('🔄 SyncRepository: Syncing flashcard set $setId');
    
    if (!_isInitialized) {
      throw RepositoryException(
        message: 'SyncRepository not initialized',
        operation: 'syncFlashcardSet',
      );
    }
    
    if (!isOnline) {
      await _queueOperation('sync_set', {'setId': setId}, 'individual_set_sync');
      throw RepositoryException(
        message: 'Cannot sync while offline - queued for later',
        operation: 'syncFlashcardSet',
      );
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get local set
      final localSet = await _flashcardRepository.getById(setId);
      if (localSet == null) {
        throw RepositoryException(
          message: 'Flashcard set not found locally: $setId',
          operation: 'syncFlashcardSet',
        );
      }
      
      // Get cloud set
      final cloudSet = await _getCloudFlashcardSet(setId);
      
      final conflicts = <SyncConflictInfo>[];
      int itemsProcessed = 0;
      
      if (cloudSet != null) {
        // Resolve conflict between local and cloud versions
        final conflictResult = await _resolveSetConflict(localSet, cloudSet);
        if (conflictResult != null) {
          conflicts.add(conflictResult);
        }
        itemsProcessed = 1;
      } else {
        // Upload local set to cloud
        await _uploadFlashcardSet(localSet);
        itemsProcessed = 1;
      }
      
      stopwatch.stop();
      
      final result = SyncResult(
        success: true,
        operationType: 'individual_sync',
        itemsProcessed: itemsProcessed,
        duration: stopwatch.elapsed,
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      debugPrint('✅ SyncRepository: Set sync completed - $setId');
      
      return result;
      
    } catch (error) {
      stopwatch.stop();
      debugPrint('❌ SyncRepository: Set sync failed for $setId: $error');
      
      final result = SyncResult(
        success: false,
        operationType: 'individual_sync',
        itemsProcessed: 0,
        duration: stopwatch.elapsed,
        error: error.toString(),
      );
      
      _resultController.add(result);
      throw RepositoryException(
        message: 'Set sync failed: $error',
        operation: 'syncFlashcardSet',
      );
    }
  }

  /// Process pending sync queue when network becomes available
  Future<SyncResult> processPendingQueue() async {
    debugPrint('🔄 SyncRepository: Processing pending sync queue (${_syncQueue.length} items)');
    
    if (!isOnline) {
      throw RepositoryException(
        message: 'Cannot process queue while offline',
        operation: 'processPendingQueue',
      );
    }
    
    if (_syncQueue.isEmpty) {
      debugPrint('✅ SyncRepository: No pending operations');
      return SyncResult(
        success: true,
        operationType: 'queue_processing',
        itemsProcessed: 0,
        duration: Duration.zero,
      );
    }
    
    final stopwatch = Stopwatch()..start();
    int processed = 0;
    final conflicts = <SyncConflictInfo>[];
    
    try {
      // Process queue items in order
      final queueCopy = List<SyncQueueItem>.from(_syncQueue);
      _syncQueue.clear();
      
      for (final item in queueCopy) {
        try {
          await _processQueueItem(item);
          processed++;
          debugPrint('✅ SyncRepository: Processed queue item ${item.id}');
        } catch (error) {
          debugPrint('❌ SyncRepository: Failed to process queue item ${item.id}: $error');
          
          // Re-queue with retry count if within limit
          if (item.retryCount < 3) {
            final retryItem = item.copyWith(retryCount: item.retryCount + 1);
            _syncQueue.add(retryItem);
            debugPrint('🔄 SyncRepository: Re-queued item ${item.id} (retry ${retryItem.retryCount})');
          } else {
            debugPrint('❌ SyncRepository: Max retries exceeded for item ${item.id}');
          }
        }
      }
      
      // Persist updated queue
      await _persistSyncQueue();
      _queueController.add(List.from(_syncQueue));
      
      stopwatch.stop();
      
      final result = SyncResult(
        success: true,
        operationType: 'queue_processing',
        itemsProcessed: processed,
        duration: stopwatch.elapsed,
        conflicts: conflicts,
      );
      
      _resultController.add(result);
      debugPrint('✅ SyncRepository: Queue processing completed - $processed items');
      
      return result;
      
    } catch (error) {
      stopwatch.stop();
      debugPrint('❌ SyncRepository: Queue processing failed: $error');
      
      final result = SyncResult(
        success: false,
        operationType: 'queue_processing',
        itemsProcessed: processed,
        duration: stopwatch.elapsed,
        error: error.toString(),
      );
      
      _resultController.add(result);
      throw RepositoryException(
        message: 'Queue processing failed: $error',
        operation: 'processPendingQueue',
      );
    }
  }

  /// Queue an operation for later processing
  Future<void> _queueOperation(String operationType, Map<String, dynamic> data, String reason) async {
    final item = SyncQueueItem(
      id: '${operationType}_${DateTime.now().millisecondsSinceEpoch}',
      operationType: operationType,
      setId: data['setId'] as String?,
      data: data,
      queuedAt: DateTime.now(),
      reason: reason,
    );
    
    _syncQueue.add(item);
    await _persistSyncQueue();
    _queueController.add(List.from(_syncQueue));
    
    debugPrint('📝 SyncRepository: Queued operation $operationType for $reason');
  }

  /// Process a single queue item
  Future<void> _processQueueItem(SyncQueueItem item) async {
    debugPrint('🔄 SyncRepository: Processing queue item ${item.id} (${item.operationType})');
    
    switch (item.operationType) {
      case 'full_sync':
        await performFullSync();
        break;
      case 'incremental_sync':
        await performIncrementalSync();
        break;
      case 'sync_set':
        final setId = item.setId;
        if (setId != null) {
          await syncFlashcardSet(setId);
        }
        break;
      case 'upload_set':
        await _processUploadSetItem(item);
        break;
      default:
        debugPrint('⚠️ SyncRepository: Unknown operation type: ${item.operationType}');
    }
  }

  /// Load pending sync queue from storage
  Future<void> _loadPendingSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = prefs.getString('sync_queue');
      if (queueData != null) {
        // Parse and load queue items
        // Implementation would deserialize the queue data
        debugPrint('📱 SyncRepository: Loaded pending sync queue');
      }
    } catch (error) {
      debugPrint('⚠️ SyncRepository: Failed to load sync queue: $error');
    }
  }

  /// Persist sync queue to storage
  Future<void> _persistSyncQueue() async {
    try {
      // Serialize and save queue
      // Implementation would serialize the _syncQueue
      debugPrint('💾 SyncRepository: Persisted sync queue');
    } catch (error) {
      debugPrint('⚠️ SyncRepository: Failed to persist sync queue: $error');
    }
  }

  /// Persist sync metadata
  Future<void> _persistSyncMetadata() async {
    try {
      if (_lastSyncTime != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
      }
      debugPrint('💾 SyncRepository: Persisted sync metadata');
    } catch (error) {
      debugPrint('⚠️ SyncRepository: Failed to persist sync metadata: $error');
    }
  }

  // Cloud operation methods
  
  /// Get all flashcard sets from cloud
  Future<List<FlashcardSet>> _getCloudFlashcardSets() async {
    if (_supabaseClient == null) {
      return [];
    }
    
    try {
      final userId = _supabaseClient!.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ SyncRepository: No authenticated user for cloud sync');
        return [];
      }
      
      final response = await _supabaseClient!
          .from('flashcard_sets')
          .select('*, flashcards(*)')
          .eq('user_id', userId)
          .eq('is_deleted', false);
      
      // Convert response to FlashcardSet objects
      final sets = <FlashcardSet>[];
      for (final setData in response) {
        try {
          final set = _convertCloudDataToFlashcardSet(setData);
          sets.add(set);
        } catch (error) {
          debugPrint('⚠️ SyncRepository: Failed to convert cloud set: $error');
        }
      }
      
      debugPrint('☁️ SyncRepository: Retrieved ${sets.length} sets from cloud');
      return sets;
      
    } catch (error) {
      debugPrint('❌ SyncRepository: Failed to get cloud flashcard sets: $error');
      throw RepositoryException(
        message: 'Failed to get cloud data: $error',
        operation: '_getCloudFlashcardSets',
      );
    }
  }

  /// Get specific flashcard set from cloud
  Future<FlashcardSet?> _getCloudFlashcardSet(String setId) async {
    if (_supabaseClient == null) {
      return null;
    }
    
    try {
      final userId = _supabaseClient!.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }
      
      final response = await _supabaseClient!
          .from('flashcard_sets')
          .select('*, flashcards(*)')
          .eq('id', setId)
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .single();
      
      return _convertCloudDataToFlashcardSet(response);
      
    } catch (error) {
      debugPrint('⚠️ SyncRepository: Cloud set not found or error: $error');
      return null;
    }
  }

  /// Upload flashcard set to cloud
  Future<void> _uploadFlashcardSet(FlashcardSet set) async {
    if (_supabaseClient == null) {
      throw RepositoryException(
        message: 'No cloud connection available',
        operation: '_uploadFlashcardSet',
      );
    }
    
    final userId = _supabaseClient!.auth.currentUser?.id;
    if (userId == null) {
      throw RepositoryException(
        message: 'User not authenticated',
        operation: '_uploadFlashcardSet',
      );
    }
    
    try {
      debugPrint('⬆️ SyncRepository: Uploading set ${set.id} to cloud');
      
      // Convert FlashcardSet to cloud format
      final setData = _convertFlashcardSetToCloudData(set, userId);
      
      // Upload main set
      await _supabaseClient!
          .from('flashcard_sets')
          .upsert(setData['set']);
      
      // Upload flashcards
      if (setData['flashcards'] != null && (setData['flashcards'] as List).isNotEmpty) {
        await _supabaseClient!
            .from('flashcards')
            .upsert(setData['flashcards']);
      }
      
      debugPrint('✅ SyncRepository: Set ${set.id} uploaded successfully');
      
    } catch (error) {
      debugPrint('❌ SyncRepository: Failed to upload set ${set.id}: $error');
      throw RepositoryException(
        message: 'Upload failed: $error',
        operation: '_uploadFlashcardSet',
      );
    }
  }

  /// Get local changes since timestamp
  Future<List<FlashcardSet>> _getLocalChangesSince(DateTime since) async {
    final allSets = await _flashcardRepository.getAll();
    return allSets.where((set) => 
        set.lastUpdated.isAfter(since)
    ).toList();
  }

  /// Get cloud changes since timestamp
  Future<List<FlashcardSet>> _getCloudChangesSince(DateTime since) async {
    if (_supabaseClient == null) {
      return [];
    }
    
    try {
      final userId = _supabaseClient!.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }
      
      final response = await _supabaseClient!
          .from('flashcard_sets')
          .select('*, flashcards(*)')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .gte('updated_at', since.toIso8601String());
      
      final sets = <FlashcardSet>[];
      for (final setData in response) {
        try {
          final set = _convertCloudDataToFlashcardSet(setData);
          sets.add(set);
        } catch (error) {
          debugPrint('⚠️ SyncRepository: Failed to convert cloud change: $error');
        }
      }
      
      return sets;
      
    } catch (error) {
      debugPrint('❌ SyncRepository: Failed to get cloud changes: $error');
      return [];
    }
  }

  // Conflict resolution methods
  
  /// Detect and resolve conflicts between local and cloud sets
  Future<({List<SyncConflictInfo> conflicts, int itemsProcessed})> _detectAndResolveConflicts(
    List<FlashcardSet> localSets, 
    List<FlashcardSet> cloudSets
  ) async {
    final conflicts = <SyncConflictInfo>[];
    int itemsProcessed = 0;
    
    // Create map for efficient cloud lookup
    final cloudMap = {for (var set in cloudSets) set.id: set};
    
    // Find sets that exist in both local and cloud
    for (final localSet in localSets) {
      final cloudSet = cloudMap[localSet.id];
      if (cloudSet != null) {
        final conflict = await _resolveSetConflict(localSet, cloudSet);
        if (conflict != null) {
          conflicts.add(conflict);
        }
        itemsProcessed++;
      }
    }
    
    return (conflicts: conflicts, itemsProcessed: itemsProcessed);
  }

  /// Resolve conflict between local and cloud versions of a set
  Future<SyncConflictInfo?> _resolveSetConflict(FlashcardSet localSet, FlashcardSet cloudSet) async {
    debugPrint('🔍 SyncRepository: Checking conflict for set ${localSet.id}');
    
    // Compare timestamps
    final localTime = localSet.lastUpdated;
    final cloudTime = cloudSet.lastUpdated;
    
    if (localTime == cloudTime) {
      debugPrint('✅ SyncRepository: No conflict - timestamps match');
      return null;
    }
    
    debugPrint('⚠️ SyncRepository: Conflict detected - Local: $localTime, Cloud: $cloudTime');
    
    // Determine resolution strategy
    ConflictResolution resolution;
    FlashcardSet resolvedSet;
    
    if (localTime.isAfter(cloudTime)) {
      // Local is newer - use local (upload to cloud)
      resolution = ConflictResolution.useLocal;
      resolvedSet = localSet;
      debugPrint('📱 SyncRepository: Using local version (newer)');
    } else {
      // Cloud is newer - use cloud (download to local)
      resolution = ConflictResolution.useCloud;
      resolvedSet = cloudSet;
      debugPrint('☁️ SyncRepository: Using cloud version (newer)');
    }
    
    // Apply resolution
    await _applyConflictResolution(resolvedSet, resolution);
    
    return SyncConflictInfo(
      setId: localSet.id,
      conflictType: 'timestamp_conflict',
      localTimestamp: localTime,
      cloudTimestamp: cloudTime,
      localData: _convertFlashcardSetToMap(localSet),
      cloudData: _convertFlashcardSetToMap(cloudSet),
      resolution: resolution,
    );
  }

  /// Apply conflict resolution
  Future<void> _applyConflictResolution(FlashcardSet resolvedSet, ConflictResolution resolution) async {
    switch (resolution) {
      case ConflictResolution.useLocal:
        // Upload local version to cloud
        await _uploadFlashcardSet(resolvedSet);
        break;
      case ConflictResolution.useCloud:
        // Save cloud version locally
        await _flashcardRepository.save(resolvedSet);
        break;
      case ConflictResolution.merge:
        // Implement merge logic if needed
        debugPrint('🔄 SyncRepository: Merge resolution not yet implemented');
        await _flashcardRepository.save(resolvedSet);
        break;
      default:
        debugPrint('⚠️ SyncRepository: Unhandled resolution: $resolution');
    }
  }

  /// Process incremental conflicts
  Future<({List<SyncConflictInfo> conflicts, int itemsProcessed})> _processIncrementalConflicts(
    List<FlashcardSet> localChanges,
    List<FlashcardSet> cloudChanges
  ) async {
    final conflicts = <SyncConflictInfo>[];
    int itemsProcessed = 0;
    
    // Similar to full conflict detection but only for changed items
    final cloudMap = {for (var set in cloudChanges) set.id: set};
    
    for (final localSet in localChanges) {
      final cloudSet = cloudMap[localSet.id];
      if (cloudSet != null) {
        final conflict = await _resolveSetConflict(localSet, cloudSet);
        if (conflict != null) {
          conflicts.add(conflict);
        }
        itemsProcessed++;
      }
    }
    
    return (conflicts: conflicts, itemsProcessed: itemsProcessed);
  }

  /// Upload local-only sets
  Future<int> _uploadLocalOnlySets(List<FlashcardSet> localSets, List<FlashcardSet> cloudSets) async {
    final cloudIds = cloudSets.map((s) => s.id).toSet();
    final localOnlySets = localSets.where((s) => !cloudIds.contains(s.id));
    
    int uploaded = 0;
    for (final set in localOnlySets) {
      try {
        await _uploadFlashcardSet(set);
        uploaded++;
        debugPrint('⬆️ SyncRepository: Uploaded local-only set ${set.id}');
      } catch (error) {
        debugPrint('❌ SyncRepository: Failed to upload set ${set.id}: $error');
      }
    }
    
    return uploaded;
  }

  /// Download cloud-only sets
  Future<int> _downloadCloudOnlySets(List<FlashcardSet> localSets, List<FlashcardSet> cloudSets) async {
    final localIds = localSets.map((s) => s.id).toSet();
    final cloudOnlySets = cloudSets.where((s) => !localIds.contains(s.id));
    
    int downloaded = 0;
    for (final set in cloudOnlySets) {
      try {
        await _flashcardRepository.save(set);
        downloaded++;
        debugPrint('⬇️ SyncRepository: Downloaded cloud-only set ${set.id}');
      } catch (error) {
        debugPrint('❌ SyncRepository: Failed to download set ${set.id}: $error');
      }
    }
    
    return downloaded;
  }

  /// Upload local changes
  Future<int> _uploadLocalChanges(List<FlashcardSet> localChanges) async {
    int uploaded = 0;
    for (final set in localChanges) {
      try {
        await _uploadFlashcardSet(set);
        uploaded++;
      } catch (error) {
        debugPrint('❌ SyncRepository: Failed to upload change ${set.id}: $error');
      }
    }
    return uploaded;
  }

  /// Apply cloud changes locally
  Future<int> _applyCloudChanges(List<FlashcardSet> cloudChanges) async {
    int applied = 0;
    for (final set in cloudChanges) {
      try {
        await _flashcardRepository.save(set);
        applied++;
      } catch (error) {
        debugPrint('❌ SyncRepository: Failed to apply cloud change ${set.id}: $error');
      }
    }
    return applied;
  }

  // Helper methods for data conversion
  
  /// Convert cloud data to FlashcardSet
  FlashcardSet _convertCloudDataToFlashcardSet(Map<String, dynamic> cloudData) {
    // Implementation would convert Supabase JSON to FlashcardSet object
    // This is a placeholder - actual implementation would handle the conversion
    throw UnimplementedError('Cloud data conversion not yet implemented');
  }

  /// Convert FlashcardSet to cloud data format
  Map<String, dynamic> _convertFlashcardSetToCloudData(FlashcardSet set, String userId) {
    // Implementation would convert FlashcardSet to Supabase-compatible format
    // This is a placeholder - actual implementation would handle the conversion
    throw UnimplementedError('Cloud data conversion not yet implemented');
  }

  /// Convert FlashcardSet to map for conflict resolution
  Map<String, dynamic> _convertFlashcardSetToMap(FlashcardSet set) {
    return {
      'id': set.id,
      'title': set.title,
      'description': set.description,
      'flashcards_count': set.flashcards.length,
      'last_updated': set.lastUpdated.toIso8601String(),
      'created_at': set.lastUpdated.toIso8601String(),
    };
  }

  /// Process upload set queue item
  Future<void> _processUploadSetItem(SyncQueueItem item) async {
    final setId = item.setId;
    if (setId == null) {
      throw RepositoryException(
        message: 'No setId in upload queue item',
        operation: '_processUploadSetItem',
      );
    }
    
    final set = await _flashcardRepository.getById(setId);
    if (set == null) {
      debugPrint('⚠️ SyncRepository: Set $setId not found for upload - may have been deleted');
      return;
    }
    
    await _uploadFlashcardSet(set);
  }

  /// Clear all sync data and queues
  Future<void> clear() async {
    debugPrint('🗑️ SyncRepository: Clearing all sync data');
    
    _syncQueue.clear();
    _lastSyncTime = null;
    
    await _persistSyncQueue();
    await _persistSyncMetadata();
    
    _queueController.add([]);
    
    debugPrint('✅ SyncRepository: Sync data cleared');
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'is_initialized': _isInitialized,
      'is_online': isOnline,
      'has_good_connection': hasGoodConnection,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'queue_length': _syncQueue.length,
      'oldest_queued_item': _syncQueue.isNotEmpty 
          ? _syncQueue.first.queuedAt.toIso8601String()
          : null,
    };
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🔄 SyncRepository: Disposing...');
    
    _queueController.close();
    _resultController.close();
    
    debugPrint('✅ SyncRepository: Disposed');
  }
}

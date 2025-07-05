/// SyncBloc: Coordinated sync operations with conflict resolution
///
/// Phase 4 Migration: Replaces competing SupabaseService operations with
/// coordinated sync that integrates with FlashcardBloc and NetworkBloc.
///
/// Key Features:
/// - Coordinates with FlashcardBloc for single source of truth
/// - Network-aware sync operations via NetworkBloc
/// - Queue-based operation management for offline scenarios
/// - Timestamp-based conflict resolution
/// - Eliminates competing periodic syncs
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../flashcard/flashcard_bloc.dart';
import '../flashcard/flashcard_event.dart' as flashcard_events;
import '../network/network_bloc.dart';
import '../network/network_state.dart' as network_states;
import '../../repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// SyncBloc - Coordinated sync operations
///
/// This BLoC coordinates all sync operations and maintains consistent
/// sync state across the application. It integrates with FlashcardBloc
/// to maintain single source of truth and eliminates race conditions.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository _syncRepository;
  final FlashcardBloc _flashcardBloc;
  final NetworkBloc _networkBloc;

  // Stream subscriptions for cleanup
  StreamSubscription<SyncResult>? _syncResultSubscription;
  StreamSubscription<List<SyncQueueItem>>? _queueSubscription;
  StreamSubscription<network_states.NetworkState>? _networkSubscription;
  
  // Periodic sync timer (replaces SupabaseService timer)
  Timer? _periodicSyncTimer;
  
  // Configuration
  static const Duration periodicSyncInterval = Duration(minutes: 15); // Less aggressive than before
  bool _automaticSyncEnabled = true;
  
  SyncBloc({
    required SyncRepository syncRepository,
    required FlashcardBloc flashcardBloc,
    required NetworkBloc networkBloc,
  }) : _syncRepository = syncRepository,
       _flashcardBloc = flashcardBloc,
       _networkBloc = networkBloc,
       super(const SyncInitial()) {
    
    // Register event handlers
    on<SyncInitialized>(_onInitialized);
    on<SyncRequested>(_onSyncRequested);
    on<SyncFlashcardSetRequested>(_onFlashcardSetSyncRequested);
    on<SyncNetworkStatusChanged>(_onNetworkStatusChanged);
    on<SyncPendingOperationsRequested>(_onPendingOperationsRequested);
    on<SyncConflictResolutionRequested>(_onConflictResolutionRequested);
    on<SyncAutomaticSyncPaused>(_onAutomaticSyncPaused);
    on<SyncAutomaticSyncResumed>(_onAutomaticSyncResumed);
    on<SyncErrorCleared>(_onErrorCleared);
    on<SyncProgressUpdated>(_onProgressUpdated);
    on<SyncOperationCompleted>(_onOperationCompleted);
    on<SyncOperationFailed>(_onOperationFailed);
    on<SyncPeriodicSyncScheduled>(_onPeriodicSyncScheduled);
    on<SyncBackgroundProcessingRequested>(_onBackgroundProcessingRequested);
    
    // Set up repository and network listeners
    _setupRepositoryListeners();
    _setupNetworkListeners();
  }

  /// Set up listeners for repository updates
  void _setupRepositoryListeners() {
    // Listen to sync results
    _syncResultSubscription = _syncRepository.resultStream.listen(
      (result) {
        debugPrint('🔄 SyncBloc: Sync result received - ${result.operationType}');
        
        if (result.success) {
          add(
            SyncOperationCompleted(
              operationType: result.operationType,
              itemsProcessed: result.itemsProcessed,
              duration: result.duration,
            ),
          );
        } else {
          add(
            SyncOperationFailed(
              operationType: result.operationType,
              error: result.error ?? 'Unknown error',
              canRetry: true,
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('❌ SyncBloc: Repository error - $error');
        add(
          SyncOperationFailed(
            operationType: 'repository_stream',
            error: error.toString(),
            canRetry: false,
          ),
        );
      },
    );
    
    // Listen to queue changes
    _queueSubscription = _syncRepository.queueStream.listen(
      (queue) {
        debugPrint('📝 SyncBloc: Queue updated - ${queue.length} items');
        
        // Update state if we're in an idle state
        if (state is SyncIdle) {
          final currentState = state as SyncIdle;
          final queueIds = queue.map((item) => item.id).toList();
          
          // Don't emit if queue hasn't actually changed
          if (!_listEquals(currentState.pendingSyncQueue, queueIds)) {
            // Use add() instead of emit() when outside event handlers
            add(SyncProgressUpdated(completed: queue.length, total: queue.length));
          }
        }
      },
    );
  }

  /// Set up listeners for network status changes
  void _setupNetworkListeners() {
    _networkSubscription = _networkBloc.stream.listen(
      (networkState) {
        if (networkState is network_states.NetworkMonitoring) {
          // Network status changed - inform sync
          add(
            SyncNetworkStatusChanged(
              isOnline: networkState.isOnline,
              hasGoodConnection: networkState.isSuitableForSync,
            ),
          );
        }
      },
    );
  }

  /// Initialize sync operations
  Future<void> _onInitialized(
    SyncInitialized event,
    Emitter<SyncState> emit,
  ) async {
    debugPrint('🔄 SyncBloc: Initializing sync operations...');
    
    try {
      // Initialize sync repository
      await _syncRepository.initialize();
      
      // Get initial network status
      final isOnline = _networkBloc.isOnline;
      final hasGoodConnection = _networkBloc.isSuitableForSync;
      
      debugPrint('🔄 SyncBloc: Initial network status - Online: $isOnline, Good: $hasGoodConnection');
      
      // Start with idle state
      emit(
        SyncIdle(
          lastSyncTime: _syncRepository.lastSyncTime,
          isOnline: isOnline,
          automaticSyncEnabled: _automaticSyncEnabled,
          pendingSyncQueue: _syncRepository.syncQueue.map((item) => item.id).toList(),
        ),
      );
      
      // Start periodic sync if online and enabled
      if (_automaticSyncEnabled && isOnline) {
        _startPeriodicSync();
      }
      
      // Process pending queue if online
      if (isOnline && _syncRepository.syncQueue.isNotEmpty) {
        add(const SyncPendingOperationsRequested());
      }
      
      debugPrint('✅ SyncBloc: Sync operations initialized successfully');
      
    } catch (error) {
      debugPrint('❌ SyncBloc: Failed to initialize sync operations: $error');
      emit(
        SyncError(
          operationType: SyncOperationType.full,
          error: 'Failed to initialize sync: $error',
          errorTime: DateTime.now(),
          canRetry: true,
          isOnline: _networkBloc.isOnline,
        ),
      );
    }
  }

  /// Handle sync requests
  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    debugPrint('🔄 SyncBloc: Sync requested - Force: ${event.forceRefresh}, Reason: ${event.reason}');
    
    // Check if we can sync
    if (!_networkBloc.isOnline) {
      debugPrint('📱 SyncBloc: Cannot sync - offline. Emitting offline state.');
      emit(
        SyncOffline(
          offlineSince: DateTime.now(),
          pendingOperations: _syncRepository.syncQueue.map((item) => item.id).toList(),
        ),
      );
      return;
    }
    
    if (!_networkBloc.isSuitableForSync) {
      debugPrint('⚠️ SyncBloc: Network quality not suitable for sync');
      emit(
        SyncError(
          operationType: event.forceRefresh ? SyncOperationType.download : SyncOperationType.full,
          error: 'Network quality too poor for sync operations',
          errorTime: DateTime.now(),
          canRetry: true,
          isOnline: true,
        ),
      );
      return;
    }
    
    // Start sync operation
    emit(
      SyncInProgress(
        operationType: event.forceRefresh ? SyncOperationType.download : SyncOperationType.full,
        progress: 0,
        total: 100, // Will be updated during sync
        startTime: DateTime.now(),
        isOnline: true,
      ),
    );
    
    try {
      // Perform sync through repository
      if (event.forceRefresh) {
        await _syncRepository.performFullSync(forceRefresh: true);
      } else {
        // Check if we should do full or incremental sync
        final lastSync = _syncRepository.lastSyncTime;
        if (lastSync == null || DateTime.now().difference(lastSync).inDays > 1) {
          await _syncRepository.performFullSync();
        } else {
          await _syncRepository.performIncrementalSync();
        }
      }
      
      // Success will be handled by _onOperationCompleted via repository stream
      
    } catch (error) {
      debugPrint('❌ SyncBloc: Sync operation failed: $error');
      // Error will be handled by _onOperationFailed via repository stream
    }
  }

  /// Handle flashcard set sync requests
  Future<void> _onFlashcardSetSyncRequested(
    SyncFlashcardSetRequested event,
    Emitter<SyncState> emit,
  ) async {
    debugPrint('🔄 SyncBloc: Flashcard set sync requested - ${event.setId}');
    
    if (!_networkBloc.isOnline) {
      debugPrint('📱 SyncBloc: Cannot sync set - offline. Queuing for later.');
      // This will be queued by the repository
      try {
        await _syncRepository.syncFlashcardSet(event.setId);
      } catch (error) {
        // Expected to fail offline - will be queued
        debugPrint('📝 SyncBloc: Set sync queued due to offline state');
      }
      return;
    }
    
    // Start individual sync operation
    emit(
      SyncInProgress(
        operationType: SyncOperationType.individual,
        progress: 0,
        total: 1,
        currentOperation: 'Syncing ${event.setId}',
        startTime: DateTime.now(),
        isOnline: true,
      ),
    );
    
    try {
      await _syncRepository.syncFlashcardSet(event.setId);
      // Success will be handled by repository stream
      
    } catch (error) {
      debugPrint('❌ SyncBloc: Set sync failed: $error');
      // Error will be handled by repository stream
    }
  }

  /// Handle network status changes
  void _onNetworkStatusChanged(
    SyncNetworkStatusChanged event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('🌐 SyncBloc: Network status changed - Online: ${event.isOnline}, Good: ${event.hasGoodConnection}');
    
    if (event.isOnline && !_wasOnline()) {
      // Just came online - process pending operations
      debugPrint('🌐 SyncBloc: Network came online - processing pending operations');
      add(const SyncPendingOperationsRequested());
      
      // Restart periodic sync if enabled
      if (_automaticSyncEnabled) {
        _startPeriodicSync();
      }
    } else if (!event.isOnline && _wasOnline()) {
      // Just went offline
      debugPrint('📱 SyncBloc: Network went offline');
      _stopPeriodicSync();
      
      emit(
        SyncOffline(
          offlineSince: DateTime.now(),
          pendingOperations: _syncRepository.syncQueue.map((item) => item.id).toList(),
        ),
      );
    }
    
    // Update current state with network info if in idle state
    if (state is SyncIdle) {
      final currentState = state as SyncIdle;
      emit(currentState.copyWith(isOnline: event.isOnline));
    }
  }

  /// Handle pending operations processing
  Future<void> _onPendingOperationsRequested(
    SyncPendingOperationsRequested event,
    Emitter<SyncState> emit,
  ) async {
    debugPrint('📝 SyncBloc: Processing pending operations...');
    
    if (!_networkBloc.isOnline) {
      debugPrint('📱 SyncBloc: Cannot process pending - still offline');
      return;
    }
    
    if (_syncRepository.syncQueue.isEmpty) {
      debugPrint('✅ SyncBloc: No pending operations to process');
      return;
    }
    
    emit(
      SyncInProgress(
        operationType: SyncOperationType.upload,
        progress: 0,
        total: _syncRepository.syncQueue.length,
        currentOperation: 'Processing pending operations',
        startTime: DateTime.now(),
        isOnline: true,
      ),
    );
    
    try {
      await _syncRepository.processPendingQueue();
      // Success will be handled by repository stream
      
    } catch (error) {
      debugPrint('❌ SyncBloc: Pending operations processing failed: $error');
      // Error will be handled by repository stream
    }
  }

  /// Handle conflict resolution requests
  Future<void> _onConflictResolutionRequested(
    SyncConflictResolutionRequested event,
    Emitter<SyncState> emit,
  ) async {
    debugPrint('🔍 SyncBloc: Conflict resolution requested for ${event.setId}');
    
    // This is a placeholder for manual conflict resolution
    // In a full implementation, this would present conflicts to the user
    // For now, we'll use automatic timestamp-based resolution
    
    emit(
      SyncInProgress(
        operationType: SyncOperationType.conflictResolution,
        progress: 0,
        total: 1,
        currentOperation: 'Resolving conflicts for ${event.setId}',
        startTime: DateTime.now(),
        isOnline: _networkBloc.isOnline,
      ),
    );
    
    try {
      // Automatic resolution: use newer timestamp
      final localTime = DateTime.tryParse(event.localData['last_updated'] ?? '');
      final cloudTime = DateTime.tryParse(event.cloudData['last_updated'] ?? '');
      
      if (localTime != null && cloudTime != null) {
        if (localTime.isAfter(cloudTime)) {
          debugPrint('📱 SyncBloc: Using local version (newer)');
          // Upload local version
          await _syncRepository.syncFlashcardSet(event.setId);
        } else {
          debugPrint('☁️ SyncBloc: Using cloud version (newer)');
          // Download cloud version - this would need FlashcardBloc coordination
          _flashcardBloc.add(flashcard_events.FlashcardRefreshRequested());
        }
      }
      
      // Success will be handled by repository stream
      
    } catch (error) {
      debugPrint('❌ SyncBloc: Conflict resolution failed: $error');
      // Error will be handled by repository stream
    }
  }

  /// Handle pause automatic sync
  void _onAutomaticSyncPaused(
    SyncAutomaticSyncPaused event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('⏸️ SyncBloc: Automatic sync paused');
    
    _automaticSyncEnabled = false;
    _stopPeriodicSync();
    
    emit(
      SyncPaused(
        pausedAt: DateTime.now(),
        reason: 'User requested pause',
        isOnline: _networkBloc.isOnline,
      ),
    );
  }

  /// Handle resume automatic sync
  void _onAutomaticSyncResumed(
    SyncAutomaticSyncResumed event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('▶️ SyncBloc: Automatic sync resumed');
    
    _automaticSyncEnabled = true;
    
    // Return to idle state
    emit(
      SyncIdle(
        lastSyncTime: _syncRepository.lastSyncTime,
        isOnline: _networkBloc.isOnline,
        automaticSyncEnabled: true,
        pendingSyncQueue: _syncRepository.syncQueue.map((item) => item.id).toList(),
      ),
    );
    
    // Start periodic sync if online
    if (_networkBloc.isOnline) {
      _startPeriodicSync();
    }
  }

  /// Handle error cleared
  void _onErrorCleared(
    SyncErrorCleared event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('🔄 SyncBloc: Error cleared, returning to idle');
    
    emit(
      SyncIdle(
        lastSyncTime: _syncRepository.lastSyncTime,
        isOnline: _networkBloc.isOnline,
        automaticSyncEnabled: _automaticSyncEnabled,
        pendingSyncQueue: _syncRepository.syncQueue.map((item) => item.id).toList(),
      ),
    );
  }

  /// Handle progress updates during sync operations
  void _onProgressUpdated(
    SyncProgressUpdated event,
    Emitter<SyncState> emit,
  ) {
    if (state is SyncInProgress) {
      final currentState = state as SyncInProgress;
      emit(
        currentState.copyWith(
          progress: event.completed,
          total: event.total,
          currentOperation: event.currentOperation,
        ),
      );
      
      debugPrint(
        '📊 SyncBloc: Progress updated - ${event.completed}/${event.total} (${event.currentOperation})',
      );
    }
  }

  /// Handle successful operation completion
  void _onOperationCompleted(
    SyncOperationCompleted event,
    Emitter<SyncState> emit,
  ) {
    debugPrint(
      '✅ SyncBloc: Operation completed - ${event.operationType} (${event.itemsProcessed} items in ${event.duration})',
    );
    
    emit(
      SyncSuccess(
        operationType: _parseOperationType(event.operationType),
        completedAt: DateTime.now(),
        itemsProcessed: event.itemsProcessed,
        duration: event.duration,
        isOnline: _networkBloc.isOnline,
        summary: '${event.operationType}: ${event.itemsProcessed} items processed',
      ),
    );
    
    // Return to idle state after a brief moment
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) {
        add(const SyncErrorCleared()); // Reuse this event to return to idle
      }
    });
    
    // 🎯 CRITICAL: Coordinate with FlashcardBloc to refresh data
    // This ensures single source of truth is maintained
    debugPrint('🔄 SyncBloc: Coordinating with FlashcardBloc to refresh data...');
    _flashcardBloc.add(flashcard_events.FlashcardRefreshRequested());
  }

  /// Handle operation failures
  void _onOperationFailed(
    SyncOperationFailed event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('❌ SyncBloc: Operation failed - ${event.operationType}: ${event.error}');
    
    emit(
      SyncError(
        operationType: _parseOperationType(event.operationType),
        error: event.error,
        errorTime: DateTime.now(),
        canRetry: event.canRetry,
        isOnline: _networkBloc.isOnline,
        debugInfo: 'Operation: ${event.operationType}, Retry: ${event.canRetry}',
      ),
    );
  }

  /// Handle periodic sync scheduling
  void _onPeriodicSyncScheduled(
    SyncPeriodicSyncScheduled event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('⏰ SyncBloc: Periodic sync triggered');
    
    // Only proceed if automatic sync is enabled and we're online
    if (!_automaticSyncEnabled || !_networkBloc.isOnline) {
      debugPrint('⏰ SyncBloc: Skipping periodic sync - disabled or offline');
      return;
    }
    
    // Only do incremental sync for periodic operations to be less aggressive
    add(const SyncRequested(forceRefresh: false, reason: 'periodic_sync'));
  }

  /// Handle background processing requests
  void _onBackgroundProcessingRequested(
    SyncBackgroundProcessingRequested event,
    Emitter<SyncState> emit,
  ) {
    debugPrint('🔄 SyncBloc: Background processing requested');
    
    // Process pending operations if suitable for background work
    if (_networkBloc.isSuitableForBackground && _syncRepository.syncQueue.isNotEmpty) {
      add(const SyncPendingOperationsRequested());
    }
  }

  // Helper methods

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Ensure no duplicate timers
    
    debugPrint('⏰ SyncBloc: Starting periodic sync (every ${periodicSyncInterval.inMinutes} minutes)');
    
    _periodicSyncTimer = Timer.periodic(periodicSyncInterval, (_) {
      if (_automaticSyncEnabled && _networkBloc.isOnline) {
        add(const SyncPeriodicSyncScheduled());
      }
    });
  }

  /// Stop periodic sync timer
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('⏰ SyncBloc: Periodic sync stopped');
  }

  /// Check if network was previously online
  bool _wasOnline() {
    if (state is SyncIdle) {
      return (state as SyncIdle).isOnline;
    } else if (state is SyncInProgress) {
      return (state as SyncInProgress).isOnline;
    } else if (state is SyncSuccess) {
      return (state as SyncSuccess).isOnline;
    } else if (state is SyncError) {
      return (state as SyncError).isOnline;
    }
    return false;
  }

  /// Parse operation type string to enum
  SyncOperationType _parseOperationType(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'full_sync':
      case 'full_refresh':
        return SyncOperationType.full;
      case 'incremental_sync':
        return SyncOperationType.incremental;
      case 'upload':
      case 'queue_processing':
        return SyncOperationType.upload;
      case 'download':
        return SyncOperationType.download;
      case 'individual_sync':
      case 'sync_set':
        return SyncOperationType.individual;
      case 'conflict_resolution':
        return SyncOperationType.conflictResolution;
      default:
        return SyncOperationType.full;
    }
  }

  /// Helper to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Public helper methods for external access

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final repoStats = _syncRepository.getSyncStatistics();
    
    return {
      ...repoStats,
      'automatic_sync_enabled': _automaticSyncEnabled,
      'periodic_sync_interval_minutes': periodicSyncInterval.inMinutes,
      'current_state': state.runtimeType.toString(),
      'network_online': _networkBloc.isOnline,
      'network_suitable_for_sync': _networkBloc.isSuitableForSync,
    };
  }

  /// Check if currently syncing
  bool get isCurrentlySyncing => state is SyncInProgress;

  /// Check if sync is paused
  bool get isSyncPaused => state is SyncPaused;

  /// Check if there are pending operations
  bool get hasPendingOperations => _syncRepository.syncQueue.isNotEmpty;

  /// Get last sync time
  DateTime? get lastSyncTime => _syncRepository.lastSyncTime;

  /// Force immediate sync
  void forceSync({bool forceRefresh = false}) {
    add(SyncRequested(forceRefresh: forceRefresh, reason: 'manual_force_sync'));
  }

  /// Sync specific flashcard set
  void syncFlashcardSet(String setId) {
    add(SyncFlashcardSetRequested(setId: setId, reason: 'manual_set_sync'));
  }

  /// Pause automatic sync
  void pauseAutomaticSync() {
    add(const SyncAutomaticSyncPaused());
  }

  /// Resume automatic sync
  void resumeAutomaticSync() {
    add(const SyncAutomaticSyncResumed());
  }

  /// Clear sync errors
  void clearErrors() {
    add(const SyncErrorCleared());
  }

  /// Process pending operations
  void processPendingOperations() {
    add(const SyncPendingOperationsRequested());
  }

  // Dispose and cleanup

  @override
  Future<void> close() async {
    debugPrint('🔄 SyncBloc: Disposing...');

    // Stop periodic sync
    _stopPeriodicSync();

    // Cancel stream subscriptions
    await _syncResultSubscription?.cancel();
    await _queueSubscription?.cancel();
    await _networkSubscription?.cancel();

    // Dispose repository
    _syncRepository.dispose();

    debugPrint('✅ SyncBloc: Disposed successfully');

    return super.close();
  }
}

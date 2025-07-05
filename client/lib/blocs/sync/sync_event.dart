/// Sync Events for coordinated synchronization operations
///
/// Phase 4 Migration: Replace competing sync operations with coordinated BLoC pattern.
/// Extends the proven coordination pattern from Phase 2-3 to sync operations.
library;

import 'package:equatable/equatable.dart';

/// Base sync event
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize sync service and check current state
class SyncInitialized extends SyncEvent {
  const SyncInitialized();
}

/// Request immediate sync of all data
class SyncRequested extends SyncEvent {
  /// Force full refresh from cloud (overwrite local)
  final bool forceRefresh;
  
  /// Reason for sync (for debugging and logging)
  final String reason;

  const SyncRequested({
    this.forceRefresh = false, 
    this.reason = 'manual_request',
  });

  @override
  List<Object?> get props => [forceRefresh, reason];
}

/// Request sync of specific flashcard set
class SyncFlashcardSetRequested extends SyncEvent {
  final String setId;
  final String reason;

  const SyncFlashcardSetRequested({
    required this.setId,
    this.reason = 'individual_set_sync',
  });

  @override
  List<Object?> get props => [setId, reason];
}

/// Handle network status changes from ConnectivityBloc
class SyncNetworkStatusChanged extends SyncEvent {
  final bool isOnline;
  final bool hasGoodConnection;

  const SyncNetworkStatusChanged({
    required this.isOnline,
    required this.hasGoodConnection,
  });

  @override
  List<Object?> get props => [isOnline, hasGoodConnection];
}

/// Process pending sync operations when network becomes available
class SyncPendingOperationsRequested extends SyncEvent {
  const SyncPendingOperationsRequested();
}

/// Handle conflict resolution for sync operations
class SyncConflictResolutionRequested extends SyncEvent {
  final String setId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> cloudData;
  final String conflictType;

  const SyncConflictResolutionRequested({
    required this.setId,
    required this.localData,
    required this.cloudData,
    required this.conflictType,
  });

  @override
  List<Object?> get props => [setId, localData, cloudData, conflictType];
}

/// Pause automatic sync operations
class SyncAutomaticSyncPaused extends SyncEvent {
  const SyncAutomaticSyncPaused();
}

/// Resume automatic sync operations
class SyncAutomaticSyncResumed extends SyncEvent {
  const SyncAutomaticSyncResumed();
}

/// Clear sync errors and reset to idle state
class SyncErrorCleared extends SyncEvent {
  const SyncErrorCleared();
}

/// Update sync progress (internal event from repository)
class SyncProgressUpdated extends SyncEvent {
  final int completed;
  final int total;
  final String? currentOperation;

  const SyncProgressUpdated({
    required this.completed,
    required this.total,
    this.currentOperation,
  });

  @override
  List<Object?> get props => [completed, total, currentOperation];
}

/// Sync operation completed successfully
class SyncOperationCompleted extends SyncEvent {
  final String operationType;
  final int itemsProcessed;
  final Duration duration;

  const SyncOperationCompleted({
    required this.operationType,
    required this.itemsProcessed,
    required this.duration,
  });

  @override
  List<Object?> get props => [operationType, itemsProcessed, duration];
}

/// Sync operation failed
class SyncOperationFailed extends SyncEvent {
  final String operationType;
  final String error;
  final bool canRetry;

  const SyncOperationFailed({
    required this.operationType,
    required this.error,
    required this.canRetry,
  });

  @override
  List<Object?> get props => [operationType, error, canRetry];
}

/// Schedule periodic sync (replaces timer-based approach)
class SyncPeriodicSyncScheduled extends SyncEvent {
  const SyncPeriodicSyncScheduled();
}

/// Process background sync queue
class SyncBackgroundProcessingRequested extends SyncEvent {
  const SyncBackgroundProcessingRequested();
}

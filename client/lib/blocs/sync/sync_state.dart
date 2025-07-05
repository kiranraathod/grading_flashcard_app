/// Sync States for coordinated synchronization operations
///
/// Phase 4 Migration: Provides unified sync state management to coordinate
/// with FlashcardBloc and eliminate competing sync operations.
library;

import 'package:equatable/equatable.dart';

/// Sync status enumeration
enum SyncStatus {
  /// Initial state - not yet initialized
  initial,
  
  /// Idle - ready for sync operations
  idle,
  
  /// Currently syncing data
  syncing,
  
  /// Sync completed successfully
  synced,
  
  /// Sync failed with recoverable error
  error,
  
  /// Network is offline
  offline,
  
  /// Conflict detected - manual resolution may be needed
  conflict,
  
  /// Paused by user or system
  paused
}

/// Sync operation type
enum SyncOperationType {
  /// Full sync of all data
  full,
  
  /// Incremental sync since last operation
  incremental,
  
  /// Upload only local changes
  upload,
  
  /// Download only cloud changes
  download,
  
  /// Individual flashcard set sync
  individual,
  
  /// Conflict resolution sync
  conflictResolution
}

/// Sync conflict information
class SyncConflict {
  final String setId;
  final String conflictType;
  final DateTime localTimestamp;
  final DateTime cloudTimestamp;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> cloudData;
  final String? resolution;

  const SyncConflict({
    required this.setId,
    required this.conflictType,
    required this.localTimestamp,
    required this.cloudTimestamp,
    required this.localData,
    required this.cloudData,
    this.resolution,
  });
}

/// Base sync state
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Initial state - sync not yet initialized
class SyncInitial extends SyncState {
  const SyncInitial();
}

/// Idle state - ready for sync operations
class SyncIdle extends SyncState {
  final DateTime? lastSyncTime;
  final bool isOnline;
  final bool automaticSyncEnabled;
  final List<String> pendingSyncQueue;

  const SyncIdle({
    this.lastSyncTime,
    this.isOnline = false,
    this.automaticSyncEnabled = true,
    this.pendingSyncQueue = const [],
  });

  @override
  List<Object?> get props => [
    lastSyncTime,
    isOnline,
    automaticSyncEnabled,
    pendingSyncQueue,
  ];

  SyncIdle copyWith({
    DateTime? lastSyncTime,
    bool? isOnline,
    bool? automaticSyncEnabled,
    List<String>? pendingSyncQueue,
  }) {
    return SyncIdle(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
      automaticSyncEnabled: automaticSyncEnabled ?? this.automaticSyncEnabled,
      pendingSyncQueue: pendingSyncQueue ?? this.pendingSyncQueue,
    );
  }
}

/// Currently syncing - operation in progress
class SyncInProgress extends SyncState {
  final SyncOperationType operationType;
  final int progress;
  final int total;
  final String? currentOperation;
  final DateTime startTime;
  final bool isOnline;

  const SyncInProgress({
    required this.operationType,
    required this.progress,
    required this.total,
    this.currentOperation,
    required this.startTime,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [
    operationType,
    progress,
    total,
    currentOperation,
    startTime,
    isOnline,
  ];

  /// Calculate progress percentage
  double get progressPercentage {
    if (total == 0) return 0.0;
    return (progress / total * 100).clamp(0.0, 100.0);
  }

  /// Get elapsed time since start
  Duration get elapsedTime => DateTime.now().difference(startTime);

  SyncInProgress copyWith({
    SyncOperationType? operationType,
    int? progress,
    int? total,
    String? currentOperation,
    DateTime? startTime,
    bool? isOnline,
  }) {
    return SyncInProgress(
      operationType: operationType ?? this.operationType,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      currentOperation: currentOperation ?? this.currentOperation,
      startTime: startTime ?? this.startTime,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Sync completed successfully
class SyncSuccess extends SyncState {
  final SyncOperationType operationType;
  final DateTime completedAt;
  final int itemsProcessed;
  final Duration duration;
  final bool isOnline;
  final String? summary;

  const SyncSuccess({
    required this.operationType,
    required this.completedAt,
    required this.itemsProcessed,
    required this.duration,
    this.isOnline = true,
    this.summary,
  });

  @override
  List<Object?> get props => [
    operationType,
    completedAt,
    itemsProcessed,
    duration,
    isOnline,
    summary,
  ];
}

/// Sync failed with error
class SyncError extends SyncState {
  final SyncOperationType operationType;
  final String error;
  final DateTime errorTime;
  final bool canRetry;
  final bool isOnline;
  final String? debugInfo;

  const SyncError({
    required this.operationType,
    required this.error,
    required this.errorTime,
    required this.canRetry,
    this.isOnline = false,
    this.debugInfo,
  });

  @override
  List<Object?> get props => [
    operationType,
    error,
    errorTime,
    canRetry,
    isOnline,
    debugInfo,
  ];
}

/// Network is offline
class SyncOffline extends SyncState {
  final DateTime offlineSince;
  final List<String> pendingOperations;

  const SyncOffline({
    required this.offlineSince,
    this.pendingOperations = const [],
  });

  @override
  List<Object?> get props => [offlineSince, pendingOperations];

  /// Get duration offline
  Duration get offlineDuration => DateTime.now().difference(offlineSince);

  SyncOffline copyWith({
    DateTime? offlineSince,
    List<String>? pendingOperations,
  }) {
    return SyncOffline(
      offlineSince: offlineSince ?? this.offlineSince,
      pendingOperations: pendingOperations ?? this.pendingOperations,
    );
  }
}

/// Sync conflict detected
class SyncConflictDetected extends SyncState {
  final List<SyncConflict> conflicts;
  final DateTime detectedAt;
  final bool isOnline;

  const SyncConflictDetected({
    required this.conflicts,
    required this.detectedAt,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [conflicts, detectedAt, isOnline];

  /// Get number of unresolved conflicts
  int get unresolvedCount => 
      conflicts.where((c) => c.resolution == null).length;

  SyncConflictDetected copyWith({
    List<SyncConflict>? conflicts,
    DateTime? detectedAt,
    bool? isOnline,
  }) {
    return SyncConflictDetected(
      conflicts: conflicts ?? this.conflicts,
      detectedAt: detectedAt ?? this.detectedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Sync paused by user or system
class SyncPaused extends SyncState {
  final DateTime pausedAt;
  final String reason;
  final bool isOnline;

  const SyncPaused({
    required this.pausedAt,
    required this.reason,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [pausedAt, reason, isOnline];

  /// Get duration paused
  Duration get pausedDuration => DateTime.now().difference(pausedAt);
}

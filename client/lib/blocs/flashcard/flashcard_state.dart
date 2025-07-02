/// FlashcardBloc States
/// 
/// Defines all possible states for FlashcardBloc.
/// Uses Equatable for proper state comparison and BLoC optimization.

import 'package:equatable/equatable.dart';
import '../../models/flashcard_set.dart';
import '../../repositories/base_repository.dart';

/// Base class for all FlashcardBloc states
abstract class FlashcardState extends Equatable {
  const FlashcardState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any operations
/// 
/// FlashcardBloc starts in this state and remains here
/// until FlashcardLoadRequested event is processed.
class FlashcardInitial extends FlashcardState {
  const FlashcardInitial();
  
  @override
  String toString() => 'FlashcardInitial()';
}

/// Loading state during data operations
/// 
/// Shown when fetching data from repository or performing
/// sync operations that may take time.
class FlashcardLoading extends FlashcardState {
  final String? operation;
  
  const FlashcardLoading({this.operation});
  
  @override
  List<Object?> get props => [operation];
  
  @override
  String toString() => 'FlashcardLoading(${operation ?? 'general'})';
}

/// Successful state with loaded flashcard sets
/// 
/// Contains all flashcard sets and metadata about the current state.
/// This is the primary state for normal app operation.
class FlashcardLoaded extends FlashcardState {
  final List<FlashcardSet> sets;
  final FlashcardSet? currentSet;
  final List<FlashcardSet> filteredSets;
  final String? searchQuery;
  final SyncStatus syncStatus;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  
  const FlashcardLoaded({
    required this.sets,
    this.currentSet,
    List<FlashcardSet>? filteredSets,
    this.searchQuery,
    this.syncStatus = SyncStatus.idle,
    this.lastSyncTime,
    this.isSyncing = false,
  }) : filteredSets = filteredSets ?? sets;
  
  /// Get current set or first set if none selected
  FlashcardSet? get activeSet => currentSet ?? (sets.isNotEmpty ? sets.first : null);
  
  /// Get total number of sets
  int get totalSets => sets.length;
  
  /// Get total number of flashcards across all sets
  int get totalFlashcards => sets.fold(0, (total, set) => total + set.flashcards.length);
  
  /// Get total completed flashcards across all sets
  int get totalCompletedFlashcards => sets.fold(0, (total, set) => 
    total + set.flashcards.where((card) => card.isCompleted).length);
  
  /// Get overall progress percentage (0-100)
  double get overallProgress {
    if (totalFlashcards == 0) return 0.0;
    return (totalCompletedFlashcards / totalFlashcards) * 100;
  }
  
  /// Check if search is active
  bool get isSearchActive => searchQuery != null && searchQuery!.isNotEmpty;
  
  /// Get sets to display (filtered or all)
  List<FlashcardSet> get displaySets => isSearchActive ? filteredSets : sets;
  
  @override
  List<Object?> get props => [
    sets,
    currentSet, 
    filteredSets,
    searchQuery,
    syncStatus,
    lastSyncTime,
    isSyncing,
  ];
  
  /// Create a copy with updated values
  FlashcardLoaded copyWith({
    List<FlashcardSet>? sets,
    FlashcardSet? currentSet,
    List<FlashcardSet>? filteredSets,
    String? searchQuery,
    SyncStatus? syncStatus,
    DateTime? lastSyncTime,
    bool? isSyncing,
    bool clearCurrentSet = false,
    bool clearSearch = false,
  }) {
    return FlashcardLoaded(
      sets: sets ?? this.sets,
      currentSet: clearCurrentSet ? null : (currentSet ?? this.currentSet),
      filteredSets: filteredSets ?? this.filteredSets,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
  
  @override
  String toString() => 'FlashcardLoaded(sets: ${sets.length}, currentSet: ${currentSet?.title}, '
                      'filteredSets: ${filteredSets.length}, searchQuery: $searchQuery, '
                      'syncStatus: $syncStatus, isSyncing: $isSyncing)';
}

/// Error state when operations fail
/// 
/// Contains error information and allows recovery actions.
class FlashcardError extends FlashcardState {
  final String message;
  final String? operation;
  final dynamic error;
  final StackTrace? stackTrace;
  final List<FlashcardSet>? cachedSets;
  
  const FlashcardError({
    required this.message,
    this.operation,
    this.error,
    this.stackTrace,
    this.cachedSets,
  });
  
  /// Check if we have cached data to fall back to
  bool get hasCachedData => cachedSets != null && cachedSets!.isNotEmpty;
  
  @override
  List<Object?> get props => [message, operation, error, cachedSets];
  
  @override
  String toString() => 'FlashcardError(message: $message, operation: $operation, '
                      'hasCachedData: $hasCachedData)';
}

/// State during sync operations
/// 
/// Shows progress and status of cloud synchronization.
class FlashcardSyncing extends FlashcardState {
  final List<FlashcardSet> sets;
  final SyncStatus syncStatus;
  final String? syncMessage;
  final double? progress;
  
  const FlashcardSyncing({
    required this.sets,
    required this.syncStatus,
    this.syncMessage,
    this.progress,
  });
  
  @override
  List<Object?> get props => [sets, syncStatus, syncMessage, progress];
  
  @override
  String toString() => 'FlashcardSyncing(sets: ${sets.length}, status: $syncStatus, '
                      'message: $syncMessage, progress: $progress)';
}
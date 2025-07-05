/// FlashcardBloc Events
///
/// Defines all events that can be sent to FlashcardBloc for processing.
/// Uses Equatable for proper event comparison and BLoC optimization.
library;

import 'package:equatable/equatable.dart';
import '../../models/flashcard_set.dart';
import '../../repositories/base_repository.dart';

/// Base class for all FlashcardBloc events
abstract class FlashcardEvent extends Equatable {
  const FlashcardEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load all flashcard sets
///
/// Triggers initial data loading from repository.
/// Should be called when FlashcardBloc is first created.
class FlashcardLoadRequested extends FlashcardEvent {
  const FlashcardLoadRequested();

  @override
  String toString() => 'FlashcardLoadRequested()';
}

/// Request to refresh flashcard sets from all sources
///
/// Forces refresh from both local cache and cloud.
/// Useful for pull-to-refresh functionality.
class FlashcardRefreshRequested extends FlashcardEvent {
  const FlashcardRefreshRequested();

  @override
  String toString() => 'FlashcardRefreshRequested()';
}

/// Request to add a new flashcard set
///
/// Validates and saves a new flashcard set to the repository.
class FlashcardSetAdded extends FlashcardEvent {
  final FlashcardSet flashcardSet;

  const FlashcardSetAdded(this.flashcardSet);

  @override
  List<Object?> get props => [flashcardSet];

  @override
  String toString() => 'FlashcardSetAdded(${flashcardSet.title})';
}

/// Request to update an existing flashcard set
///
/// Updates content, progress, or metadata of an existing set.
class FlashcardSetUpdated extends FlashcardEvent {
  final FlashcardSet flashcardSet;

  const FlashcardSetUpdated(this.flashcardSet);

  @override
  List<Object?> get props => [flashcardSet];

  @override
  String toString() => 'FlashcardSetUpdated(${flashcardSet.id})';
}

/// Request to delete a flashcard set
///
/// Removes the set from local storage and marks as deleted in cloud.
class FlashcardSetDeleted extends FlashcardEvent {
  final String setId;

  const FlashcardSetDeleted(this.setId);

  @override
  List<Object?> get props => [setId];

  @override
  String toString() => 'FlashcardSetDeleted($setId)';
}

/// Request to update progress for a specific flashcard
///
/// CRITICAL EVENT: This is the key event for fixing the progress bar bug.
/// Updates completion status for individual cards within a set.
class FlashcardProgressUpdated extends FlashcardEvent {
  final String setId;
  final String cardId;
  final bool isCompleted;

  const FlashcardProgressUpdated({
    required this.setId,
    required this.cardId,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [setId, cardId, isCompleted];

  @override
  String toString() =>
      'FlashcardProgressUpdated(setId: $setId, cardId: $cardId, isCompleted: $isCompleted)';
}

/// Request to mark/unmark a flashcard for review
///
/// Updates the review status for a specific flashcard.
class FlashcardMarkedForReview extends FlashcardEvent {
  final String setId;
  final String cardId;
  final bool isMarkedForReview;

  const FlashcardMarkedForReview({
    required this.setId,
    required this.cardId,
    required this.isMarkedForReview,
  });

  @override
  List<Object?> get props => [setId, cardId, isMarkedForReview];

  @override
  String toString() =>
      'FlashcardMarkedForReview(setId: $setId, cardId: $cardId, isMarked: $isMarkedForReview)';
}

/// Request to search flashcard sets
///
/// Filters flashcard sets based on search query.
class FlashcardSearchRequested extends FlashcardEvent {
  final String query;

  const FlashcardSearchRequested(this.query);

  @override
  List<Object?> get props => [query];

  @override
  String toString() => 'FlashcardSearchRequested($query)';
}

/// Request to sync with cloud storage
///
/// Triggers manual sync operation with cloud services.
class FlashcardSyncRequested extends FlashcardEvent {
  final bool forceRefresh;

  const FlashcardSyncRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];

  @override
  String toString() => 'FlashcardSyncRequested(forceRefresh: $forceRefresh)';
}

/// Request to clear all flashcard sets
///
/// WARNING: This will remove all local data. Use with caution.
class FlashcardClearRequested extends FlashcardEvent {
  const FlashcardClearRequested();

  @override
  String toString() => 'FlashcardClearRequested()';
}

/// Internal event for sync status updates
///
/// Used internally by FlashcardBloc to update sync status from repository.
class FlashcardSyncStatusUpdated extends FlashcardEvent {
  final SyncStatus syncStatus;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  const FlashcardSyncStatusUpdated({
    required this.syncStatus,
    required this.isSyncing,
    this.lastSyncTime,
  });

  @override
  List<Object?> get props => [syncStatus, isSyncing, lastSyncTime];

  @override
  String toString() =>
      'FlashcardSyncStatusUpdated(status: $syncStatus, isSyncing: $isSyncing)';
}

/// Internal event for data updates from repository
///
/// Used internally by FlashcardBloc when repository data changes.
class FlashcardDataUpdated extends FlashcardEvent {
  final List<FlashcardSet> sets;
  final List<FlashcardSet>? filteredSets;

  const FlashcardDataUpdated({required this.sets, this.filteredSets});

  @override
  List<Object?> get props => [sets, filteredSets];

  @override
  String toString() => 'FlashcardDataUpdated(${sets.length} sets)';
}

/// Internal event for repository errors
///
/// Used internally by FlashcardBloc when repository encounters errors.
class FlashcardRepositoryErrorOccurred extends FlashcardEvent {
  final dynamic error;

  const FlashcardRepositoryErrorOccurred({required this.error});

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'FlashcardRepositoryErrorOccurred($error)';
}

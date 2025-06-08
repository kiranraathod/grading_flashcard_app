import '../../models/flashcard_set.dart';
import '../../models/flashcard.dart';
import '../../models/category.dart' as models;

/// Utilities for handling data conflicts during sync operations
class SyncConflictResolver {
  
  /// Resolve conflicts between local and remote FlashcardSets
  static FlashcardSet resolveFlashcardSetConflict(
    FlashcardSet localSet,
    FlashcardSet remoteSet, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveByLastWrite(localSet, remoteSet);
      case ConflictResolutionStrategy.localWins:
        return localSet;
      case ConflictResolutionStrategy.remoteWins:
        return remoteSet;
      case ConflictResolutionStrategy.merge:
        return _mergeFlashcardSets(localSet, remoteSet);
    }
  }
  
  /// Resolve conflicts between local and remote Categories
  static models.Category resolveCategoryConflict(
    models.Category localCategory,
    models.Category remoteCategory, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return localCategory.updatedAt.isAfter(remoteCategory.updatedAt) 
            ? localCategory 
            : remoteCategory;
      case ConflictResolutionStrategy.localWins:
        return localCategory;
      case ConflictResolutionStrategy.remoteWins:
        return remoteCategory;
      case ConflictResolutionStrategy.merge:
        return _mergeCategories(localCategory, remoteCategory);
    }
  }
  
  /// Resolve by comparing last write times
  static FlashcardSet _resolveByLastWrite(FlashcardSet local, FlashcardSet remote) {
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }
  
  /// Merge two FlashcardSets intelligently
  static FlashcardSet _mergeFlashcardSets(FlashcardSet local, FlashcardSet remote) {
    // Use the more recently updated metadata
    final baseSet = local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
    
    // Merge flashcards by combining unique cards from both sets
    final mergedFlashcards = <String, Flashcard>{};
    
    // Add all local flashcards
    for (final card in local.flashcards) {
      mergedFlashcards[card.id] = card;
    }
    
    // Add remote flashcards, checking for conflicts
    for (final card in remote.flashcards) {
      if (mergedFlashcards.containsKey(card.id)) {
        // Since flashcards don't have updatedAt, use the parent set's updatedAt
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          mergedFlashcards[card.id] = card;
        }
        // Otherwise keep the local card (already in the map)
      } else {
        mergedFlashcards[card.id] = card;
      }
    }
    
    return baseSet.copyWith(
      flashcards: mergedFlashcards.values.toList(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Merge two Categories intelligently
  static models.Category _mergeCategories(models.Category local, models.Category remote) {
    // Use the more recently updated category as base
    final baseCategory = local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
    
    // Merge with updated timestamp
    return baseCategory.copyWith(updatedAt: DateTime.now());
  }
}

/// Strategies for resolving sync conflicts
enum ConflictResolutionStrategy {
  lastWriteWins,
  localWins,
  remoteWins,
  merge,
}

/// Utilities for optimizing sync operations
class SyncOptimizer {
  
  /// Determine if two FlashcardSets are effectively identical (no sync needed)
  static bool areFlashcardSetsIdentical(FlashcardSet set1, FlashcardSet set2) {
    if (set1.id != set2.id) return false;
    if (set1.title != set2.title) return false;
    if (set1.description != set2.description) return false;
    if (set1.flashcards.length != set2.flashcards.length) return false;
    
    // Check flashcards content
    for (int i = 0; i < set1.flashcards.length; i++) {
      final card1 = set1.flashcards[i];
      final card2 = set2.flashcards[i];
      
      if (card1.id != card2.id || 
          card1.question != card2.question || 
          card1.answer != card2.answer) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Filter out sets that don't need syncing
  static List<FlashcardSet> filterSetsNeedingSync(
    List<FlashcardSet> localSets,
    List<FlashcardSet> remoteSets,
  ) {
    final setsNeedingSync = <FlashcardSet>[];
    final remoteSetMap = {for (var set in remoteSets) set.id: set};
    
    for (final localSet in localSets) {
      final remoteSet = remoteSetMap[localSet.id];
      
      if (remoteSet == null) {
        // New local set needs to be uploaded
        setsNeedingSync.add(localSet);
      } else if (!areFlashcardSetsIdentical(localSet, remoteSet)) {
        // Sets differ, need to sync
        setsNeedingSync.add(localSet);
      }
      // If identical, no sync needed
    }
    
    return setsNeedingSync;
  }
}

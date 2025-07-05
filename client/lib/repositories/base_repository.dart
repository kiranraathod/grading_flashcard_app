/// Base repository abstraction for consistent data layer patterns
///
/// Provides foundation for all data operations with:
/// - CRUD operations with type safety
/// - Stream-based reactive data access
/// - Sync coordination for offline-first patterns
/// - Error handling and operation safety
library;

import 'package:flutter/foundation.dart';

/// Status of sync operations
enum SyncStatus { idle, syncing, synced, error, offline }

/// Base repository interface for all data operations
///
/// Provides consistent patterns for:
/// - Type-safe CRUD operations
/// - Reactive data streams
/// - Error handling
abstract class BaseRepository<T> {
  /// Get all items from the repository
  Future<List<T>> getAll();

  /// Get a specific item by ID
  Future<T?> getById(String id);

  /// Save an item (create or update)
  Future<void> save(T item);

  /// Delete an item by ID
  Future<void> delete(String id);

  /// Clear all items from the repository
  Future<void> clear();

  /// Watch all items for changes (reactive stream)
  Stream<List<T>> watchAll();

  /// Watch a specific item for changes
  Stream<T?> watchById(String id);
}

/// Extended repository interface for cloud-sync capable repositories
///
/// Adds coordination between local cache and cloud storage:
/// - Offline-first patterns
/// - Conflict resolution
/// - Sync status monitoring
abstract class SyncableRepository<T> extends BaseRepository<T> {
  /// Sync local changes to cloud
  Future<void> syncToCloud();

  /// Sync changes from cloud to local
  Future<void> syncFromCloud();

  /// Resolve sync conflicts using merge strategies
  Future<void> resolveSyncConflicts();

  /// Monitor sync status changes
  Stream<SyncStatus> get syncStatus;

  /// Check if repository is currently syncing
  bool get isSyncing;

  /// Force refresh from cloud (ignoring cache)
  Future<void> refreshFromCloud();

  /// Get last sync timestamp
  DateTime? get lastSyncTime;
}

/// Repository-specific exceptions for better error handling
class RepositoryException implements Exception {
  final String message;
  final String operation;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const RepositoryException({
    required this.message,
    required this.operation,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'RepositoryException($operation): $message';
  }
}

/// Data validation exception for repository operations
class ValidationException extends RepositoryException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    required super.message,
    required super.operation,
    this.fieldErrors = const {},
    super.originalError,
    super.stackTrace,
  });
}

/// Conflict resolution strategies for sync operations
enum ConflictResolution {
  /// Local changes take precedence
  localWins,

  /// Cloud changes take precedence
  cloudWins,

  /// Merge changes when possible, fail when not
  merge,

  /// Use timestamps to determine winner
  lastModifiedWins,
}

/// Base class for implementing repositories with common patterns
///
/// Provides:
/// - Error handling wrapper
/// - Logging patterns
/// - Validation framework
abstract class BaseRepositoryImpl<T> implements BaseRepository<T> {
  /// Safely execute repository operations with error handling
  Future<R> safeOperation<R>(
    String operationName,
    Future<R> Function() operation, {
    R? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      throw RepositoryException(
        message: 'Failed to $operationName',
        operation: operationName,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Validate an item before save operations
  void validateItem(T item) {
    // Override in concrete implementations for validation
  }

  /// Log repository operations for debugging
  void logOperation(String operation, {Map<String, dynamic>? metadata}) {
    debugPrint('📦 Repository Operation: $operation ${metadata ?? ''}');
  }
}

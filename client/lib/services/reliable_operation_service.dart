import 'dart:async';
import 'standard_error_handler.dart';

/// Core abstractions to replace scattered try-catch patterns throughout services.
/// Provides 5 key methods: withFallback(), withRetry(), withDefault(), withTimeout(), safely()
class ReliableOperationService {
  static final ReliableOperationService _instance = ReliableOperationService._internal();
  factory ReliableOperationService() => _instance;
  ReliableOperationService._internal();

  final StandardErrorHandler _errorHandler = StandardErrorHandler();

  /// Execute operation with fallback if primary fails
  /// Replaces: try { primary() } catch { fallback() }
  Future<T> withFallback<T>({
    required Future<T> Function() primary,
    required Future<T> Function() fallback,
    required String operationName,
    bool logErrors = true,
  }) async {
    try {
      final result = await primary();
      if (logErrors) {
        _errorHandler.logSuccess(operationName, 'Primary operation succeeded');
      }
      return result;
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.warning);
        _errorHandler.logInfo(operationName, 'Attempting fallback operation');
      }
      
      try {
        final result = await fallback();
        if (logErrors) {
          _errorHandler.logSuccess(operationName, 'Fallback operation succeeded');
        }
        return result;
      } catch (fallbackError, fallbackStackTrace) {
        if (logErrors) {
          _errorHandler.logError(operationName, fallbackError, fallbackStackTrace, level: ErrorLevel.error);
        }
        rethrow;
      }
    }
  }

  /// Execute operation with retry logic
  /// Replaces: Multiple try-catch blocks with manual retry logic
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 500),
    bool logErrors = true,
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await operation();
        if (logErrors && attempt > 1) {
          _errorHandler.logSuccess(operationName, 'Operation succeeded on attempt $attempt');
        }
        return result;
      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (logErrors) {
          final level = attempt == maxAttempts ? ErrorLevel.error : ErrorLevel.warning;
          _errorHandler.logError(operationName, e, stackTrace, level: level);
        }
        
        if (attempt < maxAttempts) {
          if (logErrors) {
            _errorHandler.logInfo(operationName, 'Retrying in ${delay.inMilliseconds}ms (attempt ${attempt + 1}/$maxAttempts)');
          }
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException!;
  }

  /// Execute operation with default value on failure
  /// Replaces: try { operation() } catch { return defaultValue; }
  Future<T> withDefault<T>({
    required Future<T> Function() operation,
    required T defaultValue,
    required String operationName,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.warning);
        _errorHandler.logInfo(operationName, 'Returning default value due to operation failure');
      }
      return defaultValue;
    }
  }

  /// Execute operation with timeout
  /// Replaces: Manual timeout handling with try-catch
  Future<T> withTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    required String operationName,
    bool logErrors = true,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.error);
      }
      throw TimeoutException('Operation $operationName timed out after ${timeout.inMilliseconds}ms', timeout);
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.error);
      }
      rethrow;
    }
  }

  /// Execute operation safely with comprehensive error handling
  /// Replaces: Complex try-catch blocks with multiple catch clauses
  Future<T?> safely<T>({
    required Future<T> Function() operation,
    required String operationName,
    T? defaultValue,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.warning);
        if (defaultValue != null) {
          _errorHandler.logInfo(operationName, 'Returning default value due to safe operation failure');
        }
      }
      return defaultValue;
    }
  }

  /// Synchronous version of withDefault for non-async operations
  T withDefaultSync<T>({
    required T Function() operation,
    required T defaultValue,
    required String operationName,
    bool logErrors = true,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.warning);
        _errorHandler.logInfo(operationName, 'Returning default value due to sync operation failure');
      }
      return defaultValue;
    }
  }

  /// Synchronous version of safely for non-async operations
  T? safelySync<T>({
    required T Function() operation,
    required String operationName,
    T? defaultValue,
    bool logErrors = true,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      if (logErrors) {
        _errorHandler.logError(operationName, e, stackTrace, level: ErrorLevel.warning);
        if (defaultValue != null) {
          _errorHandler.logInfo(operationName, 'Returning default value due to safe sync operation failure');
        }
      }
      return defaultValue;
    }
  }
}

// lib/services/simple_error_handler.dart
// Simplified error handler with just 2 core methods

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Simplified error handler with just 2 core methods
/// Provides clean patterns for error handling and operation retry
class SimpleErrorHandler {
  static final SimpleErrorHandler _instance = SimpleErrorHandler._internal();
  factory SimpleErrorHandler() => _instance;
  SimpleErrorHandler._internal();

  /// Execute async operation with optional fallback and logging
  /// Replaces: withFallback, withDefault, safely, withRetry patterns
  static Future<T> safe<T>(
    Future<T> Function() operation, {
    T? fallback,
    Future<T> Function()? fallbackOperation,
    String? operationName,
    bool logErrors = true,
    int retryCount = 0,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final result = await operation();
        if (logErrors && attempt > 0) {
          _log('✅ ${operationName ?? 'operation'} succeeded on attempt ${attempt + 1}');
        }
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (logErrors) {
          final level = attempt == retryCount ? 'ERROR' : 'WARNING';
          _log('$level ${operationName ?? 'operation'}: $e');
        }
        
        if (attempt < retryCount) {
          if (logErrors) {
            _log('🔄 Retrying ${operationName ?? 'operation'} in ${retryDelay.inMilliseconds}ms');
          }
          await Future.delayed(retryDelay);
        }
      }
    }
    
    // Try fallback operation if provided
    if (fallbackOperation != null) {
      try {
        final result = await fallbackOperation();
        if (logErrors) {
          _log('✅ ${operationName ?? 'operation'} fallback succeeded');
        }
        return result;
      } catch (e) {
        if (logErrors) {
          _log('ERROR ${operationName ?? 'operation'} fallback failed: $e');
        }
      }
    }
    
    // Return fallback value if provided
    if (fallback != null) {
      if (logErrors) {
        _log('🔄 ${operationName ?? 'operation'} returning fallback value');
      }
      return fallback;
    }
    
    // Rethrow the last exception
    throw lastException!;
  }

  /// Execute sync operation with optional fallback and logging
  /// Replaces: safelySync, withDefaultSync patterns
  static T safeSync<T>(
    T Function() operation, {
    T? fallback,
    T Function()? fallbackOperation,
    String? operationName,
    bool logErrors = true,
  }) {
    try {
      return operation();
    } catch (e) {
      if (logErrors) {
        _log('ERROR ${operationName ?? 'sync_operation'}: $e');
      }
      
      // Try fallback operation if provided
      if (fallbackOperation != null) {
        try {
          final result = fallbackOperation();
          if (logErrors) {
            _log('✅ ${operationName ?? 'sync_operation'} fallback succeeded');
          }
          return result;
        } catch (e2) {
          if (logErrors) {
            _log('ERROR ${operationName ?? 'sync_operation'} fallback failed: $e2');
          }
        }
      }
      
      // Return fallback value if provided
      if (fallback != null) {
        if (logErrors) {
          _log('🔄 ${operationName ?? 'sync_operation'} returning fallback value');
        }
        return fallback;
      }
      
      rethrow;
    }
  }

  /// Execute void operation safely (common pattern for side effects)
  static Future<void> safely(
    Future<void> Function() operation, {
    String? operationName,
    bool logErrors = true,
  }) async {
    await safe<void>(
      operation,
      fallback: null, // void operations don't have fallback values
      operationName: operationName,
      logErrors: logErrors,
    );
  }

  /// Simple logging method
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[${DateTime.now().toIso8601String()}] $message');
    }
  }
}

// Extension methods for easier usage
extension SafeOperations on Future<dynamic> {
  Future<T> safe<T>({
    T? fallback,
    String? operationName,
    bool logErrors = true,
  }) async {
    return SimpleErrorHandler.safe<T>(
      () => this as Future<T>,
      fallback: fallback,
      operationName: operationName,
      logErrors: logErrors,
    );
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import '../models/app_error.dart';
import 'connectivity_service.dart';
import 'enhanced_cache_manager.dart';
import 'simple_error_handler.dart';

enum RecoveryStrategy {
  retry,
  fallbackToCache,
  degradedMode,
  userIntervention,
  failSilently,
}

enum ErrorCategory {
  network,
  server,
  client,
  timeout,
  authentication,
  rateLimit,
  unknown,
}

class ErrorPattern {
  final ErrorCategory category;
  final String? specificCode;
  final RecoveryStrategy strategy;
  final Duration? delay;
  final int maxRetries;
  final String userMessage;
  final String actionAdvice;

  const ErrorPattern({
    required this.category,
    this.specificCode,
    required this.strategy,
    this.delay,
    this.maxRetries = 3,
    required this.userMessage,
    required this.actionAdvice,
  });
}

class RecoveryContext {
  final String operation;
  final Map<String, dynamic> originalRequest;
  final int attemptCount;
  final DateTime startTime;
  final List<AppError> previousErrors;

  const RecoveryContext({
    required this.operation,
    required this.originalRequest,
    required this.attemptCount,
    required this.startTime,
    required this.previousErrors,
  });
}

class NetworkErrorRecoveryService extends ChangeNotifier {
  static final NetworkErrorRecoveryService _instance = NetworkErrorRecoveryService._internal();
  factory NetworkErrorRecoveryService() => _instance;
  NetworkErrorRecoveryService._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final EnhancedCacheManager _cache = EnhancedCacheManager();
  
  // Error patterns and recovery strategies
  static final List<ErrorPattern> _errorPatterns = [
    // Network connectivity errors
    ErrorPattern(
      category: ErrorCategory.network,
      strategy: RecoveryStrategy.retry,
      delay: Duration(seconds: 2),
      maxRetries: 3,
      userMessage: 'Connection problem detected',
      actionAdvice: 'Check your internet connection and try again',
    ),
    
    // Server errors (5xx)
    ErrorPattern(
      category: ErrorCategory.server,
      strategy: RecoveryStrategy.fallbackToCache,
      delay: Duration(seconds: 5),
      maxRetries: 2,
      userMessage: 'Server temporarily unavailable',
      actionAdvice: 'Using cached data. Try again later for fresh content',
    ),
    
    // Timeout errors
    ErrorPattern(
      category: ErrorCategory.timeout,
      strategy: RecoveryStrategy.retry,
      delay: Duration(seconds: 1),
      maxRetries: 2,
      userMessage: 'Request timed out',
      actionAdvice: 'Retrying with optimized settings',
    ),
  ];

  /// Handle network error with appropriate recovery strategy
  Future<T?> handleError<T>(
    AppError error,
    RecoveryContext context,
    Future<T> Function() retryOperation,
  ) async {
    final pattern = _findErrorPattern(error);
    
    AppConfig.logNetwork(
      'Handling error: ${error.code} with strategy: ${pattern.strategy.name}',
      level: NetworkLogLevel.basic
    );

    switch (pattern.strategy) {
      case RecoveryStrategy.retry:
        return await _handleRetry(error, context, retryOperation, pattern);
      
      case RecoveryStrategy.fallbackToCache:
        return await _handleCacheFallback<T>(context);
      
      case RecoveryStrategy.degradedMode:
        return await _handleDegradedMode<T>(context);
      
      case RecoveryStrategy.userIntervention:
        await _notifyUserIntervention(error, pattern);
        return null;
      
      case RecoveryStrategy.failSilently:
        AppConfig.logNetwork('Failing silently for: ${error.code}', level: NetworkLogLevel.verbose);
        return null;
    }
  }

  /// Find appropriate error pattern for the given error
  ErrorPattern _findErrorPattern(AppError error) {
    for (final pattern in _errorPatterns) {
      // Check specific code first
      if (pattern.specificCode != null && pattern.specificCode == error.code) {
        return pattern;
      }
      
      // Check category
      final category = _categorizeError(error);
      if (pattern.category == category && pattern.specificCode == null) {
        return pattern;
      }
    }
    
    // Default fallback pattern
    return ErrorPattern(
      category: ErrorCategory.unknown,
      strategy: RecoveryStrategy.userIntervention,
      userMessage: 'An unexpected error occurred',
      actionAdvice: 'Please try again or contact support',
    );
  }

  /// Categorize error by type
  ErrorCategory _categorizeError(AppError error) {
    if (error.source == ErrorSource.network) {
      if (error.code.contains('timeout')) return ErrorCategory.timeout;
      return ErrorCategory.network;
    }
    
    if (error.code.startsWith('http_')) {
      final statusCode = int.tryParse(error.code.substring(5));
      if (statusCode != null) {
        if (statusCode >= 500) return ErrorCategory.server;
        if (statusCode == 429) return ErrorCategory.rateLimit;
        if (statusCode == 401 || statusCode == 403) return ErrorCategory.authentication;
        if (statusCode >= 400) return ErrorCategory.client;
      }
    }
    
    return ErrorCategory.unknown;
  }

  /// Handle retry strategy
  Future<T?> _handleRetry<T>(
    AppError error,
    RecoveryContext context,
    Future<T> Function() retryOperation,
    ErrorPattern pattern,
  ) async {
    if (context.attemptCount >= pattern.maxRetries) {
      AppConfig.logNetwork('Max retries exceeded for: ${context.operation}', level: NetworkLogLevel.basic);
      return null;
    }

    // Wait before retry if specified
    if (pattern.delay != null) {
      await Future.delayed(pattern.delay!);
    }

    // Check connectivity before retry
    if (!_connectivity.hasInternetConnection) {
      AppConfig.logNetwork('No connectivity for retry: ${context.operation}', level: NetworkLogLevel.basic);
      return await _handleCacheFallback<T>(context);
    }

    return await SimpleErrorHandler.safe<T?>(
      () => retryOperation(),
      fallback: null,
      operationName: 'retry_${context.operation}',
    );
  }

  /// Handle cache fallback strategy
  Future<T?> _handleCacheFallback<T>(RecoveryContext context) async {
    final cacheKey = _generateCacheKey(context.operation, context.originalRequest);
    final cachedData = await _cache.getCachedData(cacheKey);
    
    if (cachedData != null) {
      AppConfig.logNetwork('Using cached data for: ${context.operation}', level: NetworkLogLevel.basic);
      return cachedData as T?;
    }
    
    AppConfig.logNetwork('No cached data available for: ${context.operation}', level: NetworkLogLevel.basic);
    return null;
  }

  /// Handle degraded mode strategy
  Future<T?> _handleDegradedMode<T>(RecoveryContext context) async {
    AppConfig.logNetwork('Entering degraded mode for: ${context.operation}', level: NetworkLogLevel.basic);
    
    // Implement degraded functionality - return simplified/cached data
    final cacheKey = _generateCacheKey(context.operation, context.originalRequest);
    return await _cache.getCachedData(cacheKey) as T?;
  }

  /// Notify user intervention required
  Future<void> _notifyUserIntervention(AppError error, ErrorPattern pattern) async {
    AppConfig.logNetwork('User intervention required: ${error.message}', level: NetworkLogLevel.basic);
    notifyListeners(); // Notify UI to show error message
  }

  /// Generate cache key from operation and request
  String _generateCacheKey(String operation, Map<String, dynamic> request) {
    final requestKey = request.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${operation}_$requestKey';
  }

  /// Get error recovery suggestions for user
  String getRecoverySuggestion(AppError error) {
    final pattern = _findErrorPattern(error);
    return pattern.actionAdvice;
  }

  /// Check if operation should be retried
  bool shouldRetry(AppError error, int currentAttempt) {
    final pattern = _findErrorPattern(error);
    return currentAttempt < pattern.maxRetries && 
           pattern.strategy == RecoveryStrategy.retry;
  }
}

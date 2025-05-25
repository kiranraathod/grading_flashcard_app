import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import '../models/app_error.dart';
import 'connectivity_service.dart';

enum CircuitBreakerState { closed, open, halfOpen }

class RequestMetrics {
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final int? statusCode;
  final String? error;

  const RequestMetrics({
    required this.timestamp,
    required this.duration,
    required this.success,
    this.statusCode,
    this.error,
  });
}

class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration halfOpenTimeout;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  int _halfOpenAttempts = 0;
  static const int maxHalfOpenAttempts = 3;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 5),
    this.halfOpenTimeout = const Duration(seconds: 30),
  });

  CircuitBreakerState get state => _state;
  bool get isClosed => _state == CircuitBreakerState.closed;
  bool get isOpen => _state == CircuitBreakerState.open;
  bool get isHalfOpen => _state == CircuitBreakerState.halfOpen;

  bool canExecute() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) > timeout) {
          _state = CircuitBreakerState.halfOpen;
          _halfOpenAttempts = 0;
          AppConfig.logNetwork('Circuit breaker moving to half-open state', level: NetworkLogLevel.basic);
          return true;
        }
        return false;
      case CircuitBreakerState.halfOpen:
        return _halfOpenAttempts < maxHalfOpenAttempts;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
      AppConfig.logNetwork('Circuit breaker closed after successful requests', level: NetworkLogLevel.basic);
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenAttempts++;
      if (_halfOpenAttempts >= maxHalfOpenAttempts) {
        _state = CircuitBreakerState.open;
        AppConfig.logNetwork('Circuit breaker opened after half-open failures', level: NetworkLogLevel.basic);
      }
    } else if (_state == CircuitBreakerState.closed && _failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      AppConfig.logNetwork('Circuit breaker opened after $failureThreshold failures', level: NetworkLogLevel.basic);
    }
  }
}

class EnhancedHttpClientService {
  static final EnhancedHttpClientService _instance = EnhancedHttpClientService._internal();
  factory EnhancedHttpClientService() => _instance;
  EnhancedHttpClientService._internal();

  late final Dio _dio;
  final ConnectivityService _connectivity = ConnectivityService();
  final CircuitBreaker _circuitBreaker = CircuitBreaker();
  final List<RequestMetrics> _requestHistory = [];
  final Map<String, Completer<Response>> _pendingRequests = {};
  
  // Request deduplication
  final Set<String> _activeRequestKeys = {};
  
  // Performance metrics
  static const int maxHistorySize = 100;
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  
  bool _isInitialized = false;

  /// Initialize the enhanced HTTP client
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Configure BaseOptions with web-safe settings
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: AppConfig.defaultHeaders,
      connectTimeout: AppConfig.connectivityTimeout,
      receiveTimeout: AppConfig.apiTimeout,
    );
    
    // Only set sendTimeout on non-web platforms
    if (!kIsWeb) {
      baseOptions.sendTimeout = AppConfig.apiTimeout;
    }
    
    _dio = Dio(baseOptions);
    
    _setupInterceptors();
    _isInitialized = true;
    
    AppConfig.logNetwork('EnhancedHttpClientService initialized', level: NetworkLogLevel.basic);
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppConfig.logNetwork(
          'REQUEST: ${options.method} ${options.path}',
          level: NetworkLogLevel.verbose
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppConfig.logNetwork(
          'RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          level: NetworkLogLevel.verbose
        );
        handler.next(response);
      },
      onError: (error, handler) {
        AppConfig.logNetwork(
          'ERROR: ${error.response?.statusCode} ${error.requestOptions.path} - ${error.message}',
          level: NetworkLogLevel.errors
        );
        handler.next(error);
      },
    ));
  }

  /// Enhanced GET request with retry logic and circuit breaker
  Future<Response> get(String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool enableRetry = true,
    bool enableDeduplication = true,
  }) async {
    return _executeRequest(
      () => _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'GET $endpoint',
      enableRetry: enableRetry,
      enableDeduplication: enableDeduplication,
    );
  }

  /// Enhanced POST request with retry logic and circuit breaker
  Future<Response> post(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool enableRetry = true,
    bool enableDeduplication = false, // Usually don't deduplicate POST requests
  }) async {
    return _executeRequest(
      () => _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'POST $endpoint',
      enableRetry: enableRetry,
      enableDeduplication: enableDeduplication,
    );
  }

  /// Enhanced PUT request
  Future<Response> put(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool enableRetry = true,
  }) async {
    return _executeRequest(
      () => _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'PUT $endpoint',
      enableRetry: enableRetry,
      enableDeduplication: false,
    );
  }

  /// Core request execution with all enhancements
  Future<Response> _executeRequest(
    Future<Response> Function() request,
    String requestKey,
    {
      bool enableRetry = true,
      bool enableDeduplication = true,
    }
  ) async {
    await _ensureInitialized();
    
    // Check network connectivity
    if (!_connectivity.hasInternetConnection) {
      throw AppError.network('No internet connection available');
    }
    
    // Circuit breaker check
    if (!_circuitBreaker.canExecute()) {
      throw AppError.network('Service temporarily unavailable (circuit breaker open)');
    }
    
    // Request deduplication
    if (enableDeduplication) {
      final existingRequest = _pendingRequests[requestKey];
      if (existingRequest != null) {
        AppConfig.logNetwork('Request deduplicated: $requestKey', level: NetworkLogLevel.verbose);
        return await existingRequest.future;
      }
    }
    
    final completer = Completer<Response>();
    if (enableDeduplication) {
      _pendingRequests[requestKey] = completer;
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      Response response;
      
      if (enableRetry) {
        response = await _executeWithRetry(request, requestKey);
      } else {
        response = await request();
      }
      
      stopwatch.stop();
      
      // Record success metrics
      _recordRequestMetrics(RequestMetrics(
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
        success: true,
        statusCode: response.statusCode,
      ));
      
      _circuitBreaker.recordSuccess();
      _successfulRequests++;
      
      if (enableDeduplication) {
        completer.complete(response);
        _pendingRequests.remove(requestKey);
      }
      
      return response;
      
    } catch (e) {
      stopwatch.stop();
      
      // Handle specific error types
      String errorMessage = e.toString();
      if (e is TypeError) {
        errorMessage = 'Type conversion error (possibly headers): ${e.toString()}';
        AppConfig.logNetwork('Enhanced client failed, falling back: $errorMessage', level: NetworkLogLevel.errors);
      } else {
        AppConfig.logNetwork('Request failed: $errorMessage', level: NetworkLogLevel.errors);
      }
      
      // Record failure metrics
      _recordRequestMetrics(RequestMetrics(
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
        success: false,
        error: errorMessage,
      ));
      
      _circuitBreaker.recordFailure();
      _failedRequests++;
      
      if (enableDeduplication) {
        completer.completeError(e);
        _pendingRequests.remove(requestKey);
      }
      
      rethrow;
    } finally {
      _totalRequests++;
    }
  }

  /// Execute request with exponential backoff retry
  Future<Response> _executeWithRetry(
    Future<Response> Function() request,
    String requestKey,
  ) async {
    int attempts = 0;
    Duration delay = AppConfig.retryDelay;
    
    while (attempts < AppConfig.maxRetryAttempts) {
      try {
        attempts++;
        
        final response = await request();
        
        if (attempts > 1) {
          AppConfig.logNetwork(
            'Request succeeded on attempt $attempts: $requestKey',
            level: NetworkLogLevel.basic
          );
        }
        
        return response;
        
      } catch (e) {
        final shouldRetry = _shouldRetryRequest(e, attempts);
        
        if (!shouldRetry || attempts >= AppConfig.maxRetryAttempts) {
          AppConfig.logNetwork(
            'Request failed after $attempts attempts: $requestKey - $e',
            level: NetworkLogLevel.errors
          );
          rethrow;
        }
        
        // Wait before retry with exponential backoff
        AppConfig.logNetwork(
          'Request failed (attempt $attempts/${AppConfig.maxRetryAttempts}): $requestKey - Retrying in ${delay.inSeconds}s',
          level: NetworkLogLevel.basic
        );
        
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }
    
    throw AppError.network('Request failed after ${AppConfig.maxRetryAttempts} attempts');
  }

  /// Determine if a request should be retried
  bool _shouldRetryRequest(dynamic error, int attemptNumber) {
    // Don't retry on first attempt if network is known to be poor
    if (attemptNumber == 1 && _connectivity.hasPoorConnection) {
      return false;
    }
    
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          // Retry on server errors (5xx) but not client errors (4xx)
          final statusCode = error.response?.statusCode;
          return statusCode != null && statusCode >= 500;
        default:
          return false;
      }
    }
    
    // Retry on socket exceptions
    return error is SocketException || error is TimeoutException;
  }

  /// Record request metrics for monitoring
  void _recordRequestMetrics(RequestMetrics metrics) {
    _requestHistory.add(metrics);
    
    // Maintain history size
    if (_requestHistory.length > maxHistorySize) {
      _requestHistory.removeAt(0);
    }
    
    AppConfig.logNetwork(
      'Request metrics: Duration=${metrics.duration.inMilliseconds}ms, Success=${metrics.success}',
      level: NetworkLogLevel.verbose
    );
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final successRate = _totalRequests > 0 ? (_successfulRequests / _totalRequests) * 100 : 0.0;
    final recentRequests = _requestHistory.where((m) => 
      DateTime.now().difference(m.timestamp) < const Duration(minutes: 5)
    ).toList();
    
    final avgLatency = recentRequests.isNotEmpty
        ? recentRequests.fold<int>(0, (sum, m) => sum + m.duration.inMilliseconds) / recentRequests.length
        : 0.0;

    return {
      'totalRequests': _totalRequests,
      'successfulRequests': _successfulRequests,
      'failedRequests': _failedRequests,
      'successRate': successRate,
      'averageLatency': avgLatency,
      'circuitBreakerState': _circuitBreaker.state.name,
      'recentRequestCount': recentRequests.length,
    };
  }

  /// Health check method
  Future<bool> healthCheck() async {
    try {
      await _ensureInitialized();
      final response = await get(AppConfig.endpoints['ping']!, enableRetry: false);
      return response.statusCode == 200;
    } catch (e) {
      AppConfig.logNetwork('Health check failed: $e', level: NetworkLogLevel.errors);
      return false;
    }
  }

  /// Reset circuit breaker manually
  void resetCircuitBreaker() {
    _circuitBreaker._state = CircuitBreakerState.closed;
    _circuitBreaker._failureCount = 0;
    _circuitBreaker._lastFailureTime = null;
    AppConfig.logNetwork('Circuit breaker manually reset', level: NetworkLogLevel.basic);
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    _pendingRequests.clear();
    _activeRequestKeys.clear();
    _requestHistory.clear();
  }
}

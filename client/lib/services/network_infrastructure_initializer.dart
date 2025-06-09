import 'dart:async';
import '../utils/config.dart';
import 'connectivity_service.dart';
import 'enhanced_http_client_service.dart';
import 'enhanced_cache_manager.dart';
import 'sync_status_tracker.dart';
import 'http_client_service.dart';
import 'cache_manager.dart';
import 'simple_error_handler.dart';

class NetworkInfrastructureInitializer {
  static final NetworkInfrastructureInitializer _instance = NetworkInfrastructureInitializer._internal();
  factory NetworkInfrastructureInitializer() => _instance;
  NetworkInfrastructureInitializer._internal();

  bool _isInitialized = false;
  bool _initializationInProgress = false;
  final List<String> _initializationErrors = [];

  // Services
  final ConnectivityService _connectivity = ConnectivityService();
  final EnhancedHttpClientService _enhancedHttp = EnhancedHttpClientService();
  final EnhancedCacheManager _enhancedCache = EnhancedCacheManager();
  final SyncStatusTracker _syncTracker = SyncStatusTracker();
  final HttpClientService _httpClient = HttpClientService();
  final CacheManager _cacheManager = CacheManager();

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _initializationInProgress;
  List<String> get initializationErrors => List.unmodifiable(_initializationErrors);

  /// Initialize all network infrastructure components
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_initializationInProgress) return false;

    _initializationInProgress = true;
    _initializationErrors.clear();

    final result = await SimpleErrorHandler.safe<bool>(
      () async {
        AppConfig.logNetwork('Starting network infrastructure initialization', level: NetworkLogLevel.basic);

        // Step 1: Initialize core configuration
        AppConfig.initialize();
        AppConfig.logNetwork('Configuration initialized', level: NetworkLogLevel.verbose);

        // Step 2: Initialize connectivity service (foundation for all network operations)
        await _initializeWithErrorHandling(
          'ConnectivityService',
          () => _connectivity.initialize(),
        );

        // Step 3: Initialize enhanced cache manager (independent component)
        await _initializeWithErrorHandling(
          'EnhancedCacheManager',
          () => _enhancedCache.initialize(),
        );

        // Step 4: Initialize enhanced HTTP client (depends on connectivity)
        await _initializeWithErrorHandling(
          'EnhancedHttpClientService',
          () => _enhancedHttp.initialize(),
        );

        // Step 5: Initialize error recovery service (depends on connectivity and cache)
        await _initializeWithErrorHandling(
          'NetworkErrorRecoveryService',
          () => Future.value(), // Error recovery doesn't need explicit initialization
        );

        // Step 6: Initialize sync tracker (depends on connectivity, cache, and HTTP client)
        await _initializeWithErrorHandling(
          'SyncStatusTracker',
          () => _syncTracker.initialize(),
        );

        // Step 7: Initialize backward-compatible services
        await _initializeWithErrorHandling(
          'HttpClientService',
          () => _httpClient.initialize(),
        );

        await _initializeWithErrorHandling(
          'CacheManager',
          () => _cacheManager.initialize(),
        );

        _isInitialized = _initializationErrors.isEmpty;

        if (_isInitialized) {
          AppConfig.logNetwork('Network infrastructure initialization completed successfully', level: NetworkLogLevel.basic);
          _logInitializationSummary();
        } else {
          AppConfig.logNetwork('Network infrastructure initialization completed with errors: ${_initializationErrors.join(', ')}', level: NetworkLogLevel.errors);
        }

        return _isInitialized;
      },
      fallback: false,
      operationName: 'network_infrastructure_initialization',
    );

    _initializationInProgress = false;
    return result;
  }

  /// Initialize a component with error handling
  Future<void> _initializeWithErrorHandling(
    String componentName,
    Future<void> Function() initFunction,
  ) async {
    await SimpleErrorHandler.safe<void>(
      () async {
        AppConfig.logNetwork('Initializing $componentName...', level: NetworkLogLevel.verbose);
        await initFunction();
        AppConfig.logNetwork('$componentName initialized successfully', level: NetworkLogLevel.verbose);
      },
      fallbackOperation: () async {
        final errorMessage = 'Failed to initialize $componentName';
        AppConfig.logNetwork(errorMessage, level: NetworkLogLevel.errors);
        _initializationErrors.add(errorMessage);
        
        // Don't throw - allow other components to initialize
        AppConfig.logNetwork('Continuing initialization despite $componentName failure', level: NetworkLogLevel.basic);
      },
      operationName: 'initialize_$componentName',
    );
  }

  /// Log initialization summary
  void _logInitializationSummary() {
    final stats = getInfrastructureStatus();
    AppConfig.logNetwork('Network Infrastructure Status:', level: NetworkLogLevel.basic);
    stats.forEach((key, value) {
      AppConfig.logNetwork('  $key: $value', level: NetworkLogLevel.basic);
    });
  }

  /// Get status of all network infrastructure components
  Map<String, dynamic> getInfrastructureStatus() {
    return {
      'initialized': _isInitialized,
      'connectivity': _connectivity.isOnline ? 'Connected' : 'Disconnected',
      'networkQuality': _connectivity.currentQuality?.status.name ?? 'Unknown',
      'httpClientStats': _httpClient.getPerformanceStats(),
      'cacheStats': _cacheManager.getStatistics(),
      'syncStatus': _syncTracker.getStatistics(),
      'initializationErrors': _initializationErrors.length,
    };
  }

  /// Perform health check on all components
  Future<Map<String, bool>> performHealthCheck() async {
    final results = <String, bool>{};

    // Connectivity check
    results['connectivity'] = await SimpleErrorHandler.safe<bool>(
      () async => _connectivity.hasInternetConnection,
      fallback: false,
      operationName: 'connectivity_health_check',
    );

    // HTTP client check
    results['httpClient'] = await SimpleErrorHandler.safe<bool>(
      () => _httpClient.checkConnectivity(),
      fallback: false,
      operationName: 'http_client_health_check',
    );

    // Enhanced HTTP client check
    results['enhancedHttpClient'] = await SimpleErrorHandler.safe<bool>(
      () => _enhancedHttp.healthCheck(),
      fallback: false,
      operationName: 'enhanced_http_client_health_check',
    );

    // Cache availability check
    results['cache'] = await SimpleErrorHandler.safe<bool>(
      () async {
        await _cacheManager.getCachedData('health_check_test');
        return true;
      },
      fallback: false,
      operationName: 'cache_health_check',
    );

    return results;
  }

  /// Force refresh all network components
  Future<void> forceRefreshAll() async {
    AppConfig.logNetwork('Force refreshing all network components', level: NetworkLogLevel.basic);

    await _connectivity.forceRefresh();
    await _syncTracker.triggerSync();
    
    AppConfig.logNetwork('Force refresh completed', level: NetworkLogLevel.basic);
  }

  /// Reset network infrastructure (for testing or recovery)
  Future<void> reset() async {
    AppConfig.logNetwork('Resetting network infrastructure', level: NetworkLogLevel.basic);

    _isInitialized = false;
    _initializationInProgress = false;
    _initializationErrors.clear();

    // Reset circuit breakers and retry counters
    _httpClient.resetCircuitBreaker();
    
    AppConfig.logNetwork('Network infrastructure reset completed', level: NetworkLogLevel.basic);
  }

  /// Dispose all network resources
  void dispose() {
    AppConfig.logNetwork('Disposing network infrastructure', level: NetworkLogLevel.basic);

    _connectivity.dispose();
    _enhancedHttp.dispose();
    _syncTracker.dispose();
    _httpClient.dispose();

    _isInitialized = false;
  }
}

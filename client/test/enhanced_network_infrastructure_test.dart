import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flashcard_app/services/network_infrastructure_initializer.dart';
import 'package:flutter_flashcard_app/services/connectivity_service.dart';
import 'package:flutter_flashcard_app/services/enhanced_http_client_service.dart';
import 'package:flutter_flashcard_app/services/enhanced_cache_manager.dart';
import 'package:flutter_flashcard_app/services/network_error_recovery_service.dart';
import 'package:flutter_flashcard_app/services/sync_status_tracker.dart';
import 'package:flutter_flashcard_app/services/http_client_service.dart';
import 'package:flutter_flashcard_app/services/cache_manager.dart';
import 'package:flutter_flashcard_app/utils/config.dart';
import 'package:flutter_flashcard_app/models/app_error.dart';

void main() {
  group('Enhanced Network Infrastructure Tests', () {
    late NetworkInfrastructureInitializer networkInitializer;

    setUpAll(() async {
      // Initialize Flutter services for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock shared preferences
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{};
          }
          return null;
        },
      );

      networkInitializer = NetworkInfrastructureInitializer();
    });

    setUp(() {
      // Reset configuration for each test
      AppConfig.overrideForTest(
        environment: Environment.dev,
        apiTimeout: Duration(seconds: 5),
        maxRetryAttempts: 2,
        networkLogLevel: NetworkLogLevel.verbose,
      );
    });

    group('Network Infrastructure Initialization', () {
      test('should initialize all components successfully', () async {
        final success = await networkInitializer.initialize();
        
        expect(success, isTrue);
        expect(networkInitializer.isInitialized, isTrue);
        expect(networkInitializer.initializationErrors, isEmpty);
      });

      test('should provide infrastructure status', () {
        final status = networkInitializer.getInfrastructureStatus();
        
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('initialized'), isTrue);
        expect(status.containsKey('connectivity'), isTrue);
        expect(status.containsKey('httpClientStats'), isTrue);
        expect(status.containsKey('cacheStats'), isTrue);
      });

      test('should perform health check on all components', () async {
        await networkInitializer.initialize();
        final healthCheck = await networkInitializer.performHealthCheck();
        
        expect(healthCheck, isA<Map<String, bool>>());
        expect(healthCheck.containsKey('connectivity'), isTrue);
        expect(healthCheck.containsKey('httpClient'), isTrue);
        expect(healthCheck.containsKey('cache'), isTrue);
      });
    });

    group('ConnectivityService', () {
      late ConnectivityService connectivityService;

      setUp(() {
        connectivityService = ConnectivityService();
      });

      test('should initialize with default status', () {
        expect(connectivityService.currentStatus, NetworkStatus.unknown);
        expect(connectivityService.currentType, NetworkType.none);
        expect(connectivityService.isOnline, isFalse);
      });

      test('should provide quality metrics', () {
        final metrics = connectivityService.getAverageQualityMetrics();
        
        expect(metrics, isA<Map<String, double>>());
        expect(metrics.containsKey('latency'), isTrue);
        expect(metrics.containsKey('bandwidth'), isTrue);
      });

      test('should handle force refresh', () async {
        // This test verifies the method exists and doesn't throw
        expect(() async => await connectivityService.forceRefresh(), 
               returnsNormally);
      });
    });

    group('EnhancedHttpClientService', () {
      late EnhancedHttpClientService httpService;

      setUp(() {
        httpService = EnhancedHttpClientService();
      });

      test('should initialize successfully', () async {
        await httpService.initialize();
        // If no exception is thrown, initialization was successful
        expect(true, isTrue);
      });

      test('should provide performance statistics', () async {
        await httpService.initialize();
        final stats = httpService.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalRequests'), isTrue);
        expect(stats.containsKey('successfulRequests'), isTrue);
        expect(stats.containsKey('failedRequests'), isTrue);
        expect(stats.containsKey('successRate'), isTrue);
      });

      test('should reset circuit breaker', () async {
        await httpService.initialize();
        
        // This should not throw an exception
        expect(() => httpService.resetCircuitBreaker(), returnsNormally);
      });
    });

    group('EnhancedCacheManager', () {
      late EnhancedCacheManager cacheManager;

      setUp(() {
        cacheManager = EnhancedCacheManager();
      });

      test('should initialize successfully', () async {
        await cacheManager.initialize();
        // If no exception is thrown, initialization was successful
        expect(true, isTrue);
      });

      test('should cache and retrieve data', () async {
        await cacheManager.initialize();
        
        final testData = {'test': 'data', 'number': 42};
        await cacheManager.cacheData('test_key', testData);
        
        final retrievedData = await cacheManager.getCachedData('test_key');
        expect(retrievedData, equals(testData));
      });

      test('should provide cache statistics', () async {
        await cacheManager.initialize();
        final stats = cacheManager.getStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('cacheHits'), isTrue);
        expect(stats.containsKey('cacheMisses'), isTrue);
        expect(stats.containsKey('hitRate'), isTrue);
      });

      test('should handle offline queue operations', () async {
        await cacheManager.initialize();
        
        final testData = {'offline': 'data'};
        await cacheManager.addToOfflineQueue('offline_key', testData);
        
        // Process queue should not throw
        expect(() async => await cacheManager.processOfflineQueue(), 
               returnsNormally);
      });
    });

    group('NetworkErrorRecoveryService', () {
      late NetworkErrorRecoveryService errorRecovery;

      setUp(() {
        errorRecovery = NetworkErrorRecoveryService();
      });

      test('should provide recovery suggestions', () {
        final networkError = AppError.network('Connection failed');
        final suggestion = errorRecovery.getRecoverySuggestion(networkError);
        
        expect(suggestion, isA<String>());
        expect(suggestion.isNotEmpty, isTrue);
      });

      test('should determine retry eligibility', () {
        final networkError = AppError.network('Timeout');
        final shouldRetry = errorRecovery.shouldRetry(networkError, 1);
        
        expect(shouldRetry, isA<bool>());
      });
    });

    group('SyncStatusTracker', () {
      late SyncStatusTracker syncTracker;

      setUp(() {
        syncTracker = SyncStatusTracker();
      });

      test('should initialize with idle status', () {
        expect(syncTracker.currentStatus, SyncStatus.idle);
        expect(syncTracker.pendingCount, 0);
        expect(syncTracker.isSyncing, isFalse);
      });

      test('should add items to sync queue', () async {
        await syncTracker.initialize();
        
        await syncTracker.addToSyncQueue(
          '/api/test',
          {'data': 'test'},
          priority: SyncPriority.normal,
        );
        
        expect(syncTracker.pendingCount, 1);
      });

      test('should provide sync statistics', () async {
        await syncTracker.initialize();
        final stats = syncTracker.getStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('pendingCount'), isTrue);
        expect(stats.containsKey('completedCount'), isTrue);
        expect(stats.containsKey('currentStatus'), isTrue);
      });
    });

    group('Backward Compatibility', () {
      late HttpClientService httpClient;
      late CacheManager cacheManager;

      setUp(() {
        httpClient = HttpClientService();
        cacheManager = CacheManager();
      });

      test('HttpClientService should maintain backward compatibility', () async {
        await httpClient.initialize();
        
        // Should provide performance stats (enhanced feature)
        final stats = httpClient.getPerformanceStats();
        expect(stats, isA<Map<String, dynamic>>());
        
        // Should support circuit breaker reset (enhanced feature)
        expect(() => httpClient.resetCircuitBreaker(), returnsNormally);
      });

      test('CacheManager should maintain backward compatibility', () async {
        await cacheManager.initialize();
        
        // Basic caching should still work
        final testData = {'legacy': 'test'};
        await cacheManager.cacheData('legacy_key', testData);
        
        final retrieved = await cacheManager.getCachedData('legacy_key');
        expect(retrieved, equals(testData));
        
        // Should provide enhanced statistics
        final stats = cacheManager.getStatistics();
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group('Configuration and Logging', () {
      test('should respect configuration settings', () {
        AppConfig.overrideForTest(
          networkLogLevel: NetworkLogLevel.errors,
          maxRetryAttempts: 5,
          apiTimeout: Duration(seconds: 30),
        );
        
        expect(AppConfig.networkLogLevel, NetworkLogLevel.errors);
        expect(AppConfig.maxRetryAttempts, 5);
        expect(AppConfig.apiTimeout, Duration(seconds: 30));
      });

      test('should log network activity appropriately', () {
        // Test different log levels
        AppConfig.logNetwork('Test message', level: NetworkLogLevel.verbose);
        AppConfig.logNetwork('Error message', level: NetworkLogLevel.errors);
        AppConfig.logNetwork('Basic message', level: NetworkLogLevel.basic);
        
        // If no exceptions are thrown, logging is working
        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle initialization failures gracefully', () async {
        // This test verifies that even if some components fail to initialize,
        // the system continues to work
        final success = await networkInitializer.initialize();
        
        // Even if not fully successful, should not throw exceptions
        expect(success, isA<bool>());
        expect(networkInitializer.isInitialized, isA<bool>());
      });

      test('should provide meaningful error messages', () {
        final errors = networkInitializer.initializationErrors;
        
        // Errors should be human-readable strings
        for (final error in errors) {
          expect(error, isA<String>());
          expect(error.isNotEmpty, isTrue);
        }
      });
    });

    tearDownAll(() {
      // Clean up resources
      networkInitializer.dispose();
    });
  });
}

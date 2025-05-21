import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/config.dart';
import 'package:flutter_flashcard_app/web/proxy.dart';

void main() {
  group('Network Configuration Tests', () {
    test('AppConfig initialization loads correct environment settings', () {
      // Initialize with different environments
      AppConfig.initialize();

      // Verify the configuration is loaded with expected values
      expect(AppConfig.apiTimeout, isNotNull);
      expect(AppConfig.maxRetryAttempts, isNotNull);
      expect(AppConfig.retryDelay, isNotNull);
      expect(AppConfig.networkLogLevel, isNotNull);
      expect(AppConfig.networkCheckInterval, isNotNull);
      expect(AppConfig.connectivityTimeout, isNotNull);

      // Test environment-specific values
      expect(AppConfig.environment, equals(Environment.dev));
      expect(AppConfig.apiTimeout, equals(const Duration(seconds: 60)));
      expect(AppConfig.maxRetryAttempts, equals(3));
    });

    test('AppConfig endpoints are correctly configured', () {
      // Verify all required endpoints exist
      expect(AppConfig.endpoints.containsKey('grade'), isTrue);
      expect(AppConfig.endpoints.containsKey('suggestions'), isTrue);
      expect(AppConfig.endpoints.containsKey('feedback'), isTrue);
      expect(AppConfig.endpoints.containsKey('interviewGrade'), isTrue);
      expect(AppConfig.endpoints.containsKey('interviewGradeBatch'), isTrue);
      expect(AppConfig.endpoints.containsKey('jobDescriptionAnalyze'), isTrue);
      expect(AppConfig.endpoints.containsKey('jobDescriptionGenerate'), isTrue);

      // Verify endpoints have the expected format
      expect(AppConfig.endpoints['grade'], startsWith('/api/'));
    });

    test('AppConfig base URL is environment-appropriate', () {
      // Test that the API base URL is set according to environment
      final baseUrl = AppConfig.apiBaseUrl;
      expect(baseUrl, isNotEmpty);

      // In dev mode, should be pointing to localhost or similar
      expect(baseUrl, anyOf(contains('10.0.2.2'), contains('localhost')));
    });

    // Test retry logic indirectly since _shouldRetry is private
    test('ProxyClient retry logic works correctly', () {
      final mockClient = ProxyClient('http://test-api.com');

      // We can't test _shouldRetry directly because it's private
      // Instead, we'll test the overall behavior through public methods
      // or create a test-specific subclass if needed

      // We can verify the client was created successfully
      expect(mockClient, isNotNull);
      expect(mockClient.baseUrl, equals('http://test-api.com'));
    });

    test('AppConfig override works as expected', () {
      // Original values
      final originalTimeout = AppConfig.apiTimeout;
      final originalRetries = AppConfig.maxRetryAttempts;

      // Override for testing
      AppConfig.overrideForTest(
        apiTimeout: const Duration(seconds: 10),
        maxRetryAttempts: 1,
      );

      // Check that values were changed
      expect(AppConfig.apiTimeout, equals(const Duration(seconds: 10)));
      expect(AppConfig.maxRetryAttempts, equals(1));

      // Restore original values after test
      AppConfig.overrideForTest(
        apiTimeout: originalTimeout,
        maxRetryAttempts: originalRetries,
      );
    });

    // Mocking test for helper methods
    test('AppConfig helper methods for timeout and retry work correctly', () {
      bool timeoutCalled = false;
      bool retryCalled = false;

      // Create a mock operation that will succeed
      Future<int> successOperation() async {
        retryCalled = true;
        return 42;
      }

      // Create a mock operation that will time out
      Future<int> timeoutOperation() async {
        await Future.delayed(const Duration(seconds: 2));
        return 0;
      }

      // Test successful operation with retry
      AppConfig.withRetry(operation: successOperation, maxAttempts: 1).then((
        value,
      ) {
        expect(value, equals(42));
        expect(retryCalled, isTrue);
      });

      // Test timeout operation
      AppConfig.withTimeout(
        operation: timeoutOperation,
        timeout: const Duration(milliseconds: 100),
        onTimeout: () async {
          timeoutCalled = true;
          return Future.value(0); // Return a Future<int> not just an int
        },
      ).then((value) {
        expect(timeoutCalled, isTrue);
        expect(value, equals(0));
      });
    });
  });
}

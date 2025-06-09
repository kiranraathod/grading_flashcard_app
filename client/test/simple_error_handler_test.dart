// test/simple_error_handler_test.dart
// Quick test to verify SimpleErrorHandler functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/services/simple_error_handler.dart';

void main() {
  group('SimpleErrorHandler Tests', () {
    test('should handle successful operations', () async {
      final result = await SimpleErrorHandler.safe(
        () async => 'success',
        operationName: 'test_success',
      );

      expect(result, equals('success'));
    });

    test('should use fallback value on error', () async {
      final result = await SimpleErrorHandler.safe(
        () async => throw Exception('test error'),
        fallback: 'fallback_value',
        operationName: 'test_fallback',
      );

      expect(result, equals('fallback_value'));
    });

    test('should use fallback operation on error', () async {
      final result = await SimpleErrorHandler.safe(
        () async => throw Exception('primary failed'),
        fallbackOperation: () async => 'fallback_operation_result',
        operationName: 'test_fallback_operation',
      );

      expect(result, equals('fallback_operation_result'));
    });

    test('should handle sync operations', () {
      final result = SimpleErrorHandler.safeSync(
        () => 'sync_success',
        operationName: 'test_sync',
      );

      expect(result, equals('sync_success'));
    });

    test('should use sync fallback on error', () {
      final result = SimpleErrorHandler.safeSync(
        () => throw Exception('sync error'),
        fallback: 'sync_fallback',
        operationName: 'test_sync_fallback',
      );

      expect(result, equals('sync_fallback'));
    });

    test('should handle void operations safely', () async {
      bool operationCalled = false;

      await SimpleErrorHandler.safely(() async {
        operationCalled = true;
      }, operationName: 'test_void');

      expect(operationCalled, isTrue);
    });

    test('should handle retries', () async {
      int attemptCount = 0;

      final result = await SimpleErrorHandler.safe(
        () async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('attempt $attemptCount failed');
          }
          return 'success_on_attempt_$attemptCount';
        },
        retryCount: 2,
        operationName: 'test_retry',
      );

      expect(result, equals('success_on_attempt_3'));
      expect(attemptCount, equals(3));
    });
  });
}

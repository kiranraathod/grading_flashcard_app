# Task 2.2: Error Handling Standardization Implementation

## Priority Level
⚠️ **HIGH PRIORITY** - Must be completed after Task 2.1

## Overview
Standardize error handling patterns across all services to eliminate inconsistent error behavior that could cause unpredictable migration failures.

## Prerequisites
- ✅ Task 2.1 completed (System Stability Analysis)
- ✅ Root causes of system instability identified and addressed
- ✅ ReliableStorageService implemented and tested

## Background
**Current Error Handling Inconsistencies:**
```dart
// Pattern 1: Silent failure (bad)
catch (e) { debugPrint('Error: $e'); }

// Pattern 2: Proper logging (good)  
catch (e, stackTrace) { /* comprehensive logging */ }

// Pattern 3: Fallback strategy (good)
catch (e) { return fallbackData(); }

// Pattern 4: Error propagation (good)
catch (e) { throw AppError.from(e); }
```

**Risk for Migration:**
- Inconsistent error handling makes debugging migration issues difficult
- Silent failures could hide critical migration problems
- Unpredictable error behavior during migration process

## Implementation Steps

### Step 1: Create Standardized Error Handling Framework
Create `lib/utils/error_handling_framework.dart`:

```dart
/// Standardized error handling framework for consistent behavior
class ErrorHandlingFramework {
  static final ErrorReportingService _reporting = ErrorReportingService();
  
  /// Handle async service operations with consistent error management
  static Future<ServiceResult<T>> handleServiceOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    T? fallbackValue,
    ErrorSeverity severity = ErrorSeverity.error,
    bool enableRetry = false,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int attemptCount = 0;
    
    while (attemptCount <= (enableRetry ? maxRetries : 0)) {
      try {
        final result = await operation();
        
        // Log successful operation if it took multiple attempts
        if (attemptCount > 0) {
          _reporting.logInfo('$operationName succeeded after ${attemptCount + 1} attempts');
        }
        
        return ServiceResult.success(result);
        
      } catch (error, stackTrace) {
        attemptCount++;
        
        final context = ErrorContext(
          operation: operationName,
          attempt: attemptCount,
          maxAttempts: enableRetry ? maxRetries + 1 : 1,
          severity: severity,
          timestamp: DateTime.now(),
        );
        
        // Log the error with full context
        await _reporting.logError(error, stackTrace, context);
        
        // Decide whether to retry or fail
        if (enableRetry && attemptCount <= maxRetries) {
          await Future.delayed(retryDelay * attemptCount); // Exponential backoff
          continue;
        }
        
        // Final failure - return appropriate result
        if (fallbackValue != null) {
          _reporting.logWarning('$operationName using fallback value after failure');
          return ServiceResult.success(fallbackValue);
        }
        
        return ServiceResult.failure(
          StandardError.fromException(error, context),
        );
      }
    }
    
    // Should never reach here, but safety fallback
    return ServiceResult.failure(
      StandardError.unknown('Unexpected error handling failure', operationName),
    );
  }
  
  /// Handle synchronous operations with consistent error management
  static ServiceResult<T> handleSyncOperation<T>(
    String operationName,
    T Function() operation, {
    T? fallbackValue,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    try {
      final result = operation();
      return ServiceResult.success(result);
      
    } catch (error, stackTrace) {
      final context = ErrorContext(
        operation: operationName,
        attempt: 1,
        maxAttempts: 1,
        severity: severity,
        timestamp: DateTime.now(),
      );
      
      // Log error synchronously
      _reporting.logErrorSync(error, stackTrace, context);
      
      if (fallbackValue != null) {
        _reporting.logWarning('$operationName using fallback value');
        return ServiceResult.success(fallbackValue);
      }
      
      return ServiceResult.failure(
        StandardError.fromException(error, context),
      );
    }
  }
  
  /// Handle data validation operations
  static ValidationResult handleValidationOperation(
    String operationName,
    bool Function() validation,
    String validationMessage,
  ) {
    try {
      final isValid = validation();
      return ValidationResult(
        isValid: isValid,
        message: isValid ? 'Validation passed' : validationMessage,
        operation: operationName,
      );
    } catch (error, stackTrace) {
      _reporting.logErrorSync(error, stackTrace, ErrorContext(
        operation: operationName,
        severity: ErrorSeverity.warning,
        timestamp: DateTime.now(),
      ));
      
      return ValidationResult(
        isValid: false,
        message: 'Validation failed due to error: $error',
        operation: operationName,
      );
    }
  }
}

/// Generic service result wrapper
class ServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final StandardError? error;
  
  ServiceResult.success(this.data) : isSuccess = true, error = null;
  ServiceResult.failure(this.error) : isSuccess = false, data = null;
  
  /// Get data or throw if failed
  T get() {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? StandardError.unknown('No data available', 'ServiceResult.get');
  }
  
  /// Get data or return fallback
  T getOrElse(T fallback) {
    return isSuccess && data != null ? data! : fallback;
  }
}

/// Standardized error representation
class StandardError {
  final String message;
  final String operation;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final dynamic originalError;
  
  StandardError({
    required this.message,
    required this.operation,
    this.severity = ErrorSeverity.error,
    DateTime? timestamp,
    this.metadata = const {},
    this.originalError,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory StandardError.fromException(dynamic exception, ErrorContext context) {
    return StandardError(
      message: exception.toString(),
      operation: context.operation,
      severity: context.severity,
      timestamp: context.timestamp,
      metadata: {
        'attempt': context.attempt,
        'max_attempts': context.maxAttempts,
      },
      originalError: exception,
    );
  }
  
  factory StandardError.unknown(String message, String operation) {
    return StandardError(
      message: message,
      operation: operation,
      severity: ErrorSeverity.error,
    );
  }
  
  @override
  String toString() => 'StandardError($operation): $message';
}

/// Error context for logging and debugging
class ErrorContext {
  final String operation;
  final int attempt;
  final int maxAttempts;
  final ErrorSeverity severity;
  final DateTime timestamp;
  
  ErrorContext({
    required this.operation,
    this.attempt = 1,
    this.maxAttempts = 1,
    this.severity = ErrorSeverity.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,  
  error,
  critical,
}

/// Validation result wrapper
class ValidationResult {
  final bool isValid;
  final String message;
  final String operation;
  
  ValidationResult({
    required this.isValid,
    required this.message,
    required this.operation,
  });
}
```

### Step 2: Create Error Reporting Service
Create `lib/services/error_reporting_service.dart`:

```dart
class ErrorReportingService {
  static const String _logTag = '[ERROR_REPORTING]';
  
  /// Log error with full context
  Future<void> logError(
    dynamic error, 
    StackTrace stackTrace, 
    ErrorContext context,
  ) async {
    final errorReport = _createErrorReport(error, stackTrace, context);
    
    // Console logging
    _logToConsole(errorReport);
    
    // Store for later analysis
    await _storeErrorReport(errorReport);
    
    // In production, send to error reporting service
    // await _sendToErrorService(errorReport);
  }
  
  /// Log error synchronously
  void logErrorSync(
    dynamic error, 
    StackTrace stackTrace, 
    ErrorContext context,
  ) {
    final errorReport = _createErrorReport(error, stackTrace, context);
    _logToConsole(errorReport);
    
    // Store asynchronously without blocking
    _storeErrorReport(errorReport).catchError((e) {
      print('Failed to store error report: $e');
    });
  }
  
  /// Log warning message
  void logWarning(String message, [String? operation]) {
    final timestamp = DateTime.now().toIso8601String();
    print('$_logTag ⚠️ [$timestamp] ${operation != null ? '$operation: ' : ''}$message');
  }
  
  /// Log info message
  void logInfo(String message, [String? operation]) {
    final timestamp = DateTime.now().toIso8601String();
    print('$_logTag ℹ️ [$timestamp] ${operation != null ? '$operation: ' : ''}$message');
  }
  
  ErrorReport _createErrorReport(
    dynamic error, 
    StackTrace stackTrace, 
    ErrorContext context,
  ) {
    return ErrorReport(
      error: error,
      stackTrace: stackTrace,
      context: context,
      deviceInfo: _getDeviceInfo(),
      appVersion: '1.0.0', // Get from package info
      timestamp: DateTime.now(),
    );
  }
  
  void _logToConsole(ErrorReport report) {
    final severity = _getSeverityIcon(report.context.severity);
    final timestamp = report.timestamp.toIso8601String();
    
    print('$_logTag $severity [$timestamp] ${report.context.operation}');
    print('  Error: ${report.error}');
    print('  Attempt: ${report.context.attempt}/${report.context.maxAttempts}');
    
    if (report.context.severity == ErrorSeverity.critical) {
      print('  Stack Trace:');
      print('    ${report.stackTrace.toString().replaceAll('\n', '\n    ')}');
    }
  }
  
  String _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }
  
  Future<void> _storeErrorReport(ErrorReport report) async {
    try {
      final storage = ReliableStorageService();
      final errorId = 'error_${report.timestamp.millisecondsSinceEpoch}';
      await storage.set(errorId, jsonEncode(report.toJson()));
      
      // Keep only last 100 error reports
      await _cleanupOldErrorReports();
    } catch (e) {
      // Don't let error logging fail the application
      print('Failed to store error report: $e');
    }
  }
  
  Map<String, dynamic> _getDeviceInfo() {
    // Simplified device info - would use device_info package in production
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Future<void> _cleanupOldErrorReports() async {
    // Implementation to remove old error reports
    // Keep storage usage under control
  }
}

class ErrorReport {
  final dynamic error;
  final StackTrace stackTrace;
  final ErrorContext context;
  final Map<String, dynamic> deviceInfo;
  final String appVersion;
  final DateTime timestamp;
  
  ErrorReport({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.deviceInfo,
    required this.appVersion,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'error': error.toString(),
    'stack_trace': stackTrace.toString(),
    'operation': context.operation,
    'attempt': context.attempt,
    'severity': context.severity.name,
    'device_info': deviceInfo,
    'app_version': appVersion,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

### Step 3: Refactor Existing Services
Update existing services to use standardized error handling:

#### Example: FlashcardService Refactoring
```dart
class FlashcardService extends ChangeNotifier {
  // Replace existing error handling with standardized approach
  
  Future<void> _loadSets() async {
    final result = await ErrorHandlingFramework.handleServiceOperation(
      'FlashcardService._loadSets',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final setsJson = prefs.getStringList('flashcard_sets');
        
        if (setsJson != null && setsJson.isNotEmpty) {
          _sets.clear();
          for (final setJson in setsJson) {
            final Map<String, dynamic> data = json.decode(setJson);
            _sets.add(FlashcardSet.fromJson(data));
          }
        } else {
          // Load default data from server
          await _loadDefaultData();
        }
        
        return _sets.length;
      },
      enableRetry: true,
      maxRetries: 3,
      severity: ErrorSeverity.critical,
    );
    
    if (result.isSuccess) {
      debugPrint('Loaded ${result.data} flashcard sets successfully');
      notifyListeners();
    } else {
      // Handle failure - maybe show user-friendly error
      debugPrint('Failed to load flashcard sets: ${result.error}');
      await _loadMinimalFallbackData();
      notifyListeners();
    }
  }
  
  Future<void> createFlashcardSet(FlashcardSet set) async {
    final result = await ErrorHandlingFramework.handleServiceOperation(
      'FlashcardService.createFlashcardSet',
      () async {
        _sets.add(set);
        await _saveSets();
        return set.id;
      },
      severity: ErrorSeverity.error,
    );
    
    if (result.isSuccess) {
      notifyListeners();
    } else {
      // Rollback the addition if save failed
      _sets.removeWhere((s) => s.id == set.id);
      throw Exception('Failed to create flashcard set: ${result.error}');
    }
  }
}
```

## Acceptance Criteria

- [ ] **Consistent Error Patterns**: All services use ErrorHandlingFramework
- [ ] **Comprehensive Logging**: All errors logged with full context
- [ ] **Retry Logic**: Appropriate retry mechanisms for transient failures
- [ ] **Fallback Strategies**: Graceful degradation when operations fail
- [ ] **Error Reporting**: Centralized error collection and analysis
- [ ] **Migration Safety**: Error handling won't hide migration issues
- [ ] **Debugging Support**: Clear error context for troubleshooting
- [ ] **Performance Impact**: Error handling doesn't degrade performance

## Testing Instructions

1. **Test error handling consistency:**
   ```dart
   // Test all services use standardized error handling
   final services = [FlashcardService(), InterviewService(), /* ... */];
   for (final service in services) {
     await _testServiceErrorHandling(service);
   }
   ```

2. **Test retry mechanisms:**
   - Simulate transient failures
   - Verify retry logic works correctly
   - Confirm exponential backoff behavior

3. **Test error reporting:**
   - Trigger various error types
   - Verify all errors are logged with proper context
   - Confirm error storage and cleanup works

4. **Test fallback behavior:**
   - Cause service failures
   - Verify graceful degradation
   - Confirm user experience remains functional

## Implementation Timeline

**Days 1-2**: Framework Implementation
- Create ErrorHandlingFramework
- Implement ErrorReportingService
- Test core framework functionality

**Days 3-4**: Service Refactoring
- Refactor FlashcardService
- Refactor InterviewService  
- Refactor CacheManager
- Refactor RecentViewService

**Day 5**: Testing & Validation
- Comprehensive error handling testing
- Performance impact assessment
- Migration safety verification

## Expected Improvements

After standardization:
- **Predictable Error Behavior**: All services handle errors consistently
- **Better Debugging**: Rich error context for troubleshooting
- **Migration Safety**: Errors won't be silently ignored during migration
- **User Experience**: Graceful degradation instead of crashes
- **Maintenance**: Easier to identify and fix error patterns

## Next Steps
After completing this task:
- Error handling is predictable and migration-safe
- Proceed to Task 3.1: Authentication Foundation
- Begin migration with confidence in error handling

## Dependencies
- Task 2.1 (System Stability Analysis) completed
- ReliableStorageService operational
- All existing services available for refactoring
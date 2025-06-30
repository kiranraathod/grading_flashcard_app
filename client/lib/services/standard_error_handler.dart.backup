import 'package:flutter/foundation.dart';

/// Centralized error logging with consistent format across all services
/// Replaces scattered debugPrint() and inconsistent error handling patterns
enum ErrorLevel { debug, info, warning, error, critical }

class StandardErrorHandler {
  static final StandardErrorHandler _instance = StandardErrorHandler._internal();
  factory StandardErrorHandler() => _instance;
  StandardErrorHandler._internal();

  /// Log error with stack trace and context
  void logError(
    String operationName,
    dynamic error,
    StackTrace? stackTrace, {
    ErrorLevel level = ErrorLevel.error,
    Map<String, dynamic>? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelIcon = _getLevelIcon(level);
    final levelName = level.name.toUpperCase();
    
    String message = '[$timestamp] $levelIcon $levelName [$operationName]: $error';
    
    if (context != null && context.isNotEmpty) {
      message += '\n  Context: $context';
    }
    
    if (stackTrace != null && level.index >= ErrorLevel.error.index) {
      message += '\n  Stack Trace: ${stackTrace.toString().split('\n').take(5).join('\n')}';
    }
    
    _printMessage(message, level);
  }

  /// Log informational message
  void logInfo(String operationName, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp] ℹ️ INFO [$operationName]: $message';
    
    if (context != null && context.isNotEmpty) {
      logMessage += '\n  Context: $context';
    }
    
    _printMessage(logMessage, ErrorLevel.info);
  }

  /// Log success message
  void logSuccess(String operationName, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp] ✅ SUCCESS [$operationName]: $message';
    
    if (context != null && context.isNotEmpty) {
      logMessage += '\n  Context: $context';
    }
    
    _printMessage(logMessage, ErrorLevel.info);
  }

  /// Log warning message
  void logWarning(String operationName, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp] ⚠️ WARNING [$operationName]: $message';
    
    if (context != null && context.isNotEmpty) {
      logMessage += '\n  Context: $context';
    }
    
    _printMessage(logMessage, ErrorLevel.warning);
  }

  /// Log debug message (only in debug mode)
  void logDebug(String operationName, String message, {Map<String, dynamic>? context}) {
    if (!kDebugMode) return;
    
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp] 🐛 DEBUG [$operationName]: $message';
    
    if (context != null && context.isNotEmpty) {
      logMessage += '\n  Context: $context';
    }
    
    _printMessage(logMessage, ErrorLevel.debug);
  }

  /// Get icon for error level
  String _getLevelIcon(ErrorLevel level) {
    switch (level) {
      case ErrorLevel.debug:
        return '🐛';
      case ErrorLevel.info:
        return 'ℹ️';
      case ErrorLevel.warning:
        return '⚠️';
      case ErrorLevel.error:
        return '❌';
      case ErrorLevel.critical:
        return '💀';
    }
  }

  /// Print message based on level
  void _printMessage(String message, ErrorLevel level) {
    if (kDebugMode) {
      // In debug mode, print all messages
      debugPrint(message);
    } else {
      // In release mode, only print warnings and above
      if (level.index >= ErrorLevel.warning.index) {
        debugPrint(message);
      }
    }
    
    // NOTE: For production deployment, integrate with error reporting service (e.g., Sentry, Crashlytics)
    // if (level.index >= ErrorLevel.error.index) {
    //   ErrorReporting.recordError(message, level);
    // }
  }
}

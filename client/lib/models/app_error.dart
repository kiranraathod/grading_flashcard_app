import 'package:equatable/equatable.dart';

enum ErrorSeverity {
  info,     // Informational only, doesn't affect functionality
  warning,  // Functionality partially affected
  error,    // Functionality completely affected
  critical, // Application cannot continue
}

enum ErrorSource {
  network,  // Network-related errors
  api,      // API-related errors
  database, // Local data storage errors
  ui,       // UI-related errors
  system,   // System-level errors
  unknown,  // Unknown source
}

class AppError extends Equatable {
  final String code;
  final String message;
  final String? details;
  final ErrorSeverity severity;
  final ErrorSource source;
  final dynamic exception;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  
  // Removed const keyword from constructor since we use DateTime.now()
  AppError({
    required this.code,
    required this.message,
    this.details,
    required this.severity,
    required this.source,
    this.exception,
    this.stackTrace,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  List<Object?> get props => [
    code, 
    message, 
    details, 
    severity, 
    source,
    timestamp,
  ];
  
  String get userFriendlyMessage {
    // Return a user-friendly version of the error message
    switch (source) {
      case ErrorSource.network:
        return 'There was a problem connecting to the server. Please check your internet connection and try again.';
      case ErrorSource.api:
        return 'There was a problem with the server. Please try again later.';
      case ErrorSource.database:
        return 'There was a problem loading your data. Please restart the app.';
      case ErrorSource.ui:
        return 'There was a problem with the app. Please try again.';
      case ErrorSource.system:
        return 'There was a system error. Please restart the app.';
      case ErrorSource.unknown:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  String get actionableAdvice {
    // Return actionable advice based on the error type
    switch (code) {
      case 'network_unavailable':
        return 'Check your internet connection and try again.';
      case 'server_unreachable':
        return 'Our servers might be temporarily unavailable. Please try again in a few minutes.';
      case 'api_timeout':
        return 'The server took too long to respond. Try again when you have a stronger connection.';
      case 'invalid_response':
        return 'We received an unexpected response from the server. Try refreshing the app.';
      default:
        return severity == ErrorSeverity.critical 
            ? 'Please restart the app.' 
            : 'Please try again.';
    }
  }
  
  // Factory methods for common errors
  factory AppError.network(String message, {
    String? details,
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      code: 'network_error',
      message: message,
      details: details,
      severity: ErrorSeverity.warning,
      source: ErrorSource.network,
      exception: exception,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  factory AppError.api(String message, {
    String? details,
    String code = 'api_error',
    ErrorSeverity severity = ErrorSeverity.warning,
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      code: code,
      message: message,
      details: details,
      severity: severity,
      source: ErrorSource.api,
      exception: exception,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  factory AppError.data(String message, {
    String? details,
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      code: 'data_error',
      message: message,
      details: details,
      severity: ErrorSeverity.warning,
      source: ErrorSource.database,
      exception: exception,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  factory AppError.unknown(dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      code: 'unknown_error',
      message: exception?.toString() ?? 'Unknown error',
      severity: ErrorSeverity.error,
      source: ErrorSource.unknown,
      exception: exception,
      stackTrace: stackTrace,
      context: context,
    );
  }
}
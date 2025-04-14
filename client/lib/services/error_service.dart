import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

class ErrorService {
  // Singleton instance
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();
  
  // Error stream for global error handling
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorStreamController.stream;
  
  // Error history
  final List<AppError> _errorHistory = [];
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  
  // Report error
  void reportError(AppError error) {
    debugPrint('Error reported: ${error.code} - ${error.message}');
    
    // Add to history
    _errorHistory.add(error);
    
    // Broadcast error
    _errorStreamController.add(error);
    
    // Log error (could integrate with a logging service)
    _logError(error);
    
    // Analytics tracking (could integrate with analytics service)
    _trackError(error);
  }
  
  // Log error
  void _logError(AppError error) {
    // In a real app, this could send errors to a logging service
    if (kDebugMode) {
      debugPrint('------ ERROR ------');
      debugPrint('Code: ${error.code}');
      debugPrint('Message: ${error.message}');
      debugPrint('Details: ${error.details}');
      debugPrint('Severity: ${error.severity}');
      debugPrint('Source: ${error.source}');
      debugPrint('Timestamp: ${error.timestamp}');
      if (error.exception != null) {
        debugPrint('Exception: ${error.exception}');
      }
      if (error.stackTrace != null) {
        debugPrint('StackTrace: ${error.stackTrace}');
      }
      debugPrint('-------------------');
    }
  }
  
  // Track error in analytics
  void _trackError(AppError error) {
    // In a real app, this would send the error to an analytics service
    // For example: FirebaseAnalytics.instance.logEvent(...);
  }
  
  // Clear error history (for testing or privacy)
  void clearErrorHistory() {
    _errorHistory.clear();
  }
  
  // Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}
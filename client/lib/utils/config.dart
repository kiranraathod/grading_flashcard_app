import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Environment enum for different application environments
enum Environment { dev, staging, prod }

// Network log level enum
enum NetworkLogLevel { none, errors, basic, verbose }

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  // Current environment setting
  static Environment _environment = Environment.dev;
  static Environment get environment => _environment;
  
  // Network configuration
  static Duration apiTimeout = const Duration(seconds: 60);
  static int maxRetryAttempts = 3;
  static Duration retryDelay = const Duration(seconds: 2);
  static NetworkLogLevel networkLogLevel = NetworkLogLevel.basic;
  
  // Connection configuration
  static Duration networkCheckInterval = const Duration(seconds: 30);
  static Duration connectivityTimeout = const Duration(seconds: 5);
  
  // API endpoints (moved from Constants)
  static Map<String, String> endpoints = {
    'grade': '/api/grade',
    'suggestions': '/api/suggestions',
    'feedback': '/api/feedback',
    'interviewGrade': '/api/interview-grade',
    'interviewGradeBatch': '/api/interview-grade-batch',
    'jobDescriptionAnalyze': '/api/job-description/analyze',
    'jobDescriptionGenerate': '/api/job-description/generate-questions',
    'ping': '/api/ping',
    'defaultData': '/api/default-data/',
    'defaultFlashcardSets': '/api/default-data/flashcard-sets',
    'defaultInterviewQuestions': '/api/default-data/interview-questions',
    'defaultCategories': '/api/default-data/categories',
    'defaultCategoryCounts': '/api/default-data/category-counts',
    'defaultDataHealth': '/api/default-data/health',
  };
  
  // API base URL configuration (moved from Constants)
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Point to the proxy server for web
    } else {
      switch (_environment) {
        case Environment.prod:
          return 'https://api.flashmaster.app';
        case Environment.staging:
          return 'https://staging-api.flashmaster.app';
        case Environment.dev:
          return 'http://10.0.2.2:5000';
      }
    }
  }
  
  // HTTP headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Version': '1.0.0',
    'X-Environment': _environment.toString().split('.').last,
  };
  
  // Algorithm configuration
  static const double strongMatchThreshold = 0.8;
  static const double partialMatchThreshold = 0.5;
  static const double keyElementsMatchThreshold = 0.3;
  
  // Storage keys
  static const String flashcardSetsKey = 'flashcard_sets';
  static const String userStreakKey = 'weeklyStreak';
  
  // Initialize configuration based on environment
  static void initialize() {
    _environment = _determineEnvironment();
    _loadEnvironmentSettings();
    debugPrint('AppConfig initialized with environment: $_environment');
  }
  
  // Determine the environment based on compile-time flag
  static Environment _determineEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    switch (flavor) {
      case 'prod': return Environment.prod;
      case 'staging': return Environment.staging;
      default: return Environment.dev;
    }
  }
  
  // Load settings specific to the current environment
  static void _loadEnvironmentSettings() {
    switch (_environment) {
      case Environment.dev:
        apiTimeout = const Duration(seconds: 60);
        maxRetryAttempts = 3;
        retryDelay = const Duration(seconds: 2);
        networkLogLevel = NetworkLogLevel.verbose;
        networkCheckInterval = const Duration(seconds: 30);
        connectivityTimeout = const Duration(seconds: 5);
        break;
        
      case Environment.staging:
        apiTimeout = const Duration(seconds: 45);
        maxRetryAttempts = 2;
        retryDelay = const Duration(seconds: 1);
        networkLogLevel = NetworkLogLevel.basic;
        networkCheckInterval = const Duration(seconds: 60);
        connectivityTimeout = const Duration(seconds: 3);
        break;
        
      case Environment.prod:
        apiTimeout = const Duration(seconds: 30);
        maxRetryAttempts = 1;
        retryDelay = const Duration(seconds: 1);
        networkLogLevel = NetworkLogLevel.errors;
        networkCheckInterval = const Duration(seconds: 120);
        connectivityTimeout = const Duration(seconds: 3);
        break;
    }
  }
  
  // Helper for timeout with retry functionality
  static Future<T> withTimeout<T>({
    required Future<T> Function() operation,
    Duration? timeout,
    Future<T> Function()? onTimeout,
    String context = 'operation',
  }) async {
    timeout ??= apiTimeout;
    
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (_) {
      debugPrint('$context timed out after ${timeout.inSeconds} seconds');
      
      if (onTimeout != null) {
        return await onTimeout();
      }
      
      rethrow;
    }
  }
  
  // Helper for retry functionality
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int? maxAttempts,
    Duration? delay,
    bool Function(Exception)? retryIf,
    String context = 'operation',
  }) async {
    maxAttempts ??= maxRetryAttempts;
    delay ??= retryDelay;
    
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        attempts++;
        return await operation();
      } on Exception catch (e) {
        final bool shouldRetry = retryIf != null ? retryIf(e) : true;
        
        if (attempts >= maxAttempts || !shouldRetry) {
          rethrow;
        }
        
        debugPrint('$context failed (attempt $attempts/$maxAttempts): $e');
        debugPrint('Retrying in ${delay.inSeconds} seconds...');
        
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Failed after $maxAttempts attempts');
  }
  
  // Configure for tests
  static void overrideForTest({
    Environment? environment,
    Duration? apiTimeout,
    int? maxRetryAttempts,
    Duration? retryDelay,
    NetworkLogLevel? networkLogLevel,
    Duration? networkCheckInterval,
    Duration? connectivityTimeout,
    Map<String, String>? endpoints,
    String? apiBaseUrlOverride,
  }) {
    if (environment != null) _environment = environment;
    if (apiTimeout != null) AppConfig.apiTimeout = apiTimeout;
    if (maxRetryAttempts != null) AppConfig.maxRetryAttempts = maxRetryAttempts;
    if (retryDelay != null) AppConfig.retryDelay = retryDelay;
    if (networkLogLevel != null) AppConfig.networkLogLevel = networkLogLevel;
    if (networkCheckInterval != null) AppConfig.networkCheckInterval = networkCheckInterval;
    if (connectivityTimeout != null) AppConfig.connectivityTimeout = connectivityTimeout;
    if (endpoints != null) {
      AppConfig.endpoints = {
        ...AppConfig.endpoints,
        ...endpoints,
      };
    }
  }
  
  // Log network activity based on current log level setting
  static void logNetwork(String message, {NetworkLogLevel level = NetworkLogLevel.basic}) {
    if (level.index <= networkLogLevel.index) {
      debugPrint('[Network] $message');
    }
  }
}
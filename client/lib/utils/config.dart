import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Environment enum for different application environments
enum Environment { dev, staging, prod }

// Network log level enum
enum NetworkLogLevel { none, errors, basic, verbose }

// Authentication configuration
class AuthConfig {
  // Feature flags - ENABLED for unified authentication
  static bool enableAuthentication = true;
  static bool enableUsageLimits = true;
  static bool enableGuestTracking = true;
  static bool enableProfileMenu = true;
  
  // 🎯 COMBINED QUOTA SYSTEM: 
  // - Guests: 3 total actions across all features
  // - Authenticated: 5 total actions across all features
  // (Individual limits are set dynamically in UnifiedActionTracker)
  
  // Legacy configuration values (kept for compatibility)
  static int guestMaxGradingActions = 3;        
  static int guestMaxInterviewActions = 3;      
  static int guestMaxContentGeneration = 2;     
  static int guestMaxAiAssistance = 3;          
  
  static int authenticatedMaxGradingActions = 5; 
  static int authenticatedMaxInterviewActions = 5; 
  static int authenticatedMaxContentGeneration = 10; 
  static int authenticatedMaxAiAssistance = 15;
  
  // Supabase configuration
  static const String supabaseUrl = 'https://saxopupmwfcfjxuflfrx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNheG9wdXBtd2ZjZmp4dWZsZnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxOTU1NjgsImV4cCI6MjA2NDc3MTU2OH0.1RdIw1v9FG76LJz7SNZY5YW51dcRP4XVCPCBLRgTXVU';
  
  // Authentication flow configuration
  static Duration authSessionTimeout = const Duration(hours: 24);
  static bool requireEmailVerification = false; // Disable for development
  static bool enableSocialLogin = true;
  static bool enableEmailAuth = true;
  static bool enableAnonymousAuth = true; // Enable guest user support
  
  // Development flags
  static bool enableAuthDebugLogging = false; // 🔇 Disabled for clean logs
  static bool skipEmailVerification = true;
  static bool enableDemoMode = true; // Enable demo authentication for testing
  
  // Migration settings
  static bool enableLegacyMigration = true; // Support migration from SharedPreferences
  static bool autoMigrateGuestData = true;  // Automatically migrate guest data on auth
}

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  // Current environment setting
  static Environment _environment = Environment.dev;
  static Environment get environment => _environment;
  
  // Network configuration - OPTIMIZED FOR CLEAN LOGGING
  static Duration apiTimeout = const Duration(seconds: 30);     // Reduced timeout
  static int maxRetryAttempts = 1;                              // Minimal retries  
  static Duration retryDelay = const Duration(seconds: 2);      // Quick retry
  static NetworkLogLevel networkLogLevel = NetworkLogLevel.none; // 🔇 No network logs
  
  // Connection configuration - REDUCED FREQUENCY
  static Duration networkCheckInterval = const Duration(minutes: 10); // 🔧 Reduced from 5 to 10 minutes
  static Duration connectivityTimeout = const Duration(seconds: 5);
  
  // API endpoints (moved from Constants)
  static Map<String, String> endpoints = {
    'grade': '/api/grade',
    'suggestions': '/api/suggestions',
    'feedback': '/api/feedback',
    'interviewGrade': '/api/interview-grade',
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
      // 🚀 CONNECT TO PRODUCTION BACKEND - Live API with database integration
      return 'https://grading-app-5o9m.onrender.com';
    } else {
      switch (_environment) {
        case Environment.prod:
          return 'https://grading-app-5o9m.onrender.com'; // Production backend
        case Environment.staging:
          return 'https://grading-app-5o9m.onrender.com'; // Use same backend for staging
        case Environment.dev:
          return 'https://grading-app-5o9m.onrender.com'; // Use production backend for dev too
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
  
  // UI/UX Timing Configuration - Phase 4: Centralized timing constants
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Button feedback and UI responsiveness
  static const Duration buttonFeedback = Duration(milliseconds: 100);
  static const Duration modalAnimation = Duration(milliseconds: 250);
  static const Duration themeTransition = Duration(milliseconds: 200);
  
  // User feedback timings
  static const Duration errorDisplayDuration = Duration(seconds: 3);
  static const Duration successMessageDuration = Duration(seconds: 2);
  static const Duration warningDisplayDuration = Duration(seconds: 5);
  static const Duration countdownInterval = Duration(seconds: 1);
  
  // Speech and input timeouts
  static const Duration speechTimeout = Duration(seconds: 10);
  static const Duration inputDebounce = Duration(milliseconds: 300);
  static const Duration searchDelay = Duration(milliseconds: 300);
  
  // Cache and cleanup intervals
  static const Duration cacheCleanupInterval = Duration(hours: 24);
  static const Duration syncStatusInterval = Duration(minutes: 5);
  static const Duration realtimeTimeout = Duration(seconds: 10);
  
  // Authentication and session management
  static const Duration authFeedbackDelay = Duration(milliseconds: 500);
  static const Duration sessionCheckInterval = Duration(minutes: 5);
  static const Duration dataRetentionPeriod = Duration(days: 30);
  
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
        connectivityTimeout = const Duration(seconds: 45);
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
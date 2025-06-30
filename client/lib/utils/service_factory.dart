// lib/utils/service_factory.dart
// Enterprise-grade Service Factory Pattern Implementation
// Centralized service creation and dependency management

import 'package:flutter/foundation.dart' show debugPrint;

// Service imports
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/flashcard_service.dart';
import '../services/user_service.dart';
import '../services/network_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';
import '../services/job_description_service.dart';

/// Enterprise-grade Service Factory with dependency management
/// 
/// This factory implements the Singleton pattern and provides:
/// - Centralized service creation
/// - Dependency injection management
/// - Async initialization handling
/// - Type-safe service retrieval
/// - Service lifecycle management
class ServiceFactory {
  // Singleton pattern implementation
  static final ServiceFactory _instance = ServiceFactory._internal();
  factory ServiceFactory() => _instance;
  ServiceFactory._internal();

  // Service registry
  static Map<String, dynamic>? _services;
  static Map<Type, String>? _typeRegistry;
  static bool _isInitialized = false;

  /// Initialize the service registry mapping
  static void _initializeTypeRegistry() {
    _typeRegistry = {
      ApiService: 'api',
      SpeechToTextService: 'speechToText',
      FlashcardService: 'flashcard',
      UserService: 'user',
      NetworkService: 'network',
      InterviewService: 'interview',
      RecentViewService: 'recentView',
      JobDescriptionService: 'jobDescription',
    };
  }
  /// Generic service creation method
  /// Creates services using the factory pattern with proper typing
  static T create<T>() {
    if (_typeRegistry == null) {
      _initializeTypeRegistry();
    }

    final serviceKey = _typeRegistry![T];
    if (serviceKey == null) {
      throw ArgumentError('Service type $T is not registered in factory');
    }

    // Factory method pattern - create instances based on type
    switch (T) {
      case const (ApiService):
        return ApiService() as T;
      case const (SpeechToTextService):
        return SpeechToTextService() as T;
      case const (FlashcardService):
        return FlashcardService() as T;
      case const (UserService):
        return UserService() as T;
      case const (NetworkService):
        return NetworkService() as T;
      case const (InterviewService):
        return InterviewService() as T;
      case const (RecentViewService):
        return RecentViewService() as T;
      case const (JobDescriptionService):
        return JobDescriptionService() as T;
      default:
        throw ArgumentError('Unknown service type: $T');
    }
  }

  /// Create all application services with dependency management
  /// Replaces AppInitializer.createApplicationServices()
  static Future<Map<String, dynamic>> createAllServices() async {
    if (_services != null && _isInitialized) {
      debugPrint('⚠️ Services already created, returning cached instances');
      return _services!;
    }

    debugPrint('🔧 ServiceFactory: Creating all application services...');

    // Initialize type registry
    _initializeTypeRegistry();

    // Create service instances using factory methods
    final apiService = create<ApiService>();
    final speechToTextService = create<SpeechToTextService>();
    final flashcardService = create<FlashcardService>();
    final userService = create<UserService>();
    final networkService = create<NetworkService>();
    final interviewService = create<InterviewService>();
    final recentViewService = create<RecentViewService>();
    final jobDescriptionService = create<JobDescriptionService>();

    // Handle async initialization for services that require it
    await _performAsyncInitialization({
      'interview': interviewService,
    });

    // Store services for dependency injection
    _services = {
      'api': apiService,
      'speechToText': speechToTextService,
      'flashcard': flashcardService,
      'user': userService,
      'network': networkService,
      'interview': interviewService,
      'recentView': recentViewService,
      'jobDescription': jobDescriptionService,
      '_flashcardService': flashcardService, // Internal reference for auth connection
    };

    _isInitialized = true;
    debugPrint('✅ ServiceFactory: All application services created and initialized');
    return _services!;
  }

  /// Handle async initialization for services that require it
  static Future<void> _performAsyncInitialization(
    Map<String, dynamic> servicesRequiringInit,
  ) async {
    for (final entry in servicesRequiringInit.entries) {
      final serviceName = entry.key;
      final service = entry.value;

      debugPrint('🔧 ServiceFactory: Initializing $serviceName service...');
      
      try {
        // Handle InterviewService initialization
        if (service is InterviewService) {
          await service.initialize();
          debugPrint(
            '✅ ServiceFactory: InterviewService initialized with ${service.questions.length} questions',
          );
        }
        // Add other async initializations here as needed
        
      } catch (e) {
        debugPrint('⚠️ ServiceFactory: Failed to initialize $serviceName: $e');
        rethrow;
      }
    }
  }

  /// Get a specific service by name
  /// Throws if service not found or services not created
  static T getService<T>(String serviceName) {
    if (_services == null || !_isInitialized) {
      throw StateError(
        'ServiceFactory: Services not created yet. Call createAllServices() first.',
      );
    }

    final service = _services![serviceName];
    if (service == null) {
      throw ArgumentError('ServiceFactory: Service "$serviceName" not found');
    }

    if (service is! T) {
      throw TypeError();
    }

    return service;
  }

  /// Get a service by type (alternative to getService by name)
  static T getServiceByType<T>() {
    if (_typeRegistry == null) {
      _initializeTypeRegistry();
    }

    final serviceKey = _typeRegistry![T];
    if (serviceKey == null) {
      throw ArgumentError('ServiceFactory: Service type $T is not registered');
    }

    return getService<T>(serviceKey);
  }

  /// Check if services have been created and initialized
  static bool get isInitialized => _isInitialized && _services != null;

  /// Get number of registered services
  static int get serviceCount => _services?.length ?? 0;

  /// Get list of all registered service names
  static List<String> get registeredServices => 
      _services?.keys.toList() ?? [];

  /// Clear service cache and reset factory (for testing purposes)
  static void reset() {
    _services = null;
    _typeRegistry = null;
    _isInitialized = false;
    debugPrint('🔄 ServiceFactory: Factory reset complete');
  }

  /// Dispose of all services and clean up resources
  static Future<void> dispose() async {
    if (_services != null) {
      // Dispose services that implement disposal methods
      for (final entry in _services!.entries) {
        try {
          // Future enhancement: Add disposal logic for services that need cleanup
          // Example: if (entry.value has dispose method) await entry.value.dispose();
          debugPrint('🧹 ServiceFactory: Disposing ${entry.key} service');
        } catch (e) {
          debugPrint('⚠️ ServiceFactory: Error disposing ${entry.key}: $e');
        }
      }
    }
    
    reset();
    debugPrint('✅ ServiceFactory: All services disposed and factory reset');
  }
}

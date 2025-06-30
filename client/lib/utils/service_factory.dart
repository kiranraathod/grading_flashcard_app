// lib/utils/service_factory.dart
// Extracted service creation logic from main.dart
// Phase 3: Main.dart Simplification

import 'package:flutter/foundation.dart' show debugPrint;
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/flashcard_service.dart';
import '../services/user_service.dart';
import '../services/network_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';
import '../services/job_description_service.dart';

/// Service creation and initialization factory
/// Extracted from main.dart _createServices method
class ServiceFactory {
  static Map<String, dynamic>? _services;

  /// Create and initialize all application services
  /// Returns a map of service instances for dependency injection
  static Future<Map<String, dynamic>> createServices() async {
    if (_services != null) {
      debugPrint('⚠️ Services already created, returning cached instances');
      return _services!;
    }

    debugPrint('🔧 Creating application services...');

    // Create service instances
    final apiService = ApiService();
    final speechToTextService = SpeechToTextService();
    final flashcardService = FlashcardService();
    final userService = UserService();
    final networkService = NetworkService();
    final interviewService = InterviewService();
    final recentViewService = RecentViewService();
    final jobDescriptionService = JobDescriptionService();

    // Initialize InterviewService and wait for completion
    debugPrint('🔧 Initializing InterviewService...');
    await interviewService.initialize();
    debugPrint(
      '✅ InterviewService initialized with ${interviewService.questions.length} questions',
    );

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
      '_flashcardService':
          flashcardService, // Internal reference for auth connection
    };

    debugPrint('✅ All application services created successfully');
    return _services!;
  }

  /// Get a specific service by name
  /// Throws if service not found or services not created
  static T getService<T>(String serviceName) {
    if (_services == null) {
      throw StateError(
        'Services not created yet. Call createServices() first.',
      );
    }

    final service = _services![serviceName];
    if (service == null) {
      throw ArgumentError('Service "$serviceName" not found');
    }

    if (service is! T) {
      throw TypeError();
    }

    return service;
  }

  /// Check if services have been created
  static bool get isInitialized => _services != null;

  /// Clear service cache (for testing purposes)
  static void reset() {
    _services = null;
    debugPrint('🔄 Service factory reset');
  }
}

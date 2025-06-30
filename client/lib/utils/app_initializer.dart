import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// Service imports
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/enhanced_cache_manager.dart';
import '../services/supabase_service.dart';
import '../services/network_infrastructure_initializer.dart';
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/flashcard_service.dart';
import '../services/network_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';
import '../services/job_description_service.dart';
import '../utils/storage_migration_utility.dart';

/// Centralized application initialization for clean main.dart
/// 
/// This class handles all complex service initialization and configuration
/// that was previously scattered across main.dart (459 lines -> ~100 lines)
class AppInitializer {
  
  /// Configure debug output for production vs development
  static void configureDebugOutput() {
    if (!kDebugMode) {
      // In production, only show errors and critical messages
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && _isImportantMessage(message)) {
          originalDebugPrint(message, wrapWidth: wrapWidth);
        }
      };
    }
    // In debug mode, show all messages (default behavior)
  }

  /// Initialize all core services required for app startup
  /// 
  /// This replaces the complex _initializeServices() function from main.dart
  static Future<void> initializeCore() async {
    debugPrint('🚀 Initializing FlashMaster core services...');

    // 1. Core Storage - Essential for all functionality
    await _initializeStorage();
    
    // 2. Storage Migration - User data preservation
    await _performDataMigration();
    
    // 3. Basic Services - User management and caching
    await _initializeBasicServices();
    
    // 4. Authentication Services - Supabase setup
    await _initializeAuthentication();
    
    // 5. Network Infrastructure - Enhanced HTTP and connectivity
    await _initializeNetworkInfrastructure();

    debugPrint('✅ All core services initialized - FlashMaster ready');
  }

  /// Create and configure all application service instances
  /// 
  /// Returns a map of configured services ready for dependency injection
  static Future<Map<String, dynamic>> createApplicationServices() async {
    debugPrint('🔧 Creating application service instances...');

    // Create service instances
    final apiService = ApiService();
    final speechToTextService = SpeechToTextService();
    final flashcardService = FlashcardService();
    final userService = UserService();
    final networkService = NetworkService();
    final interviewService = InterviewService();
    final recentViewService = RecentViewService();
    final jobDescriptionService = JobDescriptionService();

    // Initialize services that require async setup
    debugPrint('🔧 Initializing InterviewService...');
    await interviewService.initialize();
    debugPrint(
      '✅ InterviewService initialized with ${interviewService.questions.length} questions',
    );

    // Return configured services
    final services = {
      'api': apiService,
      'speechToText': speechToTextService,
      'flashcard': flashcardService,
      'user': userService,
      'network': networkService,
      'interview': interviewService,
      'recentView': recentViewService,
      'jobDescription': jobDescriptionService,
    };

    debugPrint('✅ Application services created successfully');
    return services;
  }

  // Private helper methods for clean organization

  static Future<void> _initializeStorage() async {
    try {
      await StorageService.initialize();
      debugPrint('✅ Storage service initialized');
    } catch (e) {
      debugPrint('⚠️ Storage initialization failed: $e - using memory-only storage');
    }
  }

  static Future<void> _performDataMigration() async {
    try {
      debugPrint('🔄 Starting storage migration...');
      final migrationResult = await StorageMigrationUtility.performFullMigration();
      
      if (migrationResult.success) {
        debugPrint('✅ Storage migration completed successfully');
        debugPrint('   - Migrated users: ${migrationResult.migratedUsers.length}');
        debugPrint('   - Cleaned legacy keys: ${migrationResult.cleanedKeys.length}');
        
        // Verify migration integrity
        final verification = await StorageMigrationUtility.verifyMigration();
        if (verification.success) {
          debugPrint('✅ Migration verification passed');
        } else {
          debugPrint('⚠️ Migration verification found issues:');
          for (final error in verification.errors) {
            debugPrint('   - $error');
          }
        }
        
        // Generate migration report in debug mode
        if (kDebugMode) {
          final report = StorageMigrationUtility.generateMigrationReport(migrationResult, verification);
          debugPrint('📊 Migration Report:\n$report');
        }
      } else {
        debugPrint('❌ Storage migration failed:');
        for (final error in migrationResult.errors) {
          debugPrint('   - $error');
        }
        debugPrint('⚠️ Continuing with current storage state...');
      }
    } catch (e) {
      debugPrint('❌ Migration error: $e - continuing with current storage');
    }
  }

  static Future<void> _initializeBasicServices() async {
    // User Service
    try {
      await UserService.initialize();
      debugPrint('✅ User service initialized');
    } catch (e) {
      debugPrint('⚠️ User service failed: $e - using default user');
    }

    // Cache Manager
    try {
      final cacheManager = EnhancedCacheManager();
      await cacheManager.initialize();
      debugPrint('✅ Cache manager initialized');
    } catch (e) {
      debugPrint('⚠️ Cache manager failed: $e - using memory-only cache');
    }
  }

  static Future<void> _initializeAuthentication() async {
    try {
      await SupabaseService.instance.initialize();
      debugPrint('✅ Authentication services initialized');
    } catch (e) {
      debugPrint('⚠️ Authentication services failed: $e - guest mode only');
    }
  }

  static Future<void> _initializeNetworkInfrastructure() async {
    try {
      final networkInitializer = NetworkInfrastructureInitializer();
      final success = await networkInitializer.initialize();
      
      if (success) {
        debugPrint('✅ Network infrastructure initialized successfully');
        final status = networkInitializer.getInfrastructureStatus();
        debugPrint('📊 Network Infrastructure Status:');
        status.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      } else {
        debugPrint('⚠️ Network infrastructure initialization completed with errors:');
        for (final error in networkInitializer.initializationErrors) {
          debugPrint('   ❌ $error');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Network infrastructure error: $e - basic networking only');
    }
  }

  /// Simple production debug filter - only show critical messages
  static bool _isImportantMessage(String message) {
    return message.contains('❌') ||
           message.contains('ERROR') ||
           message.contains('Exception') ||
           message.contains('Failed') ||
           message.contains('Critical');
  }
}

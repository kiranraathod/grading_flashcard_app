import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Service imports
import '../services/flashcard_service.dart';
import '../services/interview_service.dart';
import '../providers/working_auth_provider.dart';

/// Centralized authentication connection management
/// 
/// This class handles all auth-service connection logic that was previously
/// embedded in main.dart, reducing complexity by ~25 lines
class AuthConnectionManager {

  /// Set up connection between authentication and data services
  static void setupAuthServiceConnection(Map<String, dynamic> services) {
    final flashcardService = services['flashcard'] as FlashcardService;
    
    // Store the flashcard service reference for direct connection after app initialization
    services['_flashcardService'] = flashcardService;
    debugPrint('🔗 FlashcardService stored for auth connection setup');
  }

  /// Establish auth-service connection (called after widget tree is ready)
  static void establishAuthConnection(WidgetRef ref, Map<String, dynamic> services) {
    try {
      final flashcardService = services['_flashcardService'] as FlashcardService?;
      final interviewService = services['interview'] as InterviewService?;
      
      if (flashcardService != null) {
        final authNotifier = ref.read(authNotifierProvider.notifier);
        
        // Register callback for when user data migration completes
        authNotifier.onUserDataMigrated((String userId) {
          debugPrint('🔄 Auth callback: Reloading FlashcardService for user $userId');
          flashcardService.reloadForUser(userId);
          
          // Also reload InterviewService if available
          if (interviewService != null) {
            debugPrint('🔄 Auth callback: Reloading InterviewService for user $userId');
            interviewService.reloadForUser(userId);
          }
        });
        
        debugPrint('✅ Auth-FlashcardService connection established successfully');
        if (interviewService != null) {
          debugPrint('✅ Auth-InterviewService connection established successfully');
        }
      } else {
        debugPrint('❌ FlashcardService not found for auth connection');
      }
    } catch (e) {
      debugPrint('❌ Failed to establish auth connection: $e');
    }
  }

  /// Theme change analytics logging
  static void logThemeChange(ThemeMode oldMode, ThemeMode newMode) {
    // Implement your analytics here
    debugPrint('Theme changed from $oldMode to $newMode');

    // Example with Firebase Analytics (commented out):
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'theme_changed',
    //   parameters: {
    //     'from_mode': oldMode.toString(),
    //     'to_mode': newMode.toString(),
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );
  }
}

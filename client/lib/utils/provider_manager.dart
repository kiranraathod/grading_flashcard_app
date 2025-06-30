import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart' as provider;
import 'package:provider/single_child_widget.dart' show SingleChildWidget;

// Service imports
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/flashcard_service.dart';
import '../services/user_service.dart';
import '../services/network_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';
import '../services/job_description_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_status_tracker.dart';
import '../services/supabase_service.dart';
import '../utils/theme_provider.dart';

// BLoC imports
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/search/search_bloc.dart';

/// Centralized provider management for clean main.dart architecture
/// 
/// This class handles all complex provider setup that was previously
/// embedded in main.dart, reducing complexity by ~120 lines
class ProviderManager {

  /// Create BLoC providers from service instances
  static List<BlocProvider> createBlocProviders(Map<String, dynamic> services) {
    final recentViewService = services['recentView'] as RecentViewService;
    final flashcardService = services['flashcard'] as FlashcardService;
    final interviewService = services['interview'] as InterviewService;

    // Create global instances of BLoCs to be shared across all screens
    final recentViewBloc = RecentViewBloc(recentViewService: recentViewService);
    final searchBloc = SearchBloc(
      flashcardService: flashcardService,
      interviewService: interviewService,
    );

    debugPrint('✅ Created BLoC providers');

    return [
      BlocProvider<RecentViewBloc>.value(value: recentViewBloc),
      BlocProvider<SearchBloc>.value(value: searchBloc),
    ];
  }

  /// Create service providers for dependency injection
  static List<SingleChildWidget> createServiceProviders(
    Map<String, dynamic> services,
    Function(ThemeMode, ThemeMode) onThemeChanged,
  ) {
    // Extract services from the services map
    final apiService = services['api'] as ApiService;
    final speechToTextService = services['speechToText'] as SpeechToTextService;
    final flashcardService = services['flashcard'] as FlashcardService;
    final userService = services['user'] as UserService;
    final networkService = services['network'] as NetworkService;
    final interviewService = services['interview'] as InterviewService;
    final recentViewService = services['recentView'] as RecentViewService;
    final jobDescriptionService = services['jobDescription'] as JobDescriptionService;

    return [
      // Core Infrastructure Services
      provider.ChangeNotifierProvider.value(
        value: SupabaseService.instance,
      ),

      // Enhanced Network Services
      provider.ChangeNotifierProvider(
        create: (_) => ConnectivityService(),
      ),
      provider.ChangeNotifierProvider(
        create: (_) => SyncStatusTracker(),
      ),

      // Application Services (for backward compatibility with non-migrated screens)
      provider.ChangeNotifierProvider.value(value: flashcardService),
      provider.ChangeNotifierProvider.value(value: userService),
      provider.ChangeNotifierProvider.value(value: networkService),
      provider.ChangeNotifierProvider.value(value: interviewService),

      // Theme provider with callback support
      provider.ChangeNotifierProvider(
        create: (_) {
          final themeProvider = ThemeProvider();

          // Add theme change callback for analytics
          themeProvider.addThemeChangeCallback((oldMode, newMode) {
            onThemeChanged(oldMode, newMode);
          });

          return themeProvider;
        },
      ),

      // Services as Repositories for BLoCs
      provider.Provider<ApiService>.value(value: apiService),
      provider.Provider<SpeechToTextService>.value(value: speechToTextService),
      provider.Provider<RecentViewService>.value(value: recentViewService),
      provider.Provider<JobDescriptionService>.value(value: jobDescriptionService),
    ];
  }

  /// Create complete provider tree for the application
  static Widget createProviderTree({
    required Map<String, dynamic> services,
    required Function(ThemeMode, ThemeMode) onThemeChanged,
    required Widget child,
  }) {
    debugPrint('🏗️ Setting up provider tree...');

    return MultiBlocProvider(
      providers: createBlocProviders(services),
      child: provider.MultiProvider(
        providers: createServiceProviders(services, onThemeChanged),
        child: child,
      ),
    );
  }
}

// lib/utils/provider_factory.dart
// Extracted provider setup logic from main.dart
// Phase 3: Main.dart Simplification

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart' as provider;
import '../services/flashcard_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/search/search_bloc.dart';
import '../utils/theme_provider.dart';

/// Provider and BLoC setup factory
/// Extracted from main.dart _buildMainApp method
class ProviderFactory {
  /// Create all BLoC instances with service dependencies
  static Map<String, dynamic> createBlocs(Map<String, dynamic> services) {
    final flashcardService = services['flashcard'] as FlashcardService;
    final interviewService = services['interview'] as InterviewService;
    final recentViewService = services['recentView'] as RecentViewService;

    // Create global instances of BLoCs to be shared across all screens
    final recentViewBloc = RecentViewBloc(recentViewService: recentViewService);
    final searchBloc = SearchBloc(
      flashcardService: flashcardService,
      interviewService: interviewService,
    );

    return {'recentView': recentViewBloc, 'search': searchBloc};
  }

  /// Create the complete provider tree with all dependencies
  static Widget createProviderTree({
    required Widget child,
    required Map<String, dynamic> services,
    required Map<String, dynamic> blocs,
  }) {
    // Extract services for easier access
    final apiService = services['api'];
    final speechToTextService = services['speechToText'];
    final flashcardService = services['flashcard'];
    final userService = services['user'];
    final networkService = services['network'];
    final interviewService = services['interview'];
    final recentViewService = services['recentView'];
    final jobDescriptionService = services['jobDescription'];

    // Extract BLoCs
    final recentViewBloc = blocs['recentView'] as RecentViewBloc;
    final searchBloc = blocs['search'] as SearchBloc;

    return MultiBlocProvider(
      providers: [
        BlocProvider<RecentViewBloc>.value(value: recentViewBloc),
        BlocProvider<SearchBloc>.value(value: searchBloc),
      ],
      child: provider.MultiProvider(
        providers: [
          // Service providers
          provider.Provider.value(value: apiService),
          provider.Provider.value(value: speechToTextService),
          provider.Provider.value(value: flashcardService),
          provider.Provider.value(value: userService),
          provider.Provider.value(value: networkService),
          provider.Provider.value(value: interviewService),
          provider.Provider.value(value: recentViewService),
          provider.Provider.value(value: jobDescriptionService),

          // Theme provider
          provider.ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: child,
      ),
    );
  }
}

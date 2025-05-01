import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/home_screen.dart';
import 'screens/job_description_question_generator_screen.dart';
import 'utils/theme.dart';
import 'services/flashcard_service.dart';
import 'services/user_service.dart';
import 'services/network_service.dart';
import 'services/api_service.dart';
import 'services/speech_to_text_service.dart';
import 'services/interview_service.dart';
import 'services/recent_view_service.dart';
import 'services/job_description_service.dart';
import 'blocs/recent_view/recent_view_bloc.dart';
import 'widgets/error_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create and register services
    final apiService = ApiService();
    final speechToTextService = SpeechToTextService();
    final flashcardService = FlashcardService();
    final userService = UserService();
    final networkService = NetworkService();
    final interviewService = InterviewService();
    final recentViewService = RecentViewService();
    final jobDescriptionService = JobDescriptionService();

    // Create a global instance of RecentViewBloc to be shared across all screens
    final recentViewBloc = RecentViewBloc(recentViewService: recentViewService);

    // Debug Print
    debugPrint('⭐⭐⭐ INITIALIZING APPLICATION ⭐⭐⭐');
    debugPrint('Created RecentViewService and RecentViewBloc');

    return MultiBlocProvider(
      providers: [
        // Global BLoC providers
        BlocProvider<RecentViewBloc>.value(value: recentViewBloc),
      ],
      child: MultiProvider(
        providers: [
          // Services as Providers (for backward compatibility)
          ChangeNotifierProvider(create: (_) => flashcardService),
          ChangeNotifierProvider(create: (_) => userService),
          ChangeNotifierProvider(create: (_) => networkService),
          ChangeNotifierProvider(create: (_) => interviewService),

          // Services as Repositories for BLoCs
          Provider<ApiService>.value(value: apiService),
          Provider<SpeechToTextService>.value(value: speechToTextService),
          Provider<RecentViewService>.value(value: recentViewService),
          Provider<JobDescriptionService>.value(value: jobDescriptionService),
        ],
        child: ErrorHandler(
          child: MaterialApp(
            title: 'FlashMaster',
            theme:
                AppTheme.lightTheme(), // Updated theme with new design system
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            home: const HomeScreen(),
            routes: {
              '/job-description-generator':
                  (context) => const JobDescriptionQuestionGeneratorScreen(),
            },
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}

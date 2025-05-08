import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/home_screen.dart';
import 'screens/job_description_question_generator_screen.dart';
import 'utils/theme_provider.dart';
import 'utils/app_themes.dart';
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

  // Theme change analytics
  static void _logThemeChange(ThemeMode oldMode, ThemeMode newMode) {
    // Implement your analytics here
    debugPrint('Theme changed from $oldMode to $newMode');

    // Example with Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'theme_changed',
    //   parameters: {
    //     'from_mode': oldMode.toString(),
    //     'to_mode': newMode.toString(),
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );
  }

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

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use dynamic color on supported platforms
        ThemeData lightTheme;
        ThemeData darkTheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Apply dynamic color scheme to theme
          lightTheme = AppThemes.lightTheme.copyWith(
            colorScheme: lightDynamic.harmonized(),
          );
          darkTheme = AppThemes.darkTheme.copyWith(
            colorScheme: darkDynamic.harmonized(),
          );
        } else {
          // Use default themes if dynamic color is not available
          lightTheme = AppThemes.lightTheme;
          darkTheme = AppThemes.darkTheme;
        }

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

              // Theme provider with callback support
              ChangeNotifierProvider(
                create: (_) {
                  final themeProvider = ThemeProvider();

                  // Add theme change callback for analytics
                  themeProvider.addThemeChangeCallback((oldMode, newMode) {
                    _logThemeChange(oldMode, newMode);
                  });

                  return themeProvider;
                },
              ),

              // Services as Repositories for BLoCs
              Provider<ApiService>.value(value: apiService),
              Provider<SpeechToTextService>.value(value: speechToTextService),
              Provider<RecentViewService>.value(value: recentViewService),
              Provider<JobDescriptionService>.value(
                value: jobDescriptionService,
              ),
            ],
            child: ErrorHandler(
              child: Consumer<ThemeProvider>(
                builder:
                    (
                      context,
                      themeProvider,
                      _,
                    ) => TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 200),
                      tween: Tween<double>(
                        begin: themeProvider.isDarkMode ? 1.0 : 0.0,
                        end: themeProvider.isDarkMode ? 1.0 : 0.0,
                      ),
                      builder:
                          (context, value, child) => MaterialApp(
                            title: 'FlashMaster',
                            theme: lightTheme,
                            darkTheme: darkTheme,
                            themeMode: themeProvider.themeMode,
                            themeAnimationDuration:
                                Duration
                                    .zero, // Disable theme animation to prevent lag
                            home: const HomeScreen(),
                            routes: {
                              '/job-description-generator':
                                  (context) =>
                                      const JobDescriptionQuestionGeneratorScreen(),
                            },
                            debugShowCheckedModeBanner: false,
                          ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

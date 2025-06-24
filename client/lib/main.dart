import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart' as provider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/job_description_question_generator_screen.dart';
import 'screens/data_validation_screen.dart';
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
import 'services/storage_service.dart';
import 'services/network_infrastructure_initializer.dart';
import 'services/connectivity_service.dart';
import 'services/sync_status_tracker.dart';
import 'blocs/recent_view/recent_view_bloc.dart';
import 'blocs/search/search_bloc.dart';
import 'widgets/error_handler.dart';
import 'services/cache_manager.dart';
import 'services/supabase_service.dart';
import 'providers/working_auth_provider.dart';
// 🆕 NEW UNIFIED IMPORTS
import 'utils/storage_migration_utility.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 Environment-based debug configuration
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

  // Initialize all services
  await _initializeServices();

  // Wrap the app with ProviderScope for Riverpod
  runApp(ProviderScope(child: MyApp()));
}

/// Simplified service initialization - replaces complex multi-function approach
Future<void> _initializeServices() async {
  debugPrint('🚀 Initializing FlashMaster services...');

  // 1. Core Storage - Essential for all functionality
  try {
    await StorageService.initialize();
    debugPrint('✅ Storage service initialized');
  } catch (e) {
    debugPrint('⚠️ Storage initialization failed: $e - using memory-only storage');
  }

  // 2. Storage Migration - User data preservation
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

  // 3. Basic Services - User management and caching
  try {
    await UserService.initialize();
    debugPrint('✅ User service initialized');
  } catch (e) {
    debugPrint('⚠️ User service failed: $e - using default user');
  }

  try {
    final cacheManager = CacheManager();
    await cacheManager.initialize();
    debugPrint('✅ Cache manager initialized');
  } catch (e) {
    debugPrint('⚠️ Cache manager failed: $e - using memory-only cache');
  }

  // 4. Authentication Services - Supabase setup
  try {
    await SupabaseService.instance.initialize();
    debugPrint('✅ Authentication services initialized');
  } catch (e) {
    debugPrint('⚠️ Authentication services failed: $e - guest mode only');
  }

  // 5. Network Infrastructure - Enhanced HTTP and connectivity
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

  debugPrint('✅ All services initialized - FlashMaster ready');
}

/// Simple production debug filter - only show critical messages
bool _isImportantMessage(String message) {
  return message.contains('❌') ||
         message.contains('ERROR') ||
         message.contains('Exception') ||
         message.contains('Failed') ||
         message.contains('Critical');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic> _services = {};

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
    return FutureBuilder<void>(
      future: _createServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing FlashMaster...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}'),
              ),
            ),
          );
        }

        return _buildMainApp();
      },
    );
  }

  Future<void> _createServices() async {
    // Create and register services
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

    // Store services for use in _buildMainApp
    _services = {
      'api': apiService,
      'speechToText': speechToTextService,
      'flashcard': flashcardService,
      'user': userService,
      'network': networkService,
      'interview': interviewService,
      'recentView': recentViewService,
      'jobDescription': jobDescriptionService,
    };

    // 🔗 CRITICAL FIX: Connect auth provider to FlashcardService for data migration
    debugPrint('🔗 Setting up auth-flashcard service connection...');
    _setupAuthServiceConnection(flashcardService);
  }

  /// Set up connection between authentication and data services
  void _setupAuthServiceConnection(FlashcardService flashcardService) {
    // Store the flashcard service reference for direct connection after app initialization
    _services['_flashcardService'] = flashcardService;
    debugPrint('🔗 FlashcardService stored for auth connection setup');
  }

  /// Establish auth-service connection (called after widget tree is ready)
  void _establishAuthConnection(WidgetRef ref) {
    try {
      final flashcardService = _services['_flashcardService'] as FlashcardService?;
      final interviewService = _services['interview'] as InterviewService?;
      
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

  Widget _buildMainApp() {
    // Get services from stored map
    final apiService = _services['api'] as ApiService;
    final speechToTextService =
        _services['speechToText'] as SpeechToTextService;
    final flashcardService = _services['flashcard'] as FlashcardService;
    final userService = _services['user'] as UserService;
    final networkService = _services['network'] as NetworkService;
    final interviewService = _services['interview'] as InterviewService;
    final recentViewService = _services['recentView'] as RecentViewService;
    final jobDescriptionService =
        _services['jobDescription'] as JobDescriptionService;

    // Create global instances of BLoCs to be shared across all screens
    final recentViewBloc = RecentViewBloc(recentViewService: recentViewService);
    final searchBloc = SearchBloc(
      flashcardService: flashcardService,
      interviewService: interviewService,
    );

    // Debug Print
    debugPrint('⭐⭐⭐ INITIALIZING APPLICATION ⭐⭐⭐');
    debugPrint('Created RecentViewService and BLoCs');

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
            BlocProvider<SearchBloc>.value(value: searchBloc),
          ],
          child: provider.MultiProvider(
            providers: [
              // Core Infrastructure Services (keeping for other app components)
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
                    _logThemeChange(oldMode, newMode);
                  });

                  return themeProvider;
                },
              ),

              // Services as Repositories for BLoCs
              provider.Provider<ApiService>.value(value: apiService),
              provider.Provider<SpeechToTextService>.value(
                value: speechToTextService,
              ),
              provider.Provider<RecentViewService>.value(
                value: recentViewService,
              ),
              provider.Provider<JobDescriptionService>.value(
                value: jobDescriptionService,
              ),
            ],
            child: ErrorHandler(
              child: Consumer(
                builder: (context, WidgetRef ref, _) {
                  // 🔗 CRITICAL: Set up auth-service connection on first widget build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _establishAuthConnection(ref);
                  });
                  
                  return provider.Consumer<ThemeProvider>(
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
                                  '/data-validation':
                                      (context) => const DataValidationScreen(),
                                },
                                debugShowCheckedModeBanner: false,
                                // Localization config
                                locale: const Locale('en'),
                                localizationsDelegates: const [
                                  AppLocalizations.delegate,
                                  GlobalMaterialLocalizations.delegate,
                                  GlobalWidgetsLocalizations.delegate,
                                  GlobalCupertinoLocalizations.delegate,
                                ],
                                supportedLocales: const [Locale('en')],
                              ),
                        ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

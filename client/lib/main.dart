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
import 'services/initialization_coordinator.dart';
import 'services/simple_error_handler.dart';
import 'services/cache_manager.dart';
import 'services/supabase_service.dart';
// 🆕 NEW UNIFIED IMPORTS
import 'utils/storage_migration_utility.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 TESTING MODE: Only show auth-related and error logs
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && _shouldShowForAuthTesting(message)) {
      originalDebugPrint(message, wrapWidth: wrapWidth);
    }
  };

  // Initialize System Stabilization
  await _initializeSystemStabilization();

  // Initialize secure storage and migration
  await _initializeUnifiedAuthentication();

  // Wrap the app with ProviderScope for Riverpod
  runApp(ProviderScope(child: MyApp()));
}

/// 🔄 REFACTORED: Initialize unified authentication and storage system
Future<void> _initializeUnifiedAuthentication() async {
  await SimpleErrorHandler.safely(() async {
    debugPrint('🔐 Initializing unified authentication and storage system...');

    // 1. Perform complete storage migration
    debugPrint('🔄 Starting comprehensive storage migration...');
    final migrationResult =
        await StorageMigrationUtility.performFullMigration();

    if (migrationResult.success) {
      debugPrint('✅ Storage migration completed successfully');
      debugPrint(
        '   - Migrated users: ${migrationResult.migratedUsers.length}',
      );
      debugPrint(
        '   - Cleaned legacy keys: ${migrationResult.cleanedKeys.length}',
      );

      // 2. Verify migration integrity
      final verification = await StorageMigrationUtility.verifyMigration();
      if (verification.success) {
        debugPrint('✅ Migration verification passed');
      } else {
        debugPrint('⚠️ Migration verification found issues:');
        for (final error in verification.errors) {
          debugPrint('   - $error');
        }
      }

      // 3. Generate and log migration report (debug mode only)
      if (kDebugMode) {
        final report = StorageMigrationUtility.generateMigrationReport(
          migrationResult,
          verification,
        );
        debugPrint('📊 Migration Report:\n$report');
      }
    } else {
      debugPrint('❌ Storage migration failed:');
      for (final error in migrationResult.errors) {
        debugPrint('   - $error');
      }
      debugPrint('⚠️ Continuing with current storage state...');
    }

    debugPrint('✅ Unified authentication system ready');
  }, operationName: 'unified_authentication_initialization');
}

/// Only show logs relevant for testing authentication trigger logic
bool _shouldShowForAuthTesting(String message) {
  // ✅ ALWAYS SHOW: Errors and exceptions
  if (message.contains('❌') ||
      message.contains('ERROR') ||
      message.contains('Exception') ||
      message.contains('Failed')) {
    return true;
  }

  // ✅ SHOW: Authentication trigger logic
  if (message.contains('🚫 Usage limit reached') ||
      message.contains('showing auth modal') ||
      message.contains('Authentication modal') ||
      message.contains('Grading blocked') ||
      message.contains('limit reached')) {
    return true;
  }

  // ✅ SHOW: Usage count updates (to track progress)
  if (message.contains('Grading action recorded') ||
      message.contains('Usage limit') ||
      message.contains('actions remaining') ||
      message.contains('canPerformGradingAction')) {
    return true;
  }

  // ✅ SHOW: Authentication trigger debugging
  if (message.contains('🔍 Testing Auth Trigger') ||
      message.contains('🔍 Can perform action') ||
      message.contains('🔍 Has reached limit') ||
      message.contains('🔍 Auth modal dismissed') ||
      message.contains('🔍 Proceeding with grading') ||
      message.contains('🔍 StudyBloc Auth Check') ||
      message.contains('🚫 StudyBloc: Usage limit reached') ||
      message.contains('🔍 StudyBloc: Proceeding with grading') ||
      message.contains('🔍 StudyBloc: API call successful') ||
      message.contains('🚫 StudyScreen: Authentication required') ||
      message.contains('🔍 Current count check') ||
      message.contains('🚫 StudyBloc: Usage limit already reached') ||
      message.contains('🔍 StudyBloc: FlashcardAnswered event received')) {
    return true;
  }

  // ✅ SHOW: All API calls (to catch bypassed calls)
  if (message.contains('🔍 API SERVICE') ||
      message.contains('gradeAnswer') ||
      message.contains('API request') ||
      message.contains('POST /api/grade') ||
      message.contains('Making API request') ||
      message.contains('Called from:')) {
    return true;
  }

  // ✅ SHOW: Authentication state changes
  if (message.contains('User signed in') ||
      message.contains('User signed out') ||
      message.contains('Auth state changed') ||
      message.contains('authenticated') ||
      message.contains('🔍 Google sign-in') ||
      message.contains('🔍 Email auth') ||
      message.contains('🧪 Demo') ||
      message.contains('✅ Google sign-in successful') ||
      message.contains('✅ Email auth successful') ||
      message.contains('✅ Demo') ||
      message.contains('❌ Google sign-in failed') ||
      message.contains('❌ Email auth failed') ||
      message.contains('❌ Demo')) {
    return true;
  }

  // 🔇 HIDE: All routine operations
  if (message.contains('SAVING ANSWER') ||
      message.contains('ADDING RECENT ITEM') ||
      message.contains('Save SUCCESSFUL') ||
      message.contains('Found') && message.contains('existing items') ||
      message.contains('Updating existing item') ||
      message.contains('Total local answers') ||
      message.contains('Saved to') ||
      message.contains('Load') ||
      message.contains('initialized') ||
      message.contains('✅') ||
      message.contains('✓')) {
    return false;
  }

  // 🔇 HIDE: Everything else by default
  return false;
}

/// Initialize System Stabilization with coordinated service initialization
Future<void> _initializeSystemStabilization() async {
  final coordinator = InitializationCoordinator();

  debugPrint('🚀 Initializing System Stabilization...');

  // Register services with dependencies (CacheManager registers itself)
  coordinator.registerService('StorageService');
  coordinator.registerService('UserService', dependencies: ['StorageService']);
  coordinator.registerService('NetworkInfrastructure');

  // Initialize storage service first
  await SimpleErrorHandler.safe(
    () async {
      coordinator.markServiceInitializing('StorageService');
      await StorageService.initialize();
      coordinator.markServiceInitialized('StorageService');
    },
    fallbackOperation: () async {
      coordinator.markServiceFailed(
        'StorageService',
        'Storage initialization failed',
      );
      debugPrint(
        '⚠️ Storage service initialization failed, using memory-only storage',
      );
    },
    operationName: 'storage_service_initialization',
  );

  // Initialize user service (depends on storage)
  await SimpleErrorHandler.safe(
    () async {
      await coordinator.waitForService('StorageService');
      coordinator.markServiceInitializing('UserService');
      await UserService.initialize();
      coordinator.markServiceInitialized('UserService');
    },
    fallbackOperation: () async {
      coordinator.markServiceFailed(
        'UserService',
        'User service initialization failed',
      );
      debugPrint('⚠️ User service initialization failed, using default user');
    },
    operationName: 'user_service_initialization',
  );

  // Initialize cache manager (handles its own coordination)
  await SimpleErrorHandler.safely(() async {
    final cacheManager = CacheManager();
    await cacheManager.initialize();
  }, operationName: 'cache_manager_initialization_wrapper');

  // Initialize authentication services (Riverpod-only after Phase 2 migration)
  await SimpleErrorHandler.safely(() async {
    coordinator.registerService('SupabaseService');

    // Initialize Supabase service (still needed for actual authentication)
    coordinator.markServiceInitializing('SupabaseService');
    await SupabaseService.instance.initialize();
    coordinator.markServiceInitialized('SupabaseService');

    debugPrint('✅ Authentication services initialized (Riverpod-only)');
    debugPrint(
      '📋 Phase 2 Migration: Removed AuthenticationService and GuestUserManager Provider dependencies',
    );
  }, operationName: 'authentication_services_initialization');

  // Initialize network infrastructure
  await SimpleErrorHandler.safely(() async {
    coordinator.markServiceInitializing('NetworkInfrastructure');
    await _initializeNetworkInfrastructure();
    coordinator.markServiceInitialized('NetworkInfrastructure');
  }, operationName: 'network_infrastructure_initialization');

  // Report initialization status
  final report = coordinator.getInitializationReport();
  debugPrint('📊 System Stabilization Initialization Report:');
  report.forEach((service, status) {
    final statusIcon = status == ServiceStatus.initialized ? '✅' : '❌';
    debugPrint('   $statusIcon $service: $status');
  });

  debugPrint('✅ System Stabilization Complete');
}

/// Initialize the enhanced network infrastructure
Future<void> _initializeNetworkInfrastructure() async {
  try {
    debugPrint('🚀 Initializing Enhanced Network Infrastructure...');

    final networkInitializer = NetworkInfrastructureInitializer();
    final success = await networkInitializer.initialize();

    if (success) {
      debugPrint('✅ Network infrastructure initialized successfully');

      // Log infrastructure status
      final status = networkInitializer.getInfrastructureStatus();
      debugPrint('📊 Network Infrastructure Status:');
      status.forEach((key, value) {
        debugPrint('   $key: $value');
      });
    } else {
      debugPrint(
        '⚠️ Network infrastructure initialization completed with errors:',
      );
      for (final error in networkInitializer.initializationErrors) {
        debugPrint('   ❌ $error');
      }
    }
  } catch (e, stackTrace) {
    debugPrint(
      '💥 Critical error during network infrastructure initialization: $e',
    );
    debugPrint('Stack trace: $stackTrace');
    // Continue with app startup even if network initialization fails
  }
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
      future: _initializeServices(),
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

  Future<void> _initializeServices() async {
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
              child: provider.Consumer<ThemeProvider>(
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
              ),
            ),
          ),
        );
      },
    );
  }
}

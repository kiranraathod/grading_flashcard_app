import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'services/reliable_operation_service.dart';
import 'services/cache_manager.dart';
import 'services/guest_session_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/usage_gate_service.dart';
import 'utils/config.dart';

/// Configure Supabase with production credentials
void configureSupabase() {
  AppConfig.setSupabaseConfig(
    url: 'https://saxopupmwfcfjxuflfrx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNheG9wdXBtd2ZjZmp4dWZsZnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxOTU1NjgsImV4cCI6MjA2NDc3MTU2OH0.1RdIw1v9FG76LJz7SNZY5YW51dcRP4XVCPCBLRgTXVU',
  );

  // Enable authentication for testing (you can disable these via debug panel)
  AppConfig.enableUsageLimits = true;
  AppConfig.enforceAuthentication = true;

  debugPrint('✅ Supabase configured successfully');
  debugPrint('🔐 Authentication features enabled for testing');
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Supabase BEFORE system initialization
  configureSupabase();

  // Initialize System Stabilization
  await _initializeSystemStabilization();

  runApp(MyApp());
}

/// Initialize System Stabilization with coordinated service initialization
Future<void> _initializeSystemStabilization() async {
  final coordinator = InitializationCoordinator();
  final reliableOps = ReliableOperationService();
  
  debugPrint('🚀 Initializing System Stabilization...');
  
  // Register services with dependencies
  coordinator.registerService('StorageService');
  coordinator.registerService('UserService', dependencies: ['StorageService']);
  coordinator.registerService('CacheManager');
  coordinator.registerService('GuestSessionService');
  coordinator.registerService('SupabaseAuthService');
  coordinator.registerService('UsageGateService', dependencies: ['GuestSessionService', 'SupabaseAuthService']);
  coordinator.registerService('NetworkInfrastructure');
  
  // Initialize storage service first
  await reliableOps.withFallback(
    primary: () async {
      coordinator.markServiceInitializing('StorageService');
      await StorageService.initialize();
      coordinator.markServiceInitialized('StorageService');
    },
    fallback: () async {
      coordinator.markServiceFailed('StorageService', 'Storage initialization failed');
      debugPrint('⚠️ Storage service initialization failed, using memory-only storage');
    },
    operationName: 'storage_service_initialization',
  );
  
  // Initialize user service (depends on storage)
  await reliableOps.withFallback(
    primary: () async {
      await coordinator.waitForService('StorageService');
      coordinator.markServiceInitializing('UserService');
      await UserService.initialize();
      coordinator.markServiceInitialized('UserService');
    },
    fallback: () async {
      coordinator.markServiceFailed('UserService', 'User service initialization failed');
      debugPrint('⚠️ User service initialization failed, using default user');
    },
    operationName: 'user_service_initialization',
  );
  
  // Initialize cache manager
  await reliableOps.safely(
    operation: () async {
      coordinator.markServiceInitializing('CacheManager');
      final cacheManager = CacheManager();
      await cacheManager.initialize();
      coordinator.markServiceInitialized('CacheManager');
    },
    operationName: 'cache_manager_initialization',
  );
  
  // Initialize guest session service (for anonymous users)
  await reliableOps.withFallback(
    primary: () async {
      coordinator.markServiceInitializing('GuestSessionService');
      final guestSession = GuestSessionService();
      await guestSession.initialize();
      coordinator.markServiceInitialized('GuestSessionService');
    },
    fallback: () async {
      coordinator.markServiceFailed('GuestSessionService', 'Guest session initialization failed');
      debugPrint('⚠️ Guest session service initialization failed, using default session');
    },
    operationName: 'guest_session_initialization',
  );
  
  // Initialize Supabase authentication service
  await reliableOps.withFallback(
    primary: () async {
      coordinator.markServiceInitializing('SupabaseAuthService');
      final authService = SupabaseAuthService();
      await authService.initialize();
      coordinator.markServiceInitialized('SupabaseAuthService');
    },
    fallback: () async {
      coordinator.markServiceFailed('SupabaseAuthService', 'Supabase auth initialization failed');
      debugPrint('⚠️ Supabase auth service initialization failed, using guest-only mode');
    },
    operationName: 'supabase_auth_initialization',
  );
  
  // Initialize usage gate service (depends on guest session and auth services)
  await reliableOps.safely(
    operation: () async {
      await coordinator.waitForService('GuestSessionService');
      await coordinator.waitForService('SupabaseAuthService');
      coordinator.markServiceInitializing('UsageGateService');
      UsageGateService(); // Initialize singleton
      coordinator.markServiceInitialized('UsageGateService');
    },
    operationName: 'usage_gate_initialization',
  );
  
  // Initialize network infrastructure
  await reliableOps.safely(
    operation: () async {
      coordinator.markServiceInitializing('NetworkInfrastructure');
      await _initializeNetworkInfrastructure();
      coordinator.markServiceInitialized('NetworkInfrastructure');
    },
    operationName: 'network_infrastructure_initialization',
  );
  
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
    debugPrint('✅ InterviewService initialized with ${interviewService.questions.length} questions');

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
    final speechToTextService = _services['speechToText'] as SpeechToTextService;
    final flashcardService = _services['flashcard'] as FlashcardService;
    final userService = _services['user'] as UserService;
    final networkService = _services['network'] as NetworkService;
    final interviewService = _services['interview'] as InterviewService;
    final recentViewService = _services['recentView'] as RecentViewService;
    final jobDescriptionService = _services['jobDescription'] as JobDescriptionService;

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
          child: MultiProvider(
            providers: [
              // Enhanced Network Services
              ChangeNotifierProvider(create: (_) => ConnectivityService()),
              ChangeNotifierProvider(create: (_) => SyncStatusTracker()),

              // Services as Providers (for backward compatibility)
              ChangeNotifierProvider.value(value: flashcardService),
              ChangeNotifierProvider.value(value: userService),
              ChangeNotifierProvider.value(value: networkService),
              ChangeNotifierProvider.value(value: interviewService),

              // Authentication Services
              ChangeNotifierProvider.value(value: GuestSessionService()),
              ChangeNotifierProvider.value(value: SupabaseAuthService()),
              ChangeNotifierProvider.value(value: UsageGateService()),

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

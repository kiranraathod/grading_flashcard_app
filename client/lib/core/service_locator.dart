/// Service Locator for Dependency Injection
///
/// Manages all dependencies for the FlashMaster application using GetIt.
/// Provides clean separation between:
/// - Data sources (existing services)
/// - Repositories (new repository layer)
/// - BLoCs (business logic)
///
/// Setup is done in phases to maintain compatibility during migration.
library;

import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Services (existing)
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import '../services/api_service.dart';
import '../services/authentication_service.dart';
import '../services/flashcard_service.dart';
import '../services/interview_service.dart';
import '../services/recent_view_service.dart';

// Repositories (new)
import '../repositories/flashcard_repository.dart';
import '../repositories/sync_repository.dart';

// BLoCs (new)
import '../blocs/flashcard/flashcard_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/network/network_bloc.dart';
import '../blocs/search/search_bloc.dart';
import '../blocs/recent_view/recent_view_bloc.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Setup all dependencies for the application
///
/// Call this during app initialization before running the app.
/// Dependencies are registered in order: Services → Repositories → BLoCs
Future<void> setupServiceLocator() async {
  debugPrint('🔧 Setting up service locator...');

  try {
    // Phase 1: Register existing services as singletons
    await _registerServices();

    // Phase 2: Register new repositories
    await _registerRepositories();

    // Phase 3: Register new BLoCs
    await _registerBlocs();

    debugPrint('✅ Service locator setup complete');
  } catch (error, stackTrace) {
    debugPrint('❌ Failed to setup service locator: $error');
    debugPrint('❌ Stack trace: $stackTrace');
    rethrow;
  }
}

/// Register existing services that repositories will wrap
///
/// These services are already initialized by the existing app,
/// so we register them as externals or lazy singletons
Future<void> _registerServices() async {
  debugPrint('📦 Registering services...');

  // Storage Service - already initialized by app
  if (!sl.isRegistered<StorageService>()) {
    sl.registerLazySingleton<StorageService>(() => StorageService());
  }

  // Supabase Service - already initialized by app
  if (!sl.isRegistered<SupabaseService>()) {
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService.instance);
  }

  // Connectivity Service - create new instance
  if (!sl.isRegistered<ConnectivityService>()) {
    sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  }

  // API Service - create new instance for BLoC usage
  if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton<ApiService>(() => ApiService());
  }

  // Authentication Service - create new instance for AuthBloc
  if (!sl.isRegistered<AuthenticationService>()) {
    sl.registerLazySingleton<AuthenticationService>(
      () => AuthenticationService.instance,
    );
  }

  // FlashcardService - for search and UI functionality
  if (!sl.isRegistered<FlashcardService>()) {
    sl.registerLazySingleton<FlashcardService>(
      () => FlashcardService(),
    );
  }

  // InterviewService - for search and interview functionality
  if (!sl.isRegistered<InterviewService>()) {
    sl.registerLazySingleton<InterviewService>(
      () => InterviewService(),
    );
  }

  // RecentViewService - for recent view tracking
  if (!sl.isRegistered<RecentViewService>()) {
    sl.registerLazySingleton<RecentViewService>(
      () => RecentViewService(),
    );
  }

  debugPrint('✅ Services registered');
}

/// Register repository layer
///
/// Repositories wrap existing services and provide the data layer
/// for the new BLoC architecture
Future<void> _registerRepositories() async {
  debugPrint('📚 Registering repositories...');

  // FlashcardRepository - wraps StorageService and SupabaseService
  if (!sl.isRegistered<FlashcardRepository>()) {
    sl.registerLazySingleton<FlashcardRepository>(
      () => FlashcardRepository(
        storageService: sl<StorageService>(),
        supabaseService: sl<SupabaseService>(),
        connectivityService: sl<ConnectivityService>(),
      ),
    );
  }

  // SyncRepository - manages coordinated sync operations (Phase 4)
  if (!sl.isRegistered<SyncRepository>()) {
    sl.registerLazySingleton<SyncRepository>(
      () => SyncRepository(
        connectivityService: sl<ConnectivityService>(),
        flashcardRepository: sl<FlashcardRepository>(),
      ),
    );
  }

  debugPrint('✅ Repositories registered');
}

/// Register BLoC layer
///
/// BLoCs provide business logic and state management,
/// using repositories for data operations
Future<void> _registerBlocs() async {
  debugPrint('🧠 Registering BLoCs...');

  // FlashcardBloc - manages flashcard sets and progress
  // Using factory registration so each screen gets its own instance
  if (!sl.isRegistered<FlashcardBloc>()) {
    sl.registerFactory<FlashcardBloc>(
      () => FlashcardBloc(repository: sl<FlashcardRepository>()),
    );
  }

  // AuthBloc - manages authentication state (Phase 2 Migration)
  // Using singleton since authentication state should be shared
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(authService: sl<AuthenticationService>()),
    );
  }

  // NetworkBloc - unified network state management (Phase 4)
  // Using singleton since network state should be shared
  if (!sl.isRegistered<NetworkBloc>()) {
    sl.registerLazySingleton<NetworkBloc>(
      () => NetworkBloc(connectivityService: sl<ConnectivityService>()),
    );
  }

  // SyncBloc - coordinated sync operations (Phase 4)
  // Using singleton since sync operations should be centralized
  if (!sl.isRegistered<SyncBloc>()) {
    sl.registerLazySingleton<SyncBloc>(
      () => SyncBloc(
        syncRepository: sl<SyncRepository>(),
        flashcardBloc: sl<FlashcardBloc>(),
        networkBloc: sl<NetworkBloc>(),
      ),
    );
  }

  // SearchBloc - search functionality (Phase 5)
  // Using factory since search can be instance-specific
  if (!sl.isRegistered<SearchBloc>()) {
    sl.registerFactory<SearchBloc>(
      () => SearchBloc(
        flashcardService: sl<FlashcardService>(),
        interviewService: sl<InterviewService>(),
      ),
    );
  }

  // RecentViewBloc - recent view tracking (Phase 5)
  // Using singleton since recent view state should be shared
  if (!sl.isRegistered<RecentViewBloc>()) {
    sl.registerLazySingleton<RecentViewBloc>(
      () => RecentViewBloc(
        recentViewService: sl<RecentViewService>(),
      ),
    );
  }

  // Note: StudyBloc requires WidgetRef which can't be provided at registration time
  // StudyBloc is created directly in StudyScreen with required dependencies

  debugPrint('✅ BLoCs registered');
}

/// Reset service locator (for testing)
///
/// Clears all registrations and allows re-registration.
/// Use this in tests or when completely resetting the app state.
Future<void> resetServiceLocator() async {
  debugPrint('🔄 Resetting service locator...');

  await sl.reset();

  debugPrint('✅ Service locator reset complete');
}

/// Check if all core dependencies are registered
///
/// Useful for debugging dependency issues
bool areCoreDependenciesRegistered() {
  final requiredServices = [
    StorageService,
    SupabaseService,
    ConnectivityService,
    ApiService,
    AuthenticationService,
    FlashcardService,
    InterviewService,
    RecentViewService,
  ];

  final requiredRepositories = [FlashcardRepository, SyncRepository];

  final requiredBlocs = [FlashcardBloc, AuthBloc, NetworkBloc, SyncBloc, SearchBloc, RecentViewBloc];

  for (final service in requiredServices) {
    if (!sl.isRegistered(instance: service)) {
      debugPrint('❌ Missing service: $service');
      return false;
    }
  }

  for (final repository in requiredRepositories) {
    if (!sl.isRegistered(instance: repository)) {
      debugPrint('❌ Missing repository: $repository');
      return false;
    }
  }

  for (final bloc in requiredBlocs) {
    if (!sl.isRegistered(instance: bloc)) {
      debugPrint('❌ Missing BLoC: $bloc');
      return false;
    }
  }

  debugPrint('✅ All core dependencies are registered');
  return true;
}

/// Log current registrations (for debugging)
void logRegistrations() {
  debugPrint('📋 Current Service Locator Registrations:');
  debugPrint(
    '  Services: ${sl.isRegistered<StorageService>() ? '✅' : '❌'} StorageService',
  );
  debugPrint(
    '  Services: ${sl.isRegistered<SupabaseService>() ? '✅' : '❌'} SupabaseService',
  );
  debugPrint(
    '  Services: ${sl.isRegistered<ConnectivityService>() ? '✅' : '❌'} ConnectivityService',
  );
  debugPrint(
    '  Services: ${sl.isRegistered<ApiService>() ? '✅' : '❌'} ApiService',
  );
  debugPrint(
    '  Services: ${sl.isRegistered<AuthenticationService>() ? '✅' : '❌'} AuthenticationService',
  );
  debugPrint(
    '  Repositories: ${sl.isRegistered<FlashcardRepository>() ? '✅' : '❌'} FlashcardRepository',
  );
  debugPrint(
    '  Repositories: ${sl.isRegistered<SyncRepository>() ? '✅' : '❌'} SyncRepository',
  );
  debugPrint(
    '  BLoCs: ${sl.isRegistered<FlashcardBloc>() ? '✅' : '❌'} FlashcardBloc',
  );
  debugPrint('  BLoCs: ${sl.isRegistered<AuthBloc>() ? '✅' : '❌'} AuthBloc');
  debugPrint('  BLoCs: ${sl.isRegistered<NetworkBloc>() ? '✅' : '❌'} NetworkBloc');
  debugPrint('  BLoCs: ${sl.isRegistered<SyncBloc>() ? '✅' : '❌'} SyncBloc');
  debugPrint('  BLoCs: ${sl.isRegistered<SearchBloc>() ? '✅' : '❌'} SearchBloc');
  debugPrint('  BLoCs: ${sl.isRegistered<RecentViewBloc>() ? '✅' : '❌'} RecentViewBloc');
}

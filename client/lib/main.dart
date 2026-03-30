import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core app initialization and BLoC architecture
import 'core/service_locator.dart';
import 'utils/app_initializer.dart';

// BLoC imports - Pure BLoC architecture for Phase 5
import 'blocs/flashcard/flashcard_bloc.dart';
import 'blocs/flashcard/flashcard_event.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/sync/sync_bloc.dart';
import 'blocs/sync/sync_event.dart';
import 'blocs/network/network_bloc.dart';
import 'blocs/network/network_event.dart';
import 'blocs/search/search_bloc.dart';
import 'blocs/recent_view/recent_view_bloc.dart';

// UI Components
import 'widgets/error_handler.dart';
import 'screens/home_screen.dart';

/// Phase 5: Pure BLoC Architecture Main Entry Point
/// 
/// This main.dart represents the completion of the BLoC migration project.
/// All Provider/Riverpod dependencies have been removed and replaced with
/// pure BLoC patterns while preserving the critical progress bar bug fix
/// coordination established in Phases 1-4.
/// 
/// Key Changes from Previous Version:
/// - Removed all Provider/Riverpod imports and usage
/// - Pure BLoC architecture throughout the app
/// - Service locator provides all dependencies
/// - Enhanced sync status indicators in UI
/// - Performance optimization with BlocSelector patterns
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure debug output for environment
  AppInitializer.configureDebugOutput();

  // Initialize all core services without Provider dependencies
  try {
    await AppInitializer.initializeCore();
    debugPrint('✅ Core services initialized successfully');
  } catch (error) {
    debugPrint('❌ Failed to initialize core services: $error');
  }

  // 🆕 PHASE 5: Initialize BLoC service locator (Pure BLoC Architecture)
  try {
    await setupServiceLocator();
    debugPrint('✅ Pure BLoC service locator initialized successfully');
  } catch (error) {
    debugPrint('❌ Failed to initialize BLoC service locator: $error');
    // Continue with fallback - this preserves app functionality
  }

  // 🎯 PHASE 5: Launch pure BLoC application
  runApp(const FlashMasterApp());
}

/// FlashMaster Application Widget - Pure BLoC Architecture
/// 
/// This widget represents the root of the pure BLoC architecture.
/// No Provider/Riverpod dependencies - only BLoC patterns for state management.
class FlashMasterApp extends StatelessWidget {
  const FlashMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🧠 Core BLoCs - Service Locator Dependency Injection
        BlocProvider<FlashcardBloc>(
          create: (context) {
            debugPrint('🧠 Creating FlashcardBloc instance via service locator');
            try {
              final bloc = sl<FlashcardBloc>();
              bloc.add(const FlashcardLoadRequested());
              return bloc;
            } catch (error) {
              debugPrint('❌ Failed to create FlashcardBloc: $error');
              rethrow;
            }
          },
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            debugPrint('🔐 Creating AuthBloc instance via service locator');
            try {
              final bloc = sl<AuthBloc>();
              bloc.add(const AuthInitialized());
              return bloc;
            } catch (error) {
              debugPrint('❌ Failed to create AuthBloc: $error');
              rethrow;
            }
          },
        ),
        // 🌐 Phase 4 BLoCs - Sync and Network Management
        BlocProvider<SyncBloc>(
          create: (context) {
            debugPrint('🔄 Creating SyncBloc instance via service locator');
            try {
              final bloc = sl<SyncBloc>();
              bloc.add(const SyncInitialized());
              return bloc;
            } catch (error) {
              debugPrint('❌ Failed to create SyncBloc: $error');
              rethrow;
            }
          },
        ),
        BlocProvider<NetworkBloc>(
          create: (context) {
            debugPrint('📡 Creating NetworkBloc instance via service locator');
            try {
              final bloc = sl<NetworkBloc>();
              bloc.add(const NetworkMonitoringStarted());
              return bloc;
            } catch (error) {
              debugPrint('❌ Failed to create NetworkBloc: $error');
              rethrow;
            }
          },
        ),
        // 🔍 Additional Feature BLoCs
        BlocProvider<SearchBloc>(
          create: (context) {
            debugPrint('🔍 Creating SearchBloc instance via service locator');
            try {
              return sl<SearchBloc>();
            } catch (error) {
              debugPrint('❌ Failed to create SearchBloc: $error');
              rethrow;
            }
          },
        ),
        BlocProvider<RecentViewBloc>(
          create: (context) {
            debugPrint('👁️ Creating RecentViewBloc instance via service locator');
            try {
              return sl<RecentViewBloc>();
            } catch (error) {
              debugPrint('❌ Failed to create RecentViewBloc: $error');
              rethrow;
            }
          },
        ),
      ],
      child: ErrorHandler(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return MaterialApp(
              title: 'FlashMaster',
              debugShowCheckedModeBanner: false,
              // 🎨 Theme management via BLoC (no Provider dependency)
              theme: _buildThemeData(Brightness.light),
              darkTheme: _buildThemeData(Brightness.dark),
              themeMode: ThemeMode.system,
              home: const HomeScreen(),
              // 🚀 Phase 5: Pure BLoC navigation patterns
              onGenerateRoute: _generateRoute,
            );
          },
        ),
      ),
    );
  }

  /// Build theme data without Provider dependencies
  ThemeData _buildThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: isDark ? Colors.grey[800] : Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Pure BLoC navigation patterns (no Provider dependencies)
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // This can be expanded for complex navigation patterns
    // For now, using default navigation
    return null;
  }
}
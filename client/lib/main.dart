import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/error_handler.dart';
// 🆕 NEW UNIFIED IMPORTS
import 'utils/app_initializer.dart';
import 'utils/provider_manager.dart';
import 'utils/app_widget_manager.dart';
import 'utils/auth_connection_manager.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 Configure debug output for environment
  AppInitializer.configureDebugOutput();

  // Initialize all core services
  await AppInitializer.initializeCore();

  // Wrap the app with ProviderScope for Riverpod
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic> _services = {};

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
    // Use AppInitializer to create all services
    _services = await AppInitializer.createApplicationServices();

    // 🔗 Set up auth-service connection using AuthConnectionManager
    AuthConnectionManager.setupAuthServiceConnection(_services);
  }

  Widget _buildMainApp() {
    debugPrint('⭐⭐⭐ INITIALIZING APPLICATION ⭐⭐⭐');
    
    return ProviderManager.createProviderTree(
      services: _services,
      onThemeChanged: AuthConnectionManager.logThemeChange,
      child: ErrorHandler(
        child: Consumer(
          builder: (context, WidgetRef ref, _) {
            // 🔗 Set up auth-service connection on first widget build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AuthConnectionManager.establishAuthConnection(ref, _services);
            });
            
            return AppWidgetManager.createMainApp(
              child: Container(), // AppWidgetManager handles the full app
            );
          },
        ),
      ),
    );
  }
}

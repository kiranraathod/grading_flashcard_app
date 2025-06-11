import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import 'simple_error_handler.dart';
import 'reliable_operation_service.dart';

/// Core Supabase service providing database and authentication capabilities
/// 
/// Follows the existing service patterns with reliable operations and error handling.
/// All authentication features are controlled by feature flags in AuthConfig.
class SupabaseService extends ChangeNotifier {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  final ReliableOperationService _reliableOps = ReliableOperationService();
  
  SupabaseClient? _client;
  bool _isInitialized = false;
  
  // Private constructor
  SupabaseService._();
  
  /// Get the Supabase client instance
  SupabaseClient get client {
    if (!AuthConfig.enableAuthentication) {
      throw Exception('Supabase authentication is disabled. Enable AuthConfig.enableAuthentication first.');
    }
    if (!_isInitialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  /// Check if Supabase is initialized and ready
  bool get isInitialized => _isInitialized && AuthConfig.enableAuthentication;
  
  /// Initialize Supabase client
  /// 
  /// This method is safe to call multiple times and will only initialize once.
  /// Respects feature flags - won't initialize if authentication is disabled.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SupabaseService already initialized');
      return;
    }
    
    if (!AuthConfig.enableAuthentication) {
      debugPrint('Supabase authentication disabled via feature flag');
      return;
    }
    
    await SimpleErrorHandler.safely(
      () async {
        debugPrint('Initializing Supabase service...');
        
        await Supabase.initialize(
          url: AuthConfig.supabaseUrl,
          anonKey: AuthConfig.supabaseAnonKey,
          debug: AuthConfig.enableAuthDebugLogging,
        );
        
        _client = Supabase.instance.client;
        _isInitialized = true;
        
        debugPrint('✅ Supabase service initialized successfully');
        notifyListeners();
      },
      operationName: 'supabase_service_initialization',
    );
  }
  
  /// Test connection to Supabase
  Future<bool> testConnection() async {
    if (!isInitialized) return false;
    
    return await _reliableOps.withFallback(
      primary: () async {
        // Simple query to test connection
        await client.from('categories').select('count').limit(1);
        debugPrint('Supabase connection test successful');
        return true;
      },
      fallback: () async {
        debugPrint('Supabase connection test failed');
        return false;
      },
      operationName: 'supabase_connection_test',
    );
  }
  
  /// Get current authentication status
  bool get isAuthenticated {
    if (!isInitialized) return false;
    return client.auth.currentSession != null;
  }
  
  /// Get current user
  User? get currentUser {
    if (!isInitialized) return null;
    return client.auth.currentUser;
  }
  
  /// Get current user ID
  String? get currentUserId {
    return currentUser?.id;
  }
  
  /// Dispose resources
  @override
  void dispose() {
    debugPrint('Disposing SupabaseService');
    super.dispose();
  }
}

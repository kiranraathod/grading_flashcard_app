import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import 'reliable_operation_service.dart';
import 'guest_session_service.dart';

/// SupabaseAuthService handles authentication with Supabase
/// 
/// Follows existing service patterns with ChangeNotifier and ReliableOperationService.
/// Integrates with GuestSessionService for seamless data migration.
class SupabaseAuthService extends ChangeNotifier {
  // Singleton pattern
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final ReliableOperationService _reliableOps = ReliableOperationService();
  final GuestSessionService _guestSession = GuestSessionService();
  
  User? _currentUser;
  bool _isInitialized = false;
  bool _isAuthenticating = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthenticating => _isAuthenticating;
  String? get userId => _currentUser?.id;
  String? get userEmail => _currentUser?.email;

  /// Initialize Supabase authentication
  Future<void> initialize() async {
    await _reliableOps.withFallback(
      primary: () async {
        // Check if Supabase is configured
        if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
          debugPrint('⚠️ SupabaseAuthService: Supabase not configured, using guest-only mode');
          _isInitialized = true;
          notifyListeners();
          return;
        }

        // Initialize Supabase
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        
        // Set up auth state listener
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          _handleAuthStateChange(data.session?.user);
        });
        
        // Check current session
        final session = Supabase.instance.client.auth.currentSession;
        _currentUser = session?.user;
        
        _isInitialized = true;
        notifyListeners();
        
        debugPrint('✅ SupabaseAuthService: Initialized successfully');
        if (_currentUser != null) {
          debugPrint('👤 SupabaseAuthService: User already signed in: ${_currentUser!.email}');
        }
      },
      fallback: () async {
        debugPrint('❌ SupabaseAuthService: Failed to initialize, using guest-only mode');
        _isInitialized = true;
        notifyListeners();
      },
      operationName: 'supabase_auth_initialization',
    );
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(User? user) {
    _currentUser = user;
    notifyListeners();
    
    if (user != null) {
      debugPrint('👤 SupabaseAuthService: User signed in: ${user.email}');
      _handleSuccessfulAuthentication();
    } else {
      debugPrint('👋 SupabaseAuthService: User signed out');
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    if (!_isInitialized) {
      debugPrint('⚠️ SupabaseAuthService: Not initialized');
      throw Exception('Authentication service not initialized');
    }

    if (AppConfig.supabaseUrl.isEmpty) {
      debugPrint('⚠️ SupabaseAuthService: Supabase not configured');
      throw Exception('Authentication service not configured');
    }

    return await _reliableOps.withDefault(
      operation: () async {
        _isAuthenticating = true;
        notifyListeners();

        try {
          final response = await Supabase.instance.client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: AppConfig.authRedirectUrl,
          );

          _isAuthenticating = false;
          notifyListeners();

          return response;
        } catch (e) {
          _isAuthenticating = false;
          notifyListeners();
          
          final errorString = e.toString();
          debugPrint('❌ SupabaseAuthService: Google sign-in failed: $errorString');
          
          // Enhance error context for better debugging
          if (errorString.contains('provider is not enabled')) {
            debugPrint('🚨 SupabaseAuthService: Google OAuth provider not enabled in Supabase dashboard');
            throw Exception('Google OAuth provider not enabled: $errorString');
          } else if (errorString.contains('validation_failed')) {
            debugPrint('🚨 SupabaseAuthService: OAuth validation failed');
            throw Exception('OAuth validation failed: $errorString');
          }
          
          rethrow;
        }
      },
      defaultValue: false,
      operationName: 'google_sign_in',
    );
  }

  /// Handle successful authentication and migrate guest data
  Future<void> _handleSuccessfulAuthentication() async {
    await _reliableOps.safely(
      operation: () async {
        final guestSessionId = _guestSession.currentSessionId;
        
        if (guestSessionId != null && _currentUser != null) {
          debugPrint('🔄 SupabaseAuthService: Starting guest data migration...');
          
          try {
            // Call Supabase migration function
            final result = await Supabase.instance.client.rpc(
              'migrate_guest_data_to_user',
              params: {
                'p_user_id': _currentUser!.id,
                'p_guest_session_id': guestSessionId,
              },
            );
            
            debugPrint('📊 SupabaseAuthService: Migration result: $result');
          } catch (e) {
            debugPrint('❌ SupabaseAuthService: Migration failed: $e');
            // Continue anyway - don't block authentication
          }
          
          // Clear guest session after migration attempt
          await _guestSession.clearSession();
          
          debugPrint('✅ SupabaseAuthService: Guest data migration completed');
        }
      },
      operationName: 'handle_successful_authentication',
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!_isInitialized || _currentUser == null) {
      return;
    }

    await _reliableOps.safely(
      operation: () async {
        await Supabase.instance.client.auth.signOut();
        _currentUser = null;
        notifyListeners();
        debugPrint('👋 SupabaseAuthService: User signed out successfully');
      },
      operationName: 'sign_out',
    );
  }

  /// Get authentication summary for debugging
  Map<String, dynamic> getAuthSummary() {
    return {
      'isInitialized': _isInitialized,
      'isAuthenticated': isAuthenticated,
      'isAuthenticating': _isAuthenticating,
      'userId': userId,
      'userEmail': userEmail,
      'supabaseConfigured': AppConfig.supabaseUrl.isNotEmpty,
    };
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import 'supabase_service.dart';
import 'simple_error_handler.dart';

/// Authentication state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailVerificationRequired,
  error,
}

/// Authentication service providing user sign-in/sign-out functionality
/// 
/// Follows existing service patterns with comprehensive error handling.
/// All features controlled by AuthConfig feature flags.
class AuthenticationService extends ChangeNotifier {
  static AuthenticationService? _instance;
  static AuthenticationService get instance => _instance ??= AuthenticationService._();
  
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  AuthState _authState = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // Private constructor
  AuthenticationService._();
  
  /// Current authentication state
  AuthState get authState => _authState;
  
  /// Current authentication state as string (for debug purposes)
  String get currentAuthState => _authState.toString().split('.').last;
  
  /// Current authenticated user
  User? get currentUser => _currentUser;
  
  /// Last error message
  String? get errorMessage => _errorMessage;
  
  /// Whether authentication is enabled and ready
  bool get isEnabled => AuthConfig.enableAuthentication && _supabaseService.isInitialized;
  
  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether user is currently authenticated
  bool get isAuthenticated => _currentUser != null && authState == AuthState.authenticated;
  
  /// Initialize authentication service
  Future<void> initialize() async {
    if (!AuthConfig.enableAuthentication) {
      debugPrint('Authentication disabled via feature flag');
      return;
    }
    
    await SimpleErrorHandler.safely(
      () async {
        debugPrint('Initializing AuthenticationService...');
        
        // Listen to auth state changes
        _supabaseService.client.auth.onAuthStateChange.listen((data) {
          _handleAuthStateChange(data.event, data.session);
        });
        
        // Check current session
        final session = _supabaseService.client.auth.currentSession;
        if (session != null) {
          _currentUser = session.user;
          _authState = AuthState.authenticated;
          debugPrint('Found existing auth session for user: ${_currentUser?.email}');
        } else {
          _authState = AuthState.unauthenticated;
        }
        
        notifyListeners();
        _isInitialized = true;
        debugPrint('✅ AuthenticationService initialized');
      },
      operationName: 'auth_service_initialization',
    );
  }
  
  /// Handle authentication state changes
  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint('Auth state changed: $event');
    
    switch (event) {
      case AuthChangeEvent.signedIn:
        _currentUser = session?.user;
        _authState = AuthState.authenticated;
        _errorMessage = null;
        debugPrint('User signed in: ${_currentUser?.email}');
        break;
        
      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _authState = AuthState.unauthenticated;
        _errorMessage = null;
        debugPrint('User signed out');
        break;
        
      case AuthChangeEvent.userUpdated:
        _currentUser = session?.user;
        debugPrint('User updated: ${_currentUser?.email}');
        break;
        
      default:
        break;
    }
    
    notifyListeners();
  }  
  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    if (!isEnabled) {
      debugPrint('Authentication not enabled');
      return false;
    }
    
    return await SimpleErrorHandler.safe<bool>(
      () async {
        _authState = AuthState.loading;
        _errorMessage = null;
        notifyListeners();
        
        try {
          await _supabaseService.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          
          debugPrint('Email sign-in successful for: $email');
          return true;
        } catch (e) {
          debugPrint('Email sign-in error: $e');
          
          // Handle specific Supabase authentication errors
          if (e.toString().contains('email_provider_disabled')) {
            _authState = AuthState.error;
            _errorMessage = 'Email login is currently disabled. Please try Google sign-in instead.';
          } else if (e.toString().contains('invalid_credentials')) {
            _authState = AuthState.error;
            _errorMessage = 'Invalid email or password. Please check your credentials.';
          } else {
            _authState = AuthState.error;
            _errorMessage = 'Login failed. Please try Google sign-in instead.';
          }
          notifyListeners();
          return false;
        }
      },
      fallbackOperation: () async {
        _authState = AuthState.error;
        _errorMessage = 'Email login is currently unavailable. Please try Google sign-in.';
        debugPrint('Email sign-in failed for: $email');
        notifyListeners();
        return false;
      },
      operationName: 'sign_in_with_email',
    );
  }
  
  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    if (!isEnabled) return false;
    
    return await SimpleErrorHandler.safe<bool>(
      () async {
        _authState = AuthState.loading;
        _errorMessage = null;
        notifyListeners();
        
        try {
          final response = await _supabaseService.client.auth.signUp(
            email: email,
            password: password,
          );
          
          if (AuthConfig.requireEmailVerification && response.user?.emailConfirmedAt == null) {
            _authState = AuthState.emailVerificationRequired;
            debugPrint('Email verification required for: $email');
          }
          
          debugPrint('Email sign-up successful for: $email');
          return true;
        } catch (e) {
          debugPrint('Email sign-up error: $e');
          
          // Handle specific Supabase authentication errors
          if (e.toString().contains('email_provider_disabled')) {
            _authState = AuthState.error;
            _errorMessage = 'Email registration is currently disabled. Please try Google sign-in instead.';
          } else if (e.toString().contains('user_already_exists')) {
            _authState = AuthState.error;
            _errorMessage = 'This email is already registered. Please sign in instead of signing up.';
          } else {
            _authState = AuthState.error;
            _errorMessage = 'Registration failed. Please try Google sign-in instead.';
          }
          notifyListeners();
          return false;
        }
      },
      fallbackOperation: () async {
        _authState = AuthState.error;
        _errorMessage = 'Email registration is currently unavailable. Please try Google sign-in.';
        notifyListeners();
        return false;
      },
      operationName: 'sign_up_with_email',
    );
  }
  
  /// Demo authentication for testing (when real auth is unavailable)
  Future<bool> signInDemo() async {
    if (!AuthConfig.enableDemoMode) return false;
    
    debugPrint('🧪 Demo authentication - simulating successful sign-in');
    
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
    
    // Simulate authentication delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _authState = AuthState.authenticated;
    
    // 🔧 FIX: Create a demo user object for testing
    _currentUser = User(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      appMetadata: {'provider': 'demo'},
      userMetadata: {
        'email': 'demo@flashmaster.app',
        'full_name': 'Demo User',
        'demo_mode': true,
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    _errorMessage = null;
    notifyListeners();
    
    debugPrint('✅ Demo authentication successful - user created with ID: ${_currentUser?.id}');
    debugPrint('🔍 Authentication status: isAuthenticated=$isAuthenticated, authState=$authState');
    return true;
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (!isEnabled) return false;
    
    return await SimpleErrorHandler.safe<bool>(
      () async {
        _authState = AuthState.loading;
        _errorMessage = null;
        notifyListeners();
        
        try {
          debugPrint('🔍 Starting Google OAuth sign-in...');
          
          // For web applications, use the current URL as redirect
          await _supabaseService.client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb ? null : 'your-app://auth-callback',
          );
          
          debugPrint('🔍 Google OAuth response received');
          debugPrint('Google sign-in successful');
          return true;
        } catch (e) {
          debugPrint('❌ Google sign-in error: $e');
          _authState = AuthState.error;
          _errorMessage = 'Google sign-in failed: ${e.toString()}';
          notifyListeners();
          return false;
        }
      },
      fallbackOperation: () async {
        _authState = AuthState.error;
        _errorMessage = 'Google sign-in is currently unavailable';
        notifyListeners();
        return false;
      },
      operationName: 'sign_in_with_google',
    );
  }  
  /// Sign out current user
  Future<bool> signOut() async {
    if (!isEnabled) return false;
    
    return await SimpleErrorHandler.safe<bool>(
      () async {
        await _supabaseService.client.auth.signOut();
        debugPrint('User signed out successfully');
        return true;
      },
      fallbackOperation: () async {
        // Force local sign out even if server call fails
        _currentUser = null;
        _authState = AuthState.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        debugPrint('Local sign out completed');
        return true;
      },
      operationName: 'sign_out',
    );
  }
  
  /// Reset password for email
  Future<bool> resetPassword(String email) async {
    if (!isEnabled) return false;
    
    return await SimpleErrorHandler.safe<bool>(
      () async {
        await _supabaseService.client.auth.resetPasswordForEmail(email);
        debugPrint('Password reset email sent to: $email');
        return true;
      },
      fallbackOperation: () async {
        _errorMessage = 'Failed to send password reset email';
        debugPrint('Password reset failed for: $email');
        return false;
      },
      operationName: 'reset_password',
    );
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    debugPrint('Disposing AuthenticationService');
    super.dispose();
  }
}

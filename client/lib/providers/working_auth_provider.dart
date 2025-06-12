import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/simple_auth_state.dart';
import '../services/working_secure_auth_storage.dart';
import '../services/supabase_service.dart';
import '../utils/config.dart';

/// Simple authentication notifier
class SimpleAuthNotifier extends StateNotifier<AuthState> {
  late final SupabaseClient _supabase;
  
  SimpleAuthNotifier() : super(const AuthStateInitial()) {
    _supabase = SupabaseService.instance.client;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (!AuthConfig.enableAuthentication) {
      debugPrint('Authentication disabled via config');
      state = const AuthStateUnauthenticated();
      return;
    }

    try {
      state = const AuthStateLoading();
      
      // Check for existing Supabase session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('Found existing session for: ${session.user.email}');
        state = AuthStateAuthenticated(session.user);
        await _migrateGuestDataIfNeeded(session.user.id);
        return;
      }

      // Check for guest user data
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        debugPrint('Found guest user: ${guestData.id}');
        state = AuthStateGuest(guestData.id);
        return;
      }

      debugPrint('No existing authentication found');
      state = const AuthStateUnauthenticated();
      
      // Listen to Supabase auth changes
      _supabase.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.event, data.session);
      });
      
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
      state = AuthStateError('Authentication initialization failed: $e');
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint('🔄 Auth state changed: $event');
    
    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session?.user != null) {
          state = AuthStateAuthenticated(session!.user);
          _migrateGuestDataIfNeeded(session.user.id);
        }
        break;
        
      case AuthChangeEvent.signedOut:
        state = const AuthStateUnauthenticated();
        break;
        
      case AuthChangeEvent.userUpdated:
        if (session?.user != null) {
          state = AuthStateAuthenticated(session!.user);
        }
        break;
        
      default:
        break;
    }
  }

  Future<void> _migrateGuestDataIfNeeded(String userId) async {
    try {
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        debugPrint('🔄 Migrating guest data to authenticated user');
        
        final guestActions = await WorkingSecureAuthStorage.getUserActions(guestData.id);
        if (guestActions.isNotEmpty) {
          await WorkingSecureAuthStorage.storeUserActions(userId, guestActions);
        }
        
        await WorkingSecureAuthStorage.clearGuestData();
        debugPrint('✅ Guest data migration completed');
      }
    } catch (e) {
      debugPrint('❌ Guest data migration failed: $e');
    }
  }  Future<void> signInAnonymously() async {
    try {
      state = const AuthStateLoading();
      
      final response = await _supabase.auth.signInAnonymously();
      if (response.user != null) {
        final guestId = response.user!.id;
        await WorkingSecureAuthStorage.storeGuestData(guestId, {
          'created_at': DateTime.now().toIso8601String(),
          'type': 'anonymous',
        });
        
        state = AuthStateGuest(guestId);
        debugPrint('✅ Anonymous sign-in successful: $guestId');
      }
    } catch (e) {
      debugPrint('❌ Anonymous sign-in failed: $e');
      state = AuthStateError('Failed to create guest session: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthStateLoading();
      
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email sign-in successful: $email');
    } catch (e) {
      debugPrint('❌ Email sign-in failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      state = const AuthStateLoading();
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (AuthConfig.requireEmailVerification && 
          response.user?.emailConfirmedAt == null) {
        state = const AuthStateEmailVerificationRequired();
      }
      
      debugPrint('✅ Email sign-up successful: $email');
    } catch (e) {
      debugPrint('❌ Email sign-up failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AuthStateLoading();
      
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'your-app://auth-callback',
      );
      
      debugPrint('✅ Google sign-in initiated');
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signInDemo() async {
    if (!AuthConfig.enableDemoMode) {
      state = const AuthStateError('Demo mode disabled');
      return;
    }

    try {
      state = const AuthStateLoading();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create a simple demo user object
      final demoUser = {
        'id': 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': 'demo@flashmaster.app',
        'user_metadata': {
          'full_name': 'Demo User',
          'demo_mode': true,
        },
      };
      
      state = AuthStateAuthenticated(demoUser);
      debugPrint('✅ Demo authentication successful');
    } catch (e) {
      debugPrint('❌ Demo authentication failed: $e');
      state = AuthStateError('Demo authentication failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await WorkingSecureAuthStorage.clearSession();
      state = const AuthStateUnauthenticated();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      state = const AuthStateUnauthenticated();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent: $email');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid_credentials')) {
      return 'Invalid email or password';
    } else if (errorString.contains('email_provider_disabled')) {
      return 'Email authentication is temporarily unavailable';
    } else if (errorString.contains('user_already_exists')) {
      return 'An account with this email already exists';
    } else if (errorString.contains('weak_password')) {
      return 'Password is too weak';
    } else if (errorString.contains('invalid_email')) {
      return 'Please enter a valid email address';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }
}

// Provider instances
final authNotifierProvider = StateNotifierProvider<SimpleAuthNotifier, AuthState>((ref) {
  return SimpleAuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateAuthenticated;
});

final currentUserProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.user;
  }
  return null;
});

final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateGuest;
});

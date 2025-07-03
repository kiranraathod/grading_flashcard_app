import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../services/authentication_service.dart' hide AuthState;
import '../../services/working_secure_auth_storage.dart';
import '../../services/supabase_service.dart';
import '../../services/storage_service.dart';
import '../../utils/config.dart';
import '../../utils/migration_debug_helper.dart';
import '../../utils/enhanced_safe_map_converter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc: Replace Riverpod authentication with BLoC pattern
/// 
/// Phase 2 Migration: Eliminates state management conflicts by providing
/// unified authentication state through BLoC pattern instead of Riverpod.
/// 
/// Key Benefits:
/// - Single source of truth for authentication
/// - Consistent state management with rest of app
/// - Better coordination with FlashcardBloc
/// - Eliminates progress bar bug through unified state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationService _authService;
  SupabaseClient? _supabase;
  StreamSubscription? _authSubscription;
  
  // Callback system for data migration (migrated from Riverpod)
  final List<Function(String userId)> _onUserDataMigrated = [];
  
  AuthBloc({
    required AuthenticationService authService,
  }) : _authService = authService,
       super(const AuthStateInitial()) {
    
    _supabase = SupabaseService.instance.client;
    
    // Use authService for validation
    debugPrint('🔧 AuthBloc: Initialized with authService enabled: ${_authService.isEnabled}');
    
    // Register event handlers
    on<AuthInitialized>(_onAuthInitialized);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInAnonymouslyRequested>(_onSignInAnonymouslyRequested);
    on<AuthSignInDemoRequested>(_onSignInDemoRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthStateChangeDetected>(_onAuthStateChangeDetected);
    on<AuthGuestDataMigrationRequested>(_onGuestDataMigrationRequested);
  }
  
  /// Register a callback to be called when user data migration completes
  /// 
  /// Compatible with existing service notification system
  void onUserDataMigrated(Function(String userId) callback) {
    _onUserDataMigrated.add(callback);
  }
  
  /// Remove a data migration callback
  void removeUserDataMigrationCallback(Function(String userId) callback) {
    _onUserDataMigrated.remove(callback);
  }
  
  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    super.close();
  }
  
  /// Initialize authentication and check for existing sessions
  Future<void> _onAuthInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    if (!AuthConfig.enableAuthentication) {
      debugPrint('🔧 AuthBloc: Authentication disabled via config');
      emit(const AuthStateUnauthenticated());
      return;
    }
    
    try {
      emit(const AuthStateLoading());
      
      // Check for existing Supabase session
      final session = _supabase?.auth.currentSession;
      if (session != null) {
        debugPrint('🔍 AuthBloc: Found existing session for: ${session.user.email}');
        emit(AuthStateAuthenticated(session.user));
        
        // Trigger guest data migration if needed
        add(AuthGuestDataMigrationRequested(userId: session.user.id));
        return;
      }
      
      // Check for guest user data
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        debugPrint('🔍 AuthBloc: Found guest user: ${guestData.id}');
        emit(AuthStateGuest(guestData.id));
        return;
      }
      
      debugPrint('🔍 AuthBloc: No existing authentication found');
      emit(const AuthStateUnauthenticated());
      
      // Setup Supabase auth state listener
      _setupAuthStateListener();
      
    } catch (e) {
      debugPrint('❌ AuthBloc: Auth initialization error: $e');
      emit(AuthStateError('Authentication initialization failed: $e'));
    }
  }
  
  /// Setup Supabase authentication state listener
  void _setupAuthStateListener() {
    _authSubscription = _supabase?.auth.onAuthStateChange.listen((data) {
      add(AuthStateChangeDetected(
        eventType: data.event.name,
        session: data.session,
      ));
    });
  }  
  /// Handle external authentication state changes from Supabase
  void _onAuthStateChangeDetected(
    AuthStateChangeDetected event,
    Emitter<AuthState> emit,
  ) {
    debugPrint('🔄 AuthBloc: Auth state changed: ${event.eventType}');
    
    switch (event.eventType) {
      case 'signedIn':
        if (event.session?.user != null) {
          final user = event.session!.user;
          debugPrint('✅ AuthBloc: User signed in: ${user.id} (${user.email})');
          emit(AuthStateAuthenticated(user));
          
          // Generate migration report before attempting migration
          MigrationDebugHelper.generateMigrationReport(user.id);
          
          // Trigger guest data migration
          add(AuthGuestDataMigrationRequested(userId: user.id));
        }
        break;
        
      case 'signedOut':
        debugPrint('👋 AuthBloc: User signed out');
        emit(const AuthStateUnauthenticated());
        break;
        
      case 'userUpdated':
        if (event.session?.user != null) {
          final user = event.session!.user;
          debugPrint('🔄 AuthBloc: User updated: ${user.id}');
          emit(AuthStateAuthenticated(user));
        }
        break;
        
      default:
        debugPrint('🔄 AuthBloc: Unhandled auth event: ${event.eventType}');
        break;
    }
  }
  
  /// Handle email sign in request
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      
      debugPrint('✅ AuthBloc: Email sign-in successful: ${event.email}');
      // State will be updated by auth state listener
      
    } catch (e) {
      debugPrint('❌ AuthBloc: Email sign-in failed: $e');
      emit(AuthStateError(_getErrorMessage(e)));
    }
  }
  
  /// Handle email sign up request
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      final response = await _supabase!.auth.signUp(
        email: event.email,
        password: event.password,
      );
      
      if (AuthConfig.requireEmailVerification && 
          response.user?.emailConfirmedAt == null) {
        emit(const AuthStateEmailVerificationRequired());
      }
      
      debugPrint('✅ AuthBloc: Email sign-up successful: ${event.email}');
      
    } catch (e) {
      debugPrint('❌ AuthBloc: Email sign-up failed: $e');
      emit(AuthStateError(_getErrorMessage(e)));
    }
  }
  
  /// Handle Google sign in request
  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'your-app://auth-callback',
      );
      
      debugPrint('✅ AuthBloc: Google sign-in initiated');
      
    } catch (e) {
      debugPrint('❌ AuthBloc: Google sign-in failed: $e');
      emit(AuthStateError(_getErrorMessage(e)));
    }
  }  
  /// Handle anonymous sign in request
  Future<void> _onSignInAnonymouslyRequested(
    AuthSignInAnonymouslyRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      final response = await _supabase!.auth.signInAnonymously();
      if (response.user != null) {
        final guestId = response.user!.id;
        await WorkingSecureAuthStorage.storeGuestData(guestId, {
          'created_at': DateTime.now().toIso8601String(),
          'type': 'anonymous',
        });
        
        emit(AuthStateGuest(guestId));
        debugPrint('✅ AuthBloc: Anonymous sign-in successful: $guestId');
      }
    } catch (e) {
      debugPrint('❌ AuthBloc: Anonymous sign-in failed: $e');
      emit(AuthStateError('Failed to create guest session: $e'));
    }
  }
  
  /// Handle demo sign in request
  Future<void> _onSignInDemoRequested(
    AuthSignInDemoRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!AuthConfig.enableDemoMode) {
      emit(const AuthStateError('Demo mode disabled'));
      return;
    }
    
    try {
      emit(const AuthStateLoading());
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create a simple demo user object (compatible with existing code)
      final demoUser = {
        'id': 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': 'demo@flashmaster.app',
        'user_metadata': {
          'full_name': 'Demo User',
          'demo_mode': true,
        },
      };
      
      emit(AuthStateAuthenticated(demoUser));
      debugPrint('✅ AuthBloc: Demo authentication successful');
    } catch (e) {
      debugPrint('❌ AuthBloc: Demo authentication failed: $e');
      emit(AuthStateError('Demo authentication failed: $e'));
    }
  }
  
  /// Handle sign out request
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (_supabase != null) {
        await _supabase!.auth.signOut();
      }
      await WorkingSecureAuthStorage.clearSession();
      emit(const AuthStateUnauthenticated());
      debugPrint('✅ AuthBloc: Sign out successful');
    } catch (e) {
      debugPrint('❌ AuthBloc: Sign out failed: $e');
      emit(const AuthStateUnauthenticated());
    }
  }
  
  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.resetPasswordForEmail(event.email);
      debugPrint('✅ AuthBloc: Password reset email sent: ${event.email}');
    } catch (e) {
      debugPrint('❌ AuthBloc: Password reset failed: $e');
      emit(AuthStateError(_getErrorMessage(e)));
    }
  }
  
  /// Handle error cleared request
  void _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthStateError) {
      emit(const AuthStateUnauthenticated());
    }
  }  
  /// Handle guest data migration after authentication
  Future<void> _onGuestDataMigrationRequested(
    AuthGuestDataMigrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      debugPrint('🔄 AuthBloc: Starting guest data migration for user: ${event.userId}');
      
      // Emit migrating state
      emit(AuthStateMigrating(event.userId));
      
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        await _migrateAllGuestContent(event.userId);
        await WorkingSecureAuthStorage.clearGuestData();
        _triggerDataMigrationCallbacks(event.userId);
      }
      
      // Return to authenticated state
      final session = _supabase?.auth.currentSession;
      if (session?.user != null) {
        emit(AuthStateAuthenticated(session!.user));
      }
    } catch (e) {
      debugPrint('❌ AuthBloc: Guest data migration failed: $e');
      // Return to authenticated state even if migration fails
      final session = _supabase?.auth.currentSession;
      if (session?.user != null) {
        emit(AuthStateAuthenticated(session!.user));
      }
    }
  }
  
  /// Trigger data migration callbacks
  void _triggerDataMigrationCallbacks(String userId) {
    debugPrint('🔔 AuthBloc: Notifying ${_onUserDataMigrated.length} services...');
    
    for (int i = 0; i < _onUserDataMigrated.length; i++) {
      try {
        _onUserDataMigrated[i](userId);
        debugPrint('✅ Service callback ${i + 1} completed');
      } catch (e) {
        debugPrint('❌ Service callback ${i + 1} failed: $e');
      }
    }
  }
  
  /// Migrate guest content (simplified version)
  Future<void> _migrateAllGuestContent(String userId) async {
    try {
      final guestFlashcards = StorageService.getFlashcardSets();
      
      if (guestFlashcards != null && guestFlashcards.isNotEmpty) {
        final convertedFlashcards = EnhancedSafeMapConverter.convertHiveData(guestFlashcards);
        
        final migrationPayload = {
          'flashcards': convertedFlashcards,
          'migrated_at': DateTime.now().toIso8601String(),
          'migration_source': 'guest_session',
        };
        
        await _backupGuestDataForUser(userId, migrationPayload);
        await _markDataAsMigrated(userId);
      }
    } catch (e) {
      debugPrint('❌ AuthBloc: Guest content migration failed: $e');
    }
  }
  
  /// Backup guest data
  Future<void> _backupGuestDataForUser(String userId, Map<String, dynamic> guestData) async {
    final prefs = await SharedPreferences.getInstance();
    final backupKey = 'user_migrated_data_$userId';
    final jsonString = jsonEncode(guestData);
    await prefs.setString(backupKey, jsonString);
    await prefs.setBool('user_has_migrated_data_$userId', true);
    debugPrint('✅ AuthBloc: Guest data backed up for user: $userId');
  }
  
  /// Mark data as migrated
  Future<void> _markDataAsMigrated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_migrated_for_user_$userId', true);
    await prefs.setString('last_migration_date_$userId', DateTime.now().toIso8601String());
  }
  
  /// Get user-friendly error message
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
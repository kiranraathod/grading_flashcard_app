import 'package:equatable/equatable.dart';

/// Base class for all authentication events
/// 
/// AuthBloc replaces Riverpod authentication system for Phase 2
/// of the FlashMaster migration to eliminate state management conflicts
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

/// Initialize authentication system and check for existing sessions
/// 
/// Triggered on app startup to restore authentication state
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
  
  @override
  String toString() => 'AuthInitialized()';
}

/// Sign in with email and password
/// 
/// Standard email authentication flow
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
  
  @override
  String toString() => 'AuthSignInRequested(email: $email)';
}

/// Sign up with email and password
/// 
/// Creates new user account with email verification if required
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthSignUpRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
  
  @override
  String toString() => 'AuthSignUpRequested(email: $email)';
}

/// Sign in with Google OAuth
/// 
/// Handles Google authentication flow
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
  
  @override
  String toString() => 'AuthSignInWithGoogleRequested()';
}

/// Sign in anonymously as guest user
/// 
/// Creates temporary anonymous session for demo usage
class AuthSignInAnonymouslyRequested extends AuthEvent {
  const AuthSignInAnonymouslyRequested();
  
  @override
  String toString() => 'AuthSignInAnonymouslyRequested()';
}

/// Sign in with demo mode
/// 
/// Creates local demo session for testing without authentication
class AuthSignInDemoRequested extends AuthEvent {
  const AuthSignInDemoRequested();
  
  @override
  String toString() => 'AuthSignInDemoRequested()';
}

/// Sign out current user
/// 
/// Clears session and returns to unauthenticated state
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
  
  @override
  String toString() => 'AuthSignOutRequested()';
}

/// Request password reset for given email
/// 
/// Sends password reset email through Supabase
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  
  const AuthPasswordResetRequested({
    required this.email,
  });
  
  @override
  List<Object?> get props => [email];
  
  @override
  String toString() => 'AuthPasswordResetRequested(email: $email)';
}

/// Clear authentication error state
/// 
/// Resets error state to allow retry of authentication
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
  
  @override
  String toString() => 'AuthErrorCleared()';
}

/// Handle external authentication state changes
/// 
/// Triggered by Supabase auth state listener for session changes
class AuthStateChangeDetected extends AuthEvent {
  final String eventType;
  final dynamic session;
  
  const AuthStateChangeDetected({
    required this.eventType,
    this.session,
  });
  
  @override
  List<Object?> get props => [eventType, session];
  
  @override
  String toString() => 'AuthStateChangeDetected(eventType: $eventType)';
}

/// Trigger guest data migration after authentication
/// 
/// Migrates local guest data to authenticated user context
class AuthGuestDataMigrationRequested extends AuthEvent {
  final String userId;
  
  const AuthGuestDataMigrationRequested({
    required this.userId,
  });
  
  @override
  List<Object?> get props => [userId];
  
  @override
  String toString() => 'AuthGuestDataMigrationRequested(userId: $userId)';
}
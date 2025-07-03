import 'package:equatable/equatable.dart';

/// Base class for all authentication states
/// 
/// AuthBloc replaces SimpleAuthState from Riverpod system
/// Provides unified authentication state for entire app
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when authentication system is starting up
/// 
/// Used during app launch while checking for existing sessions
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
  
  @override
  String toString() => 'AuthStateInitial()';
}

/// Loading state during authentication operations
/// 
/// Shown during sign in, sign up, and other auth operations
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
  
  @override
  String toString() => 'AuthStateLoading()';
}

/// User is not authenticated
/// 
/// Default state when no valid session exists
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
  
  @override
  String toString() => 'AuthStateUnauthenticated()';
}

/// User is authenticated with full account
/// 
/// Contains user data and enables full app functionality
class AuthStateAuthenticated extends AuthState {
  final dynamic user; // Compatible with existing codebase user type
  
  const AuthStateAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
  
  @override
  String toString() => 'AuthStateAuthenticated(user: ${user?.id ?? "unknown"})';
}

/// User is signed in as guest/anonymous
/// 
/// Limited functionality with anonymous session
class AuthStateGuest extends AuthState {
  final String guestId;
  
  const AuthStateGuest(this.guestId);
  
  @override
  List<Object?> get props => [guestId];
  
  @override
  String toString() => 'AuthStateGuest(guestId: $guestId)';
}

/// Email verification required
/// 
/// User signed up but needs to verify email before full access
class AuthStateEmailVerificationRequired extends AuthState {
  const AuthStateEmailVerificationRequired();
  
  @override
  String toString() => 'AuthStateEmailVerificationRequired()';
}

/// Authentication error occurred
/// 
/// Contains error message for user display
class AuthStateError extends AuthState {
  final String message;
  
  const AuthStateError(this.message);
  
  @override
  List<Object?> get props => [message];
  
  @override
  String toString() => 'AuthStateError(message: $message)';
}

/// Guest data migration in progress
/// 
/// Temporary state during data migration after authentication
class AuthStateMigrating extends AuthState {
  final String userId;
  
  const AuthStateMigrating(this.userId);
  
  @override
  List<Object?> get props => [userId];
  
  @override
  String toString() => 'AuthStateMigrating(userId: $userId)';
}

/// Helper extensions for AuthState checking
extension AuthStateCheckers on AuthState {
  /// Check if user is authenticated (full account or guest)
  bool get isAuthenticated => 
      this is AuthStateAuthenticated || this is AuthStateGuest;
  
  /// Check if user has full authenticated account
  bool get isFullyAuthenticated => this is AuthStateAuthenticated;
  
  /// Check if user is guest
  bool get isGuest => this is AuthStateGuest;
  
  /// Check if in loading state
  bool get isLoading => this is AuthStateLoading;
  
  /// Check if in error state
  bool get hasError => this is AuthStateError;
  
  /// Get current user if authenticated
  dynamic get currentUser {
    if (this is AuthStateAuthenticated) {
      return (this as AuthStateAuthenticated).user;
    }
    return null;
  }
  
  /// Get current user ID (works for both authenticated and guest)
  String? get currentUserId {
    if (this is AuthStateAuthenticated) {
      return (this as AuthStateAuthenticated).user?.id;
    } else if (this is AuthStateGuest) {
      return (this as AuthStateGuest).guestId;
    }
    return null;
  }
}
/// Simple authentication state without freezed code generation
abstract class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final dynamic user; // Using dynamic to avoid import conflicts
  const AuthStateAuthenticated(this.user);
}

class AuthStateGuest extends AuthState {
  final String guestId;
  const AuthStateGuest(this.guestId);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}

class AuthStateEmailVerificationRequired extends AuthState {
  const AuthStateEmailVerificationRequired();
}

/// User action tracking state
class UserActionState {
  final Map<String, int> actionCounts;
  final Map<String, int> dailyLimits;
  final DateTime lastReset;
  final bool hasReachedLimit;

  const UserActionState({
    required this.actionCounts,
    required this.dailyLimits,
    required this.lastReset,
    this.hasReachedLimit = false,
  });

  UserActionState copyWith({
    Map<String, int>? actionCounts,
    Map<String, int>? dailyLimits,
    DateTime? lastReset,
    bool? hasReachedLimit,
  }) {
    return UserActionState(
      actionCounts: actionCounts ?? this.actionCounts,
      dailyLimits: dailyLimits ?? this.dailyLimits,
      lastReset: lastReset ?? this.lastReset,
      hasReachedLimit: hasReachedLimit ?? this.hasReachedLimit,
    );
  }
}

/// Unified action types across all features
enum ActionType {
  flashcardGrading,
  interviewPractice,
  contentGeneration,
  aiAssistance,
}

/// User permission levels
enum UserPermissionLevel {
  guest,
  authenticated,
  premium,
}

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

/// Enhanced usage status for UI display
class UsageStatus {
  final int totalUsage;
  final int totalLimit;
  final int remainingActions;
  final bool isAuthenticated;
  final String resetTime;
  final int progressPercentage;
  final bool canPerformActions;
  final String statusMessage;

  const UsageStatus({
    required this.totalUsage,
    required this.totalLimit,
    required this.remainingActions,
    required this.isAuthenticated,
    required this.resetTime,
    required this.progressPercentage,
    required this.canPerformActions,
    required this.statusMessage,
  });

  /// Get color for progress indicator based on usage
  String get progressColor {
    if (progressPercentage <= 50) return 'green';
    if (progressPercentage <= 80) return 'orange';
    return 'red';
  }

  /// Check if user should be warned about approaching limit
  bool get shouldShowWarning => remainingActions <= 2 && remainingActions > 0;

  /// Get encouragement message for authentication
  String get authEncouragement {
    if (isAuthenticated) return '';
    if (remainingActions <= 1) return 'Sign in to get 5 daily actions!';
    if (remainingActions <= 2) return 'Sign in for more actions!';
    return '';
  }
}

/// Result of recording an action with enhanced feedback
class ActionResult {
  final bool success;
  final String? errorMessage;
  final int? remainingActions;
  final String? warningMessage;
  final int? currentUsage;
  final int? limit;
  final String? resetTime;

  const ActionResult._({
    required this.success,
    this.errorMessage,
    this.remainingActions,
    this.warningMessage,
    this.currentUsage,
    this.limit,
    this.resetTime,
  });

  /// Create a successful result
  factory ActionResult.success({
    int? remainingActions,
    String? warningMessage,
  }) {
    return ActionResult._(
      success: true,
      remainingActions: remainingActions,
      warningMessage: warningMessage,
    );
  }

  /// Create a limit reached result
  factory ActionResult.limitReached({
    required int currentUsage,
    required int limit,
    required String resetTime,
  }) {
    return ActionResult._(
      success: false,
      currentUsage: currentUsage,
      limit: limit,
      resetTime: resetTime,
      errorMessage: 'Daily limit reached',
    );
  }

  /// Create an error result
  factory ActionResult.error(String message) {
    return ActionResult._(
      success: false,
      errorMessage: message,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_auth_provider.dart';
import '../services/working_secure_auth_storage.dart';
import '../utils/config.dart';

/// Reactive action tracking provider that responds to authentication changes
class SimpleActionTracker extends StateNotifier<UserActionState> {
  final Ref ref;
  
  SimpleActionTracker(this.ref) : super(UserActionState(
    actionCounts: const {},
    dailyLimits: const {},
    lastReset: DateTime(2000),
  )) {
    _initializeTracking();
    _listenToAuthChanges(); // 🆕 Add auth state listener
  }

  /// 🆕 Listen to authentication state changes and react accordingly
  void _listenToAuthChanges() {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
      debugPrint('🔄 Action tracker: Auth state changed from ${previous?.runtimeType} to ${next.runtimeType}');
      
      // Handle authentication transition
      if (previous is! AuthStateAuthenticated && next is AuthStateAuthenticated) {
        debugPrint('✨ User authenticated - refreshing action limits and counts');
        await _handleUserAuthenticated(next);
      } 
      // Handle logout transition
      else if (previous is AuthStateAuthenticated && next is! AuthStateAuthenticated) {
        debugPrint('👋 User logged out - resetting to guest limits');
        await _handleUserLoggedOut();
      }
      // Handle any other auth state change
      else if (previous != null && _getUserId(previous) != _getUserId(next)) {
        debugPrint('🔄 User changed - reloading action data');
        await _reloadActionData();
      }
    });
  }

  /// 🆕 Handle user authentication - refresh limits and optionally reset counts
  Future<void> _handleUserAuthenticated(AuthStateAuthenticated authState) async {
    try {
      final userId = _getUserId(authState);
      if (userId == null) return;

      // Update daily limits to authenticated limits
      final newLimits = _getDailyLimits();
      
      // Option 1: Reset counts to give fresh authenticated quota
      // This gives user their full authenticated limit immediately
      final resetCounts = <String, int>{};
      
      // Option 2: Keep existing counts but update limits
      // Uncomment this if you want to preserve existing action counts:
      // final existingActions = await WorkingSecureAuthStorage.getUserActions(userId);
      // final resetCounts = existingActions;
      
      state = state.copyWith(
        actionCounts: resetCounts,
        dailyLimits: newLimits,
        lastReset: DateTime.now(),
        hasReachedLimit: _checkIfLimitReached(resetCounts, newLimits),
      );
      
      // Store the reset counts
      await WorkingSecureAuthStorage.storeUserActions(userId, resetCounts);
      
      debugPrint('🎉 Authenticated user limits applied:');
      debugPrint('   - Flashcard grading: ${resetCounts['flashcard_grading'] ?? 0}/${newLimits['flashcard_grading']}');
      debugPrint('   - Interview practice: ${resetCounts['interview_practice'] ?? 0}/${newLimits['interview_practice']}');
      
    } catch (e) {
      debugPrint('❌ Failed to handle user authentication: $e');
    }
  }

  /// 🆕 Handle user logout - reset to guest limits
  Future<void> _handleUserLoggedOut() async {
    try {
      // Reset to guest limits and clear actions
      final guestLimits = _getDailyLimits();
      
      state = state.copyWith(
        actionCounts: {},
        dailyLimits: guestLimits,
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      
      debugPrint('👋 Reset to guest limits');
    } catch (e) {
      debugPrint('❌ Failed to handle user logout: $e');
    }
  }

  /// 🆕 Reload action data when user changes
  Future<void> _reloadActionData() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      if (userId != null) {
        await _loadUserActions(userId);
        await _checkDailyReset();
      } else {
        // 🆕 Handle guest users - set up guest limits without storage
        state = state.copyWith(
          actionCounts: {},
          dailyLimits: _getDailyLimits(),
          lastReset: DateTime.now(),
          hasReachedLimit: false,
        );
        debugPrint('✅ Guest user action data reloaded');
      }
    } catch (e) {
      debugPrint('❌ Failed to reload action data: $e');
    }
  }

  Future<void> _initializeTracking() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      if (userId != null) {
        await _loadUserActions(userId);
        await _checkDailyReset();
      } else {
        // 🆕 Initialize guest user tracking even without userId
        debugPrint('🎯 Initializing guest user tracking');
        state = state.copyWith(
          actionCounts: {},
          dailyLimits: _getDailyLimits(), // Set up guest limits
          lastReset: DateTime.now(),
          hasReachedLimit: false,
        );
        debugPrint('✅ Guest user tracking initialized with limits: ${state.dailyLimits}');
      }
      
      debugPrint('✅ Action tracking initialized');
    } catch (e) {
      debugPrint('❌ Action tracking initialization failed: $e');
      // 🆕 Fallback: Set up basic guest tracking even if initialization fails
      try {
        state = state.copyWith(
          actionCounts: {},
          dailyLimits: _getDailyLimits(),
          lastReset: DateTime.now(),
          hasReachedLimit: false,
        );
        debugPrint('✅ Fallback guest tracking initialized');
      } catch (fallbackError) {
        debugPrint('❌ Fallback initialization also failed: $fallbackError');
      }
    }
  }

  String? _getUserId(AuthState authState) {
    if (authState is AuthStateAuthenticated) {
      final user = authState.user;
      if (user is Map<String, dynamic>) {
        return user['id']?.toString();
      }
      // Handle Supabase User object
      try {
        return (user as dynamic).id;
      } catch (e) {
        return null;
      }
    } else if (authState is AuthStateGuest) {
      return authState.guestId;
    }
    return null;
  }

  Future<void> _loadUserActions(String userId) async {
    try {
      final actions = await WorkingSecureAuthStorage.getUserActions(userId);
      final now = DateTime.now();
      
      state = state.copyWith(
        actionCounts: actions,
        dailyLimits: _getDailyLimits(),
        lastReset: now,
      );
      
      debugPrint('📊 Loaded actions for user $userId: $actions');
    } catch (e) {
      debugPrint('❌ Failed to load user actions: $e');
    }
  }

  Map<String, int> _getDailyLimits() {
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;

    if (isAuthenticated) {
      return {
        'flashcard_grading': AuthConfig.authenticatedMaxGradingActions,
        'interview_practice': AuthConfig.authenticatedMaxInterviewActions,
        'content_generation': AuthConfig.authenticatedMaxContentGeneration,
        'ai_assistance': AuthConfig.authenticatedMaxAiAssistance,
      };
    } else {
      return {
        'flashcard_grading': AuthConfig.guestMaxGradingActions,
        'interview_practice': AuthConfig.guestMaxInterviewActions,
        'content_generation': AuthConfig.guestMaxContentGeneration,
        'ai_assistance': AuthConfig.guestMaxAiAssistance,
      };
    }
  }
  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final lastReset = state.lastReset;
    
    if (now.day != lastReset.day || 
        now.month != lastReset.month || 
        now.year != lastReset.year) {
      
      debugPrint('🔄 Daily reset triggered');
      await _resetDailyActions();
    }
  }

  Future<void> _resetDailyActions() async {
    final authState = ref.read(authNotifierProvider);
    final userId = _getUserId(authState);
    
    // 🆕 Always reset state, regardless of userId
    state = state.copyWith(
      actionCounts: {},
      lastReset: DateTime.now(),
      hasReachedLimit: false,
    );
    
    // 🆕 Only try to store if we have a userId (authenticated users)
    if (userId != null) {
      try {
        await WorkingSecureAuthStorage.storeUserActions(userId, {});
        debugPrint('✅ Daily actions reset and stored for user $userId');
      } catch (e) {
        debugPrint('⚠️ Failed to store reset actions for user $userId: $e');
      }
    } else {
      debugPrint('✅ Daily actions reset for guest user (no storage)');
    }
  }

  Future<bool> recordAction(ActionType actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!AuthConfig.enableUsageLimits) {
      debugPrint('💡 Usage limits disabled - allowing action');
      return true;
    }

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      // 🆕 Don't require userId for guest users - they can still use in-memory tracking
      await _checkDailyReset();
      
      final actionKey = _getActionKey(actionType);
      final currentCount = state.actionCounts[actionKey] ?? 0;
      final limit = state.dailyLimits[actionKey] ?? 0;
      
      if (currentCount >= limit) {
        debugPrint('🚫 Action blocked - limit exceeded: $currentCount/$limit');
        state = state.copyWith(hasReachedLimit: true);
        return false;
      }

      final newCounts = Map<String, int>.from(state.actionCounts);
      newCounts[actionKey] = currentCount + 1;
      
      state = state.copyWith(
        actionCounts: newCounts,
        hasReachedLimit: _checkIfLimitReached(newCounts, state.dailyLimits),
      );
      
      // 🆕 Only try to store if we have a userId (authenticated users)
      if (userId != null) {
        try {
          await WorkingSecureAuthStorage.storeUserActions(userId, newCounts);
          debugPrint('📊 Action recorded and stored: $actionKey (${newCounts[actionKey]}/$limit)');
        } catch (e) {
          debugPrint('⚠️ Failed to store action for user $userId: $e');
        }
      } else {
        debugPrint('📊 Action recorded (guest): $actionKey (${newCounts[actionKey]}/$limit)');
      }
      
      if (newCounts[actionKey] == limit - 1) {
        debugPrint('⚠️ Approaching limit: 1 action remaining');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to record action: $e');
      return true; // Fail open to not block user
    }
  }

  bool canPerformAction(ActionType actionType) {
    if (!AuthConfig.enableUsageLimits) {
      debugPrint('💡 Usage limits disabled - allowing action');
      return true;
    }
    
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    
    final canPerform = currentCount < limit;
    
    // 🆕 Enhanced debugging
    debugPrint('🔍 canPerformAction($actionType):');
    debugPrint('  - actionKey: $actionKey');
    debugPrint('  - currentCount: $currentCount');
    debugPrint('  - limit: $limit');
    debugPrint('  - canPerform: $canPerform');
    debugPrint('  - state.dailyLimits: ${state.dailyLimits}');
    debugPrint('  - state.actionCounts: ${state.actionCounts}');
    
    if (!canPerform) {
      debugPrint('🚫 Action check failed: $actionKey ($currentCount/$limit)');
    }
    
    return canPerform;
  }

  int getRemainingActions(ActionType actionType) {
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    
    return (limit - currentCount).clamp(0, limit);
  }

  String _getActionKey(ActionType actionType) {
    switch (actionType) {
      case ActionType.flashcardGrading:
        return 'flashcard_grading';
      case ActionType.interviewPractice:
        return 'interview_practice';
      case ActionType.contentGeneration:
        return 'content_generation';
      case ActionType.aiAssistance:
        return 'ai_assistance';
    }
  }

  /// 🔧 Updated to accept custom limits parameter
  bool _checkIfLimitReached(Map<String, int> counts, Map<String, int> limits) {
    for (final entry in counts.entries) {
      final limit = limits[entry.key] ?? 0;
      if (entry.value >= limit) {
        return true;
      }
    }
    return false;
  }

  String getUsageMessage(ActionType actionType) {
    if (!AuthConfig.enableUsageLimits) return '';
    
    final remaining = getRemainingActions(actionType);
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    
    if (remaining <= 0) {
      return isAuthenticated 
        ? 'Daily limit reached. Resets at midnight.'
        : 'Guest limit reached. Sign in for more actions.';
    } else if (remaining == 1) {
      return '$remaining action remaining today';
    } else {
      return '$remaining actions remaining today';
    }
  }

  /// Debug method to reset all action counts (for testing purposes)
  Future<void> resetActions() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      if (userId != null) {
        // Reset all action counts to zero
        state = state.copyWith(
          actionCounts: {},
          lastReset: DateTime.now(),
          hasReachedLimit: false,
        );
        
        // Store the reset counts
        await WorkingSecureAuthStorage.storeUserActions(userId, {});
        
        debugPrint('🔄 Debug: All action counts reset to zero');
      }
    } catch (e) {
      debugPrint('❌ Failed to reset actions: $e');
    }
  }
}

// Provider instances
final actionTrackerProvider = StateNotifierProvider<SimpleActionTracker, UserActionState>((ref) {
  return SimpleActionTracker(ref);
});

final canPerformFlashcardGradingProvider = Provider<bool>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.canPerformAction(ActionType.flashcardGrading);
});

final canPerformInterviewPracticeProvider = Provider<bool>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.canPerformAction(ActionType.interviewPractice);
});

final remainingFlashcardActionsProvider = Provider<int>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.getRemainingActions(ActionType.flashcardGrading);
});

final remainingInterviewActionsProvider = Provider<int>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.getRemainingActions(ActionType.interviewPractice);
});

final flashcardUsageMessageProvider = Provider<String>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.getUsageMessage(ActionType.flashcardGrading);
});

final interviewUsageMessageProvider = Provider<String>((ref) {
  final tracker = ref.watch(actionTrackerProvider.notifier);
  return tracker.getUsageMessage(ActionType.interviewPractice);
});

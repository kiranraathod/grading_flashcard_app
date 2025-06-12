import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_auth_provider.dart';
import '../services/working_secure_auth_storage.dart';
import '../utils/config.dart';

/// Simple action tracking provider
class SimpleActionTracker extends StateNotifier<UserActionState> {
  final Ref ref;
  
  SimpleActionTracker(this.ref) : super(UserActionState(
    actionCounts: const {},
    dailyLimits: const {},
    lastReset: DateTime(2000),
  )) {
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      if (userId != null) {
        await _loadUserActions(userId);
        await _checkDailyReset();
      }
      
      debugPrint('✅ Action tracking initialized');
    } catch (e) {
      debugPrint('❌ Action tracking initialization failed: $e');
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
    
    if (userId != null) {
      state = state.copyWith(
        actionCounts: {},
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      
      await WorkingSecureAuthStorage.storeUserActions(userId, {});
      debugPrint('✅ Daily actions reset');
    }
  }  Future<bool> recordAction(ActionType actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!AuthConfig.enableUsageLimits) {
      debugPrint('💡 Usage limits disabled - allowing action');
      return true;
    }

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState);
      
      if (userId == null) {
        debugPrint('❌ No user ID available for action recording');
        return false;
      }

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
        hasReachedLimit: _checkIfLimitReached(newCounts),
      );
      
      await WorkingSecureAuthStorage.storeUserActions(userId, newCounts);
      
      debugPrint('📊 Action recorded: $actionKey (${newCounts[actionKey]}/$limit)');
      
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
    if (!AuthConfig.enableUsageLimits) return true;
    
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    
    final canPerform = currentCount < limit;
    
    if (!canPerform) {
      debugPrint('🔍 Action check failed: $actionKey ($currentCount/$limit)');
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

  bool _checkIfLimitReached(Map<String, int> counts) {
    for (final entry in counts.entries) {
      final limit = state.dailyLimits[entry.key] ?? 0;
      if (entry.value >= limit) {
        return true;
      }
    }
    return false;
  }

  String getUsageMessage(ActionType actionType) {
    if (!AuthConfig.enableUsageLimits) return '';
    
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    final remaining = limit - currentCount;
    
    if (isAuthenticated) {
      return 'Actions used: $currentCount/$limit';
    }
    
    if (remaining <= 0) {
      return 'Daily limit reached. Sign in for more actions!';
    } else if (remaining <= 1) {
      return '$remaining action remaining. Sign in for more!';
    } else {
      return '$remaining actions remaining today';
    }
  }

  Future<void> resetActions() async {
    final authState = ref.read(authNotifierProvider);
    final userId = _getUserId(authState);
    
    if (userId != null) {
      state = state.copyWith(
        actionCounts: {},
        hasReachedLimit: false,
      );
      
      await WorkingSecureAuthStorage.storeUserActions(userId, {});
      debugPrint('🔄 Actions reset for testing');
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

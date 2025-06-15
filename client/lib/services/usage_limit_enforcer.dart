import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_action_tracking_provider.dart';
import '../providers/working_auth_provider.dart';
import '../utils/config.dart';
import '../widgets/auth/authentication_modal.dart';

/// Centralized usage limit enforcer that manages shared quotas across all features
class UsageLimitEnforcer {
  final Ref ref;
  
  UsageLimitEnforcer(this.ref);

  /// 🎯 MAIN METHOD: Enforce usage limits with authentication trigger
  /// Returns true if action can proceed, false if blocked
  Future<bool> enforceLimit(
    ActionType actionType, {
    BuildContext? context,
    String? source,
  }) async {
    if (!AuthConfig.enableUsageLimits) {
      debugPrint('💡 Usage limits disabled - allowing action');
      return true;
    }

    final authState = ref.read(authNotifierProvider);
    
    // Get combined usage count across all action types
    final totalUsageCount = _getTotalUsageCount();
    final maxActions = _getMaxActionsForUser(authState);
    
    debugPrint('🔍 UsageLimitEnforcer.enforceLimit($actionType):');
    debugPrint('  - source: ${source ?? "unknown"}');
    debugPrint('  - totalUsageCount: $totalUsageCount');
    debugPrint('  - maxActions: $maxActions');
    debugPrint('  - authenticated: ${authState is AuthStateAuthenticated}');
    
    // Check if user has exceeded the COMBINED limit
    if (totalUsageCount >= maxActions) {
      debugPrint('🚫 COMBINED usage limit exceeded: $totalUsageCount/$maxActions');
      
      // Trigger authentication modal if context is available
      if (context != null) {
        debugPrint('🔓 Showing authentication modal for usage limit exceeded');
        await _triggerAuthenticationModal(context);
        
        // After authentication modal closes, re-check the quota
        debugPrint('🔄 Authentication modal closed, re-checking quota...');
        
        // Small delay to ensure state updates propagate
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Get updated auth state and recalculate limits
        final updatedAuthState = ref.read(authNotifierProvider);
        final updatedTotalUsage = _getTotalUsageCount();
        final updatedMaxActions = _getMaxActionsForUser(updatedAuthState);
        
        debugPrint('🔍 Updated quota check:');
        debugPrint('  - totalUsage: $updatedTotalUsage');
        debugPrint('  - maxActions: $updatedMaxActions');
        debugPrint('  - authenticated: ${updatedAuthState is AuthStateAuthenticated}');
        
        if (updatedTotalUsage < updatedMaxActions) {
          debugPrint('✅ Authentication successful - user can now proceed');
          return true;
        } else {
          debugPrint('❌ User still cannot perform action after authentication');
          return false;
        }
      }
      
      return false;
    }
    
    debugPrint('✅ Usage limit check passed: $totalUsageCount/$maxActions');
    return true;
  }

  /// 🎯 ATOMIC ACTION: Check limit and consume quota in one operation
  Future<bool> executeAction(
    ActionType actionType, {
    BuildContext? context,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if action is allowed
    final canProceed = await enforceLimit(
      actionType,
      context: context,
      source: source,
    );
    
    if (!canProceed) {
      return false;
    }
    
    // Consume the quota atomically
    final actionTracker = ref.read(actionTrackerProvider.notifier);
    final success = await actionTracker.recordAction(actionType, metadata: metadata);
    
    if (success) {
      final newTotalCount = _getTotalUsageCount();
      debugPrint('📊 Action consumed: $actionType (total: $newTotalCount)');
    } else {
      debugPrint('❌ Failed to record action: $actionType');
    }
    
    return success;
  }

  /// Get combined usage count across all action types
  int _getTotalUsageCount() {
    final actionState = ref.read(actionTrackerProvider);
    final actionCounts = actionState.actionCounts;
    
    // Sum all action counts for combined limit checking
    int totalCount = 0;
    for (final actionType in ActionType.values) {
      final actionKey = _getActionKey(actionType);
      final count = actionCounts[actionKey] ?? 0;
      totalCount += count;
    }
    
    return totalCount;
  }

  /// Get maximum actions allowed for current user
  int _getMaxActionsForUser(AuthState authState) {
    if (authState is AuthStateAuthenticated) {
      // For authenticated users, use higher combined limit
      return AuthConfig.authenticatedMaxGradingActions; // 5 total actions
    } else {
      // For guest users, use lower combined limit
      return AuthConfig.guestMaxGradingActions; // 3 total actions
    }
  }

  /// Get remaining actions for current user
  int getRemainingActions() {
    final authState = ref.read(authNotifierProvider);
    final totalUsed = _getTotalUsageCount();
    final maxActions = _getMaxActionsForUser(authState);
    
    return (maxActions - totalUsed).clamp(0, maxActions);
  }

  /// Check if user can perform any action without consuming quota
  bool canPerformAnyAction() {
    final authState = ref.read(authNotifierProvider);
    final totalUsed = _getTotalUsageCount();
    final maxActions = _getMaxActionsForUser(authState);
    
    return totalUsed < maxActions;
  }

  /// Trigger authentication modal and wait for completion
  Future<void> _triggerAuthenticationModal(BuildContext context) async {
    try {
      debugPrint('🔓 Triggering authentication modal from UsageLimitEnforcer');
      
      // Get current auth state before modal
      final authStateBefore = ref.read(authNotifierProvider);
      debugPrint('🔍 Auth state before modal: ${authStateBefore.runtimeType}');
      
      await AuthenticationModal.show(context);
      
      // Get auth state after modal
      final authStateAfter = ref.read(authNotifierProvider);
      debugPrint('🔍 Auth state after modal: ${authStateAfter.runtimeType}');
      debugPrint('✅ Authentication modal completed');
      
      // Log usage summary after authentication
      final usageSummary = getUsageSummary();
      debugPrint('📊 Post-authentication usage summary: $usageSummary');
      
    } catch (e) {
      debugPrint('❌ Error showing authentication modal: $e');
    }
  }

  /// Helper method to get action key (matches SimpleActionTracker logic)
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

  /// Get usage summary for debugging
  Map<String, dynamic> getUsageSummary() {
    final authState = ref.read(authNotifierProvider);
    final actionState = ref.read(actionTrackerProvider);
    final totalUsed = _getTotalUsageCount();
    final maxActions = _getMaxActionsForUser(authState);
    
    return {
      'totalUsed': totalUsed,
      'maxActions': maxActions,
      'remaining': getRemainingActions(),
      'canPerform': canPerformAnyAction(),
      'authenticated': authState is AuthStateAuthenticated,
      'actionCounts': actionState.actionCounts,
      'dailyLimits': actionState.dailyLimits,
    };
  }
}

/// Provider for the usage limit enforcer
final usageLimitEnforcerProvider = Provider<UsageLimitEnforcer>((ref) {
  return UsageLimitEnforcer(ref);
});

/// Convenience provider for checking if user can perform actions
final canPerformActionProvider = Provider<bool>((ref) {
  final enforcer = ref.watch(usageLimitEnforcerProvider);
  return enforcer.canPerformAnyAction();
});

/// Provider for remaining actions count
final remainingActionsProvider = Provider<int>((ref) {
  final enforcer = ref.watch(usageLimitEnforcerProvider);
  return enforcer.getRemainingActions();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/unified_action_tracking_provider.dart';
import '../providers/working_auth_provider.dart';
import '../utils/config.dart';
import '../widgets/auth/authentication_modal.dart';

/// 🔄 REFACTORED: Unified usage limit enforcer using consolidated storage
/// 
/// This now uses the UnifiedActionTracker instead of fragmented systems.
/// Provides cleaner, more reliable limit enforcement with single source of truth.
class UnifiedUsageLimitEnforcer {
  final Ref ref;
  
  UnifiedUsageLimitEnforcer(this.ref);

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
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    
    // 🎯 FIX: Check COMBINED total usage instead of individual action type limits
    final totalUsage = tracker.getTotalUsage();
    final totalLimit = tracker.getTotalLimit();
    final canPerformAny = totalUsage < totalLimit;
    
    // Also get individual action data for debugging
    final remaining = tracker.getRemainingActions(actionType);
    
    debugPrint('🔍 UnifiedUsageLimitEnforcer.enforceLimit($actionType):');
    debugPrint('  - source: ${source ?? "unknown"}');
    debugPrint('  - COMBINED check: $totalUsage/$totalLimit (canPerform: $canPerformAny)');
    debugPrint('  - individual remaining: $remaining');
    debugPrint('  - authenticated: ${authState is AuthStateAuthenticated}');
    
    // 🎯 FIX: Check combined quota instead of individual action type
    if (!canPerformAny) {
      debugPrint('🚫 COMBINED usage limit exceeded: $totalUsage/$totalLimit');
      
      // 🎯 NEW FIX: Only show auth modal for guest users, not authenticated users
      final isAuthenticated = authState is AuthStateAuthenticated;
      
      if (!isAuthenticated && context != null) {
        // Guest user reached limit - show authentication modal to get more actions
        debugPrint('🔓 Guest user limit exceeded - showing authentication modal');
        await _triggerAuthenticationModal(context);
        
        // After authentication modal closes, re-check the quota
        debugPrint('🔄 Authentication modal closed, re-checking quota...');
        
        // Small delay to ensure state updates propagate
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Get updated state and recalculate COMBINED quota
        final updatedAuthState = ref.read(authNotifierProvider);
        final updatedTotalUsage = tracker.getTotalUsage();
        final updatedTotalLimit = tracker.getTotalLimit();
        final updatedCanPerform = updatedTotalUsage < updatedTotalLimit;
        
        debugPrint('🔍 Updated quota check:');
        debugPrint('  - COMBINED: $updatedTotalUsage/$updatedTotalLimit (canPerform: $updatedCanPerform)');
        debugPrint('  - authenticated: ${updatedAuthState is AuthStateAuthenticated}');
        
        if (updatedCanPerform) {
          debugPrint('✅ Authentication successful - user can now proceed');
          return true;
        } else {
          debugPrint('❌ User still cannot perform action after authentication');
          debugPrint('🚫 Modal was dismissed without authentication - blocking action');
          return false;
        }
      } else {
        // Authenticated user reached limit - show limit reached message, no auth modal
        if (isAuthenticated) {
          debugPrint('🚫 Authenticated user reached daily limit ($totalUsage/$totalLimit) - no auth modal shown');
          debugPrint('💡 User should see "Daily limit reached" message instead');
        } else {
          debugPrint('🚫 Guest user reached limit - no context for auth modal');
        }
        return false;
      }
    }
    
    debugPrint('✅ Usage limit check passed: $remaining remaining for $actionType');
    return true;
  }

  /// 🎯 ATOMIC ACTION: Check limit and consume quota in one operation
  Future<bool> executeAction(
    ActionType actionType, {
    BuildContext? context,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('🔍 ExecuteAction START: $actionType from ${source ?? "unknown"}');
    
    // Check if action is allowed (context may be null to avoid async BuildContext issues)
    final canProceed = await enforceLimit(
      actionType,
      context: context,
      source: source,
    );
    
    debugPrint('🔍 ExecuteAction: enforceLimit returned: $canProceed');
    
    if (!canProceed) {
      debugPrint('🚫 ExecuteAction: Action blocked by enforceLimit - returning false');
      return false;
    }
    
    // Consume the quota atomically with enhanced feedback
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    final result = await tracker.recordAction(actionType, metadata: metadata);
    
    if (result.success) {
      debugPrint('📊 Action consumed: $actionType');
      if (result.remainingActions != null) {
        debugPrint('📊 Remaining actions: ${result.remainingActions}');
      }
      if (result.warningMessage != null) {
        debugPrint('⚠️ Warning: ${result.warningMessage}');
      }
    } else {
      debugPrint('❌ Failed to record action: ${result.errorMessage}');
    }
    
    return result.success;
  }

  /// Get remaining actions for current user across all types
  Map<ActionType, int> getRemainingActionsAll() {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    
    return {
      for (final actionType in ActionType.values)
        actionType: tracker.getRemainingActions(actionType),
    };
  }

  /// Check if user can perform any action without consuming quota
  bool canPerformAnyAction() {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    
    // 🎯 FIX: Check combined usage instead of individual action types
    final totalUsage = tracker.getTotalUsage();
    final totalLimit = tracker.getTotalLimit();
    
    return totalUsage < totalLimit;
  }

  /// Get combined remaining actions (sum across all types)
  int getTotalRemainingActions() {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    final totalLimit = tracker.getTotalLimit();
    final totalUsage = tracker.getTotalUsage();
    
    return (totalLimit - totalUsage).clamp(0, totalLimit);
  }

  /// Trigger authentication modal and wait for completion
  Future<void> _triggerAuthenticationModal(BuildContext context) async {
    try {
      debugPrint('🔓 Triggering authentication modal from UnifiedUsageLimitEnforcer');
      
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

  /// Get comprehensive usage summary for debugging
  Map<String, dynamic> getUsageSummary() {
    final authState = ref.read(authNotifierProvider);
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    final actionState = ref.read(unifiedActionTrackerProvider);
    
    final totalUsage = tracker.getTotalUsage();
    final totalLimit = tracker.getTotalLimit();
    
    return {
      'totalUsage': totalUsage,
      'totalLimit': totalLimit,
      'totalRemaining': getTotalRemainingActions(),
      'canPerformAny': canPerformAnyAction(),
      'authenticated': authState is AuthStateAuthenticated,
      'actionCounts': actionState.actionCounts,
      'dailyLimits': actionState.dailyLimits,
      'lastReset': actionState.lastReset.toIso8601String(),
      'hasReachedLimit': actionState.hasReachedLimit,
      'remainingByType': {
        for (final actionType in ActionType.values)
          actionType.toString(): tracker.getRemainingActions(actionType),
      },
    };
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    final totalRemaining = getTotalRemainingActions();
    
    if (!AuthConfig.enableUsageLimits) {
      return 'Usage limits disabled';
    }
    
    if (totalRemaining <= 0) {
      return isAuthenticated 
        ? 'Daily limit reached. Resets at midnight.'
        : 'Guest limit reached. Sign in for more actions!';
    }
    
    if (isAuthenticated) {
      return '$totalRemaining actions remaining today';
    } else {
      return '$totalRemaining guest actions remaining. Sign in for more!';
    }
  }
}

/// ✅ UPDATED PROVIDER DEFINITIONS
final unifiedUsageLimitEnforcerProvider = Provider<UnifiedUsageLimitEnforcer>((ref) {
  return UnifiedUsageLimitEnforcer(ref);
});

/// Convenience provider for checking if user can perform any action
final canPerformAnyActionProvider = Provider<bool>((ref) {
  final enforcer = ref.watch(unifiedUsageLimitEnforcerProvider);
  return enforcer.canPerformAnyAction();
});

/// Provider for total remaining actions count
final totalRemainingActionsProvider = Provider<int>((ref) {
  final enforcer = ref.watch(unifiedUsageLimitEnforcerProvider);
  return enforcer.getTotalRemainingActions();
});

/// Provider for usage status message
final usageStatusMessageProvider = Provider<String>((ref) {
  final enforcer = ref.watch(unifiedUsageLimitEnforcerProvider);
  return enforcer.getStatusMessage();
});

/// Provider for detailed usage summary (for debug panels)
final usageSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final enforcer = ref.watch(unifiedUsageLimitEnforcerProvider);
  return enforcer.getUsageSummary();
});

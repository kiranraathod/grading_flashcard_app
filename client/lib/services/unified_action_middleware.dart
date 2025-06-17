import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/unified_action_tracking_provider.dart';
import '../services/unified_usage_limit_enforcer.dart';

/// 🔄 REFACTORED: Middleware using unified storage system
/// 
/// Wraps actions with quota enforcement using the consolidated tracking system.
/// Ensures consistent usage limit checking across all features.
class UnifiedActionMiddleware {
  final Ref ref;
  
  UnifiedActionMiddleware(this.ref);

  /// Execute an action with automatic quota enforcement
  /// Returns the result of the action or null if blocked by quota
  Future<T?> executeWithQuota<T>(
    ActionType actionType,
    Future<T> Function() action, {
    BuildContext? context,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    
    debugPrint('🛡️ UnifiedActionMiddleware: Executing $actionType from ${source ?? "unknown"}');
    
    // 🎯 FIX: Check quota and handle auth modal BEFORE async operations
    final canPerformAny = enforcer.canPerformAnyAction();
    final usageSummary = enforcer.getUsageSummary();
    
    debugPrint('🔍 Pre-action quota check:');
    debugPrint('  - Can perform any: $canPerformAny');
    debugPrint('  - Usage: ${usageSummary['totalUsage']}/${usageSummary['totalLimit']}');
    debugPrint('  - Authenticated: ${usageSummary['authenticated']}');
    
    if (!canPerformAny) {
      // Handle authentication modal immediately with valid context
      final authHandled = await enforcer.enforceLimit(
        actionType,
        context: context,
        source: source,
      );
      
      if (!authHandled) {
        debugPrint('🚫 UnifiedActionMiddleware: Action blocked - user at quota limit (pre-check)');
        return null;
      }
    }
    
    // 🎯 FIX: Add state synchronization delay for auth transitions
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Use atomic executeAction method for clean quota enforcement + recording
    // Note: Pass null context after async gap to avoid BuildContext warnings
    final quotaConsumed = await enforcer.executeAction(
      actionType,
      context: null, // Don't pass context across async gaps
      source: source,
      metadata: metadata,
    );
    
    if (!quotaConsumed) {
      debugPrint('🚫 UnifiedActionMiddleware: Action blocked by quota enforcement');
      return null;
    }
    
    // 🚨 CRITICAL FIX: Double-check quota after executeAction for race conditions
    final finalCheck = enforcer.canPerformAnyAction();
    if (!finalCheck) {
      debugPrint('🚨 UnifiedActionMiddleware: RACE CONDITION DETECTED - User at limit after quota check');
      debugPrint('🚫 Blocking action to prevent quota bypass');
      return null;
    }
    
    try {
      // Execute the action (quota already consumed)
      debugPrint('⚡ UnifiedActionMiddleware: Quota verified - executing action...');
      debugPrint('🔍 FINAL CHECK: About to call action() - if you see API logs after this, quota was properly verified');
      final result = await action();
      
      // Log success with updated usage
      final usageSummary = enforcer.getUsageSummary();
      debugPrint('✅ UnifiedActionMiddleware: Action completed successfully');
      debugPrint('📊 Updated usage: ${usageSummary['totalUsage']}/${usageSummary['totalLimit']}');
      
      return result;
    } catch (error) {
      debugPrint('❌ UnifiedActionMiddleware: Action failed with error: $error');
      
      // NOTE: Currently keeping quota consumed for failed actions to prevent abuse.
      // Future enhancement: Implement smart rollback based on error type.
      
      rethrow;
    }
  }

  /// Execute an action with quota check but manual recording
  /// Use this when you need custom logic for when to record the action
  Future<bool> checkQuotaOnly(
    ActionType actionType, {
    BuildContext? context,
    String? source,
  }) async {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    
    debugPrint('🔍 UnifiedActionMiddleware: Checking quota for $actionType from ${source ?? "unknown"}');
    
    return await enforcer.enforceLimit(
      actionType,
      context: context,
      source: source,
    );
  }

  /// Manually record an action (use with checkQuotaOnly)
  Future<bool> recordAction(
    ActionType actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    final result = await tracker.recordAction(actionType, metadata: metadata);
    
    if (result.success) {
      final usageSummary = getUsageSummary();
      debugPrint('📊 UnifiedActionMiddleware: Action recorded manually');
      debugPrint('📊 Current usage: ${usageSummary['totalUsage']}/${usageSummary['totalLimit']}');
    } else {
      debugPrint('❌ UnifiedActionMiddleware: Failed to record action');
    }
    
    return result.success;
  }

  /// Get current usage summary (enhanced with unified data)
  Map<String, dynamic> getUsageSummary() {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    return enforcer.getUsageSummary();
  }

  /// Check if user can perform any action
  bool canPerformAnyAction() {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    return enforcer.canPerformAnyAction();
  }

  /// Get total remaining actions count (across all types)
  int getTotalRemainingActions() {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    return enforcer.getTotalRemainingActions();
  }

  /// Get remaining actions for specific action type
  int getRemainingActions(ActionType actionType) {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    return tracker.getRemainingActions(actionType);
  }

  /// Get remaining actions for all action types
  Map<ActionType, int> getRemainingActionsAll() {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    return enforcer.getRemainingActionsAll();
  }

  /// Check if specific action type can be performed
  bool canPerformAction(ActionType actionType) {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    return tracker.canPerformAction(actionType);
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    return enforcer.getStatusMessage();
  }

  /// Get usage message for specific action type
  String getUsageMessage(ActionType actionType) {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    return tracker.getUsageMessage(actionType);
  }

  /// Debug method: Get detailed usage breakdown
  Map<String, dynamic> getDetailedUsageBreakdown() {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    final actionState = ref.read(unifiedActionTrackerProvider);
    
    return {
      'actionCounts': actionState.actionCounts,
      'dailyLimits': actionState.dailyLimits,
      'lastReset': actionState.lastReset.toIso8601String(),
      'hasReachedLimit': actionState.hasReachedLimit,
      'totalUsage': tracker.getTotalUsage(),
      'totalLimit': tracker.getTotalLimit(),
      'canPerformAny': canPerformAnyAction(),
      'statusMessage': getStatusMessage(),
      'remainingByType': getRemainingActionsAll(),
    };
  }

  /// Debug method: Reset all actions for testing
  Future<void> resetAllActions() async {
    final tracker = ref.read(unifiedActionTrackerProvider.notifier);
    await tracker.resetAllActions();
    debugPrint('🔄 UnifiedActionMiddleware: All actions reset for testing');
  }
}

/// ✅ UPDATED PROVIDER DEFINITIONS
final unifiedActionMiddlewareProvider = Provider<UnifiedActionMiddleware>((ref) {
  return UnifiedActionMiddleware(ref);
});

// Backward compatibility alias (optional)
final actionMiddlewareProvider = Provider<UnifiedActionMiddleware>((ref) {
  return ref.watch(unifiedActionMiddlewareProvider);
});

/// Helper extension for easy middleware access in services
extension UnifiedActionMiddlewareRef on Ref {
  UnifiedActionMiddleware get actionMiddleware => read(unifiedActionMiddlewareProvider);
  UnifiedActionMiddleware get unifiedActionMiddleware => read(unifiedActionMiddlewareProvider);
}
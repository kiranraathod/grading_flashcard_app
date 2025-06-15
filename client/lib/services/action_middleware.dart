import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_action_tracking_provider.dart';
import '../services/usage_limit_enforcer.dart';

/// Middleware that wraps actions with quota enforcement
/// Ensures consistent usage limit checking across all features
class ActionMiddleware {
  final Ref ref;
  
  ActionMiddleware(this.ref);

  /// Execute an action with automatic quota enforcement
  /// Returns the result of the action or null if blocked by quota
  Future<T?> executeWithQuota<T>(
    ActionType actionType,
    Future<T> Function() action, {
    BuildContext? context,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    final enforcer = ref.read(usageLimitEnforcerProvider);
    
    debugPrint('🛡️ ActionMiddleware: Executing $actionType from ${source ?? "unknown"}');
    
    // Check if action is allowed (combined quota)
    final canProceed = await enforcer.enforceLimit(
      actionType,
      context: context,
      source: source,
    );
    
    if (!canProceed) {
      debugPrint('🚫 ActionMiddleware: Action blocked by quota enforcement');
      return null;
    }
    
    try {
      // Execute the action
      debugPrint('⚡ ActionMiddleware: Executing action...');
      final result = await action();
      
      // Record the action after successful execution
      final actionTracker = ref.read(actionTrackerProvider.notifier);
      await actionTracker.recordAction(actionType, metadata: metadata);
      
      // Log success
      final usageSummary = enforcer.getUsageSummary();
      debugPrint('✅ ActionMiddleware: Action completed successfully');
      debugPrint('📊 Updated usage: ${usageSummary['totalUsed']}/${usageSummary['maxActions']}');
      
      return result;
    } catch (error) {
      debugPrint('❌ ActionMiddleware: Action failed with error: $error');
      // Don't record the action if it failed
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
    final enforcer = ref.read(usageLimitEnforcerProvider);
    
    debugPrint('🔍 ActionMiddleware: Checking quota for $actionType from ${source ?? "unknown"}');
    
    return await enforcer.enforceLimit(
      actionType,
      context: context,
      source: source,
    );
  }

  /// Manually record an action (use with checkQuotaOnly)
  Future<void> recordAction(
    ActionType actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    final actionTracker = ref.read(actionTrackerProvider.notifier);
    await actionTracker.recordAction(actionType, metadata: metadata);
    
    final enforcer = ref.read(usageLimitEnforcerProvider);
    final usageSummary = enforcer.getUsageSummary();
    debugPrint('📊 ActionMiddleware: Action recorded manually');
    debugPrint('📊 Current usage: ${usageSummary['totalUsed']}/${usageSummary['maxActions']}');
  }

  /// Get current usage summary
  Map<String, dynamic> getUsageSummary() {
    final enforcer = ref.read(usageLimitEnforcerProvider);
    return enforcer.getUsageSummary();
  }

  /// Check if user can perform any action
  bool canPerformAnyAction() {
    final enforcer = ref.read(usageLimitEnforcerProvider);
    return enforcer.canPerformAnyAction();
  }

  /// Get remaining actions count
  int getRemainingActions() {
    final enforcer = ref.read(usageLimitEnforcerProvider);
    return enforcer.getRemainingActions();
  }
}

/// Provider for action middleware
final actionMiddlewareProvider = Provider<ActionMiddleware>((ref) {
  return ActionMiddleware(ref);
});

/// Helper extension for easy middleware access in services
extension ActionMiddlewareRef on Ref {
  ActionMiddleware get actionMiddleware => read(actionMiddlewareProvider);
}

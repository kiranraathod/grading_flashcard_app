import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/usage_gate_service.dart';
import '../utils/design_system.dart';
import 'authentication_popup.dart';

/// AuthenticatedAction wraps interactive elements to enforce usage limits
/// 
/// Automatically tracks usage and shows authentication prompts when limits are reached.
/// Provides a seamless experience for both guest and authenticated users.
class AuthenticatedAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String actionType;
  final bool showUsageHint;
  final Widget? usageHintWidget;

  const AuthenticatedAction({
    super.key,
    required this.child,
    required this.onPressed,
    required this.actionType,
    this.showUsageHint = false,
    this.usageHintWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageGateService>(
      builder: (context, usageGate, _) {
        return Column(
          children: [
            // Main interactive element
            GestureDetector(
              onTap: onPressed != null ? () => _handleAction(context, usageGate) : null,
              child: child,
            ),
            
            // Optional usage hint
            if (showUsageHint) ...[
              const SizedBox(height: DS.spacingXs),
              _buildUsageHint(context, usageGate),
            ],
          ],
        );
      },
    );
  }

  /// Handle action with usage gate check
  Future<void> _handleAction(BuildContext context, UsageGateService usageGate) async {
    final canPerform = await usageGate.attemptAction(actionType: actionType);
    
    if (!context.mounted) return;
    
    if (canPerform && onPressed != null) {
      onPressed!();
    } else if (!canPerform) {
      // Show authentication popup if action was blocked
      _showAuthenticationPopup(context);
    }
  }

  /// Show authentication popup
  void _showAuthenticationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AuthenticationPopup(
        onAuthenticationComplete: null, // Will close automatically
      ),
    );
  }

  /// Build usage hint widget
  Widget _buildUsageHint(BuildContext context, UsageGateService usageGate) {
    if (usageHintWidget != null) {
      return usageHintWidget!;
    }

    final status = usageGate.getUsageStatus();
    final theme = Theme.of(context);
    
    if (status['isAuthenticated'] == true) {
      // Show unlimited for authenticated users
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive_outlined,
              size: 12,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: DS.spacingXs),
            Text(
              'Unlimited access',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // Show usage count for guest users
      final remainingActions = status['remainingActions'] as int;
      final usageCount = status['usageCount'] as int;
      final usageLimit = status['usageLimit'] as int;
      
      if (remainingActions <= 1) {
        // Near limit warning
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_outlined,
                size: 12,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: DS.spacingXs),
              Text(
                remainingActions == 0 ? 'Sign in to continue' : '$remainingActions use left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else {
        // Normal usage count
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          ),
          child: Text(
            '$usageCount/$usageLimit uses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
    }
  }
}

/// Convenience widget for wrapping buttons with authentication action
class AuthenticatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String actionType;
  final ButtonStyle? style;
  final bool showUsageHint;

  const AuthenticatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.actionType,
    this.style,
    this.showUsageHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAction(
      actionType: actionType,
      onPressed: onPressed,
      showUsageHint: showUsageHint,
      child: FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

/// Usage status indicator widget
class UsageStatusIndicator extends StatelessWidget {
  final bool compact;

  const UsageStatusIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageGateService>(
      builder: (context, usageGate, _) {
        final status = usageGate.getUsageStatus();
        final theme = Theme.of(context);
        
        if (status['isAuthenticated'] == true) {
          // Authenticated user indicator
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? DS.spacingXs : DS.spacingS,
              vertical: compact ? 2 : DS.spacingXs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: compact ? 12 : 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                if (!compact) ...[
                  const SizedBox(width: DS.spacingXs),
                  Text(
                    'Premium',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        } else {
          // Guest user indicator
          final remainingActions = status['remainingActions'] as int;
          
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? DS.spacingXs : DS.spacingS,
              vertical: compact ? 2 : DS.spacingXs,
            ),
            decoration: BoxDecoration(
              color: remainingActions <= 1
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  remainingActions <= 1 ? Icons.warning_outlined : Icons.schedule_outlined,
                  size: compact ? 12 : 16,
                  color: remainingActions <= 1
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (!compact) ...[
                  const SizedBox(width: DS.spacingXs),
                  Text(
                    remainingActions == 0 ? 'Trial ended' : '$remainingActions left',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: remainingActions <= 1
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }
}

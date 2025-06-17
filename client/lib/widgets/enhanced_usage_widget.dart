import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/unified_action_tracking_provider.dart';
import '../models/simple_auth_state.dart';

/// Enhanced usage display widget with progress bar and smart messaging
class EnhancedUsageWidget extends ConsumerWidget {
  final bool showProgressBar;
  final bool showDetails;
  final EdgeInsets? padding;

  const EnhancedUsageWidget({
    super.key,
    this.showProgressBar = true,
    this.showDetails = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageStatus = ref.watch(usageStatusProvider);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main status message
          Text(
            usageStatus.statusMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _getStatusColor(context, usageStatus),
            ),
          ),
          
          if (showProgressBar) ...[
            const SizedBox(height: 8),
            _buildProgressBar(context, usageStatus),
          ],
          
          // Auth encouragement message
          if (usageStatus.authEncouragement.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      usageStatus.authEncouragement,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Detailed breakdown (optional)
          if (showDetails) ...[
            const SizedBox(height: 12),
            _buildDetailedBreakdown(context, usageStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, UsageStatus status) {
    final progress = status.progressPercentage / 100.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${status.totalUsage}/${status.totalLimit} actions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Resets in ${status.resetTime}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(context, status),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBreakdown(BuildContext context, UsageStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Details',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Used Today',
                  status.totalUsage.toString(),
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Remaining',
                  status.remainingActions.toString(),
                  Icons.schedule,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Limit',
                  status.totalLimit.toString(),
                  Icons.security,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, UsageStatus status) {
    if (!status.canPerformActions) {
      return Theme.of(context).colorScheme.error;
    }
    if (status.shouldShowWarning) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  }

  Color _getProgressColor(BuildContext context, UsageStatus status) {
    switch (status.progressColor) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}

/// Simple usage badge for minimal UI space
class UsageBadge extends ConsumerWidget {
  const UsageBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageStatus = ref.watch(usageStatusProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBadgeColor(context, usageStatus).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBadgeColor(context, usageStatus).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${usageStatus.remainingActions} left',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getBadgeColor(context, usageStatus),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBadgeColor(BuildContext context, UsageStatus status) {
    if (!status.canPerformActions) {
      return Theme.of(context).colorScheme.error;
    }
    if (status.shouldShowWarning) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

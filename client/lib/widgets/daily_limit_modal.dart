import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'authenticated_limit_reached_modal.dart';

class DailyLimitModal extends ConsumerStatefulWidget {
  final bool isAuthenticated;
  final String currentUsage;
  final String resetTime;
  final VoidCallback? onSignInPressed;
  final VoidCallback? onUpgradePressed;

  const DailyLimitModal({
    super.key,
    required this.isAuthenticated,
    required this.currentUsage,
    required this.resetTime,
    this.onSignInPressed,
    this.onUpgradePressed,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isAuthenticated,
    required String currentUsage,
    required String resetTime,
    VoidCallback? onSignInPressed,
    VoidCallback? onUpgradePressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return DailyLimitModal(
          isAuthenticated: isAuthenticated,
          currentUsage: currentUsage,
          resetTime: resetTime,
          onSignInPressed: onSignInPressed,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }

  @override
  ConsumerState<DailyLimitModal> createState() => _DailyLimitModalState();
}

class _DailyLimitModalState extends ConsumerState<DailyLimitModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog(
              elevation: 24,
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with matching teal color from auth modal
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B), // Teal to match auth modal
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isAuthenticated
                            ? Icons.schedule_rounded
                            : Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title - matching auth modal typography
                    Text(
                      widget.isAuthenticated 
                          ? 'Daily Limit Reached'
                          : 'Daily Limit Reached',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      widget.isAuthenticated
                          ? 'You\'ve used all your daily actions'
                          : 'Sign in to unlock more actions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Info banner - matching the teal info box from auth modal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00897B).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: const Color(0xFF00897B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.isAuthenticated
                                  ? 'Current usage: ${widget.currentUsage}. Resets ${widget.resetTime}'
                                  : 'You\'ve reached your daily limit. Sign in for 5 more grading attempts and additional features.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF00695C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (!widget.isAuthenticated) ...[
                      // Primary action - Sign In (matching auth modal style)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onSignInPressed?.call();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Sign In for More Actions',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary action - Later
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ),
                    ] else ...[
                      // For authenticated users - just close or upgrade options
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Got It',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (widget.onUpgradePressed != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onUpgradePressed?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00897B),
                              side: const BorderSide(
                                color: Color(0xFF00897B),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Upgrade for Unlimited',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Close text button at bottom
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class for consistent usage with your quota system
class QuotaLimitHandler {
  static Future<void> showLimitReached(
    BuildContext context, {
    required bool isAuthenticated,
    required int currentUsage,
    required int totalLimit,
    required String resetTime,
    VoidCallback? onSignInPressed,
    VoidCallback? onUpgradePressed,
  }) async {
    if (isAuthenticated && currentUsage >= totalLimit) {
      // Authenticated user reached their final limit (5/5) - show special modal
      return AuthenticatedLimitReachedModal.show(
        context,
        resetTime: resetTime,
        onUpgradePressed: onUpgradePressed,
      );
    } else {
      // Guest user reached limit (3/3) - show regular modal with sign-in option
      return DailyLimitModal.show(
        context,
        isAuthenticated: isAuthenticated,
        currentUsage: '$currentUsage/$totalLimit actions used',
        resetTime: resetTime,
        onSignInPressed: onSignInPressed,
        onUpgradePressed: onUpgradePressed,
      );
    }
  }
}

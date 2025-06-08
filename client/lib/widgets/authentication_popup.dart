import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/supabase_auth_service.dart';
import '../services/usage_gate_service.dart';
import '../utils/design_system.dart';

/// Material Design 3 compliant authentication popup with comprehensive accessibility
/// 
/// Implements WCAG 2.2 requirements, progressive authentication patterns,
/// and modern UX design principles for 2025.
class AuthenticationPopup extends StatefulWidget {
  final VoidCallback? onAuthenticationComplete;
  final VoidCallback? onAuthenticationCancelled;

  const AuthenticationPopup({
    super.key,
    this.onAuthenticationComplete,
    this.onAuthenticationCancelled,
  });

  @override
  State<AuthenticationPopup> createState() => _AuthenticationPopupState();
}

class _AuthenticationPopupState extends State<AuthenticationPopup>
    with SingleTickerProviderStateMixin {
  // State management
  bool _isAuthenticating = false;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // Focus management for accessibility
  late FocusNode _dialogFocusNode;
  late FocusNode _primaryButtonFocusNode;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFocusNodes();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DS.durationMedium,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeFocusNodes() {
    _dialogFocusNode = FocusNode();
    _primaryButtonFocusNode = FocusNode();
  }

  void _startEntranceAnimation() {
    _animationController.forward();
    
    // Set initial focus after animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _primaryButtonFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dialogFocusNode.dispose();
    _primaryButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseAuthService, UsageGateService>(
      builder: (context, authService, usageGate, child) {
        return PopScope(
          canPop: false, // Prevent dismissal to ensure user addresses usage limit
          child: _buildDialogScaffold(context, authService, usageGate),
        );
      },
    );
  }

  Widget _buildDialogScaffold(
    BuildContext context,
    SupabaseAuthService authService,
    UsageGateService usageGate,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.8),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildDialog(context, authService, usageGate),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    SupabaseAuthService authService,
    UsageGateService usageGate,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = DS.isSmallScreen(context);
    
    return Focus(
      focusNode: _dialogFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        explicitChildNodes: true,
        scopesRoute: true,
        label: 'Authentication required dialog',
        child: Container(
          margin: EdgeInsets.all(isSmallScreen ? DS.spacingM : DS.spacingL),
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? double.infinity : 400,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DS.borderRadiusLarge),
            boxShadow: DS.getShadow(DS.elevationXl, color: colorScheme.shadow),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DS.borderRadiusLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildContent(context, authService, usageGate),
                _buildActions(context, authService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // For non-dismissible dialogs, we don't close on escape
      // but we can provide feedback or show help
      HapticFeedback.selectionClick();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: DS.iconSizeM,
                  semanticLabel: 'Authentication required',
                ),
              ),
              const SizedBox(width: DS.spacingM),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Continue Learning',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DS.spacingM),
          // Description
          Text(
            'You\'ve reached your trial limit. Sign in to keep your progress and unlock unlimited access to FlashMaster.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SupabaseAuthService authService,
    UsageGateService usageGate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildBenefitsList(context),
          const SizedBox(height: DS.spacingM),
          
          // State-specific content
          if (_errorMessage != null) ...[
            _buildErrorState(context),
            const SizedBox(height: DS.spacingM),
          ],
          
          if (_isAuthenticating || authService.isAuthenticating) ...[
            _buildLoadingState(context),
            const SizedBox(height: DS.spacingM),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final benefits = [
      {
        'icon': Icons.cloud_sync_outlined,
        'title': 'Sync across devices',
        'description': 'Access your flashcards anywhere'
      },
      {
        'icon': Icons.trending_up_outlined,
        'title': 'Track your progress',
        'description': 'Detailed learning analytics'
      },
      {
        'icon': Icons.all_inclusive_outlined,
        'title': 'Unlimited access',
        'description': 'No more usage limits'
      },
    ];

    return Column(
      children: benefits.map<Widget>((benefit) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: colorScheme.onSecondaryContainer,
                  size: DS.iconSizeS,
                ),
              ),
              const SizedBox(width: DS.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      benefit['description'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DS.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(DS.borderRadiusMedium),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: DS.iconSizeS,
              semanticLabel: 'Error',
            ),
            const SizedBox(width: DS.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign-in failed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Semantics(
      liveRegion: true,
      label: 'Signing in, please wait',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DS.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(DS.borderRadiusMedium),
        ),
        child: Row(
          children: [
            SizedBox(
              width: DS.iconSizeS,
              height: DS.iconSizeS,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: DS.spacingM),
            Text(
              'Signing you in...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, SupabaseAuthService authService) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = _isAuthenticating || authService.isAuthenticating;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Primary action button
          SizedBox(
            width: double.infinity,
            height: DS.buttonHeightXl,
            child: FilledButton.icon(
              focusNode: _primaryButtonFocusNode,
              onPressed: isLoading ? null : _handleGoogleSignIn,
              icon: isLoading
                  ? SizedBox(
                      width: DS.iconSizeS,
                      height: DS.iconSizeS,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.login_rounded,
                      size: DS.iconSizeS,
                    ),
              label: Text(
                isLoading ? 'Signing In...' : 'Continue with Google',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.borderRadiusMedium),
                ),
                elevation: 0,
              ),
            ),
          ),
          
          const SizedBox(height: DS.spacingM),
          
          // Privacy notice
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DS.spacingXs),
              Flexible(
                child: Text(
                  'Your data is secure and never shared',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    // Prevent multiple simultaneous authentication attempts
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    // Provide haptic feedback for button press
    HapticFeedback.selectionClick();

    try {
      final authService = context.read<SupabaseAuthService>();
      final usageGate = context.read<UsageGateService>();

      final success = await authService.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        // Authentication successful - save progress and migrate data
        HapticFeedback.lightImpact();
        
        // Handle successful authentication and progress saving
        await usageGate.handleSuccessfulAuthentication();
        usageGate.markAuthPromptHandled();
        
        widget.onAuthenticationComplete?.call();
        
        // Animate out before closing
        await _animationController.reverse();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Authentication was cancelled or failed
        setState(() {
          _errorMessage = 'Sign in was cancelled. Please try again to continue using FlashMaster.';
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Handle authentication errors
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
        HapticFeedback.selectionClick();
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('provider is not enabled') || errorLower.contains('unsupported provider')) {
      return 'Google sign-in is temporarily unavailable. Our team is working to fix this. Please try again later or contact support.';
    } else if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorLower.contains('cancelled') || errorLower.contains('cancel')) {
      return 'Sign in was cancelled. Please try again to continue using FlashMaster.';
    } else if (errorLower.contains('timeout')) {
      return 'Sign in timed out. Please check your connection and try again.';
    } else if (errorLower.contains('invalid')) {
      return 'There was an issue with your account. Please try again.';
    } else if (errorLower.contains('validation_failed')) {
      return 'Authentication service is currently unavailable. Please try again later or contact support.';
    } else {
      return 'Something went wrong. Please try again or contact support if the problem persists.';
    }
  }
}

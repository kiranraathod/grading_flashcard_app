import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/working_auth_provider.dart';
import '../../models/simple_auth_state.dart';
import '../../utils/config.dart';

/// Material Design 3 authentication modal with progressive enhancement
/// 
/// Follows zero-disruption principle by only showing when authentication is enabled.
/// Implements modern authentication UX with accessibility-first design.
/// 
/// MIGRATION: Converted from Provider to Riverpod
/// - StatefulWidget → ConsumerStatefulWidget
/// - Provider.of → ref.watch/ref.read
/// - Consumer → Direct state watching
class AuthenticationModal extends ConsumerStatefulWidget {
  const AuthenticationModal({super.key});
  
  /// Show authentication modal if feature is enabled
  static Future<void> show(BuildContext context) async {
    if (!AuthConfig.enableAuthentication) {
      debugPrint('Authentication modal blocked - feature disabled');
      return;
    }
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AuthenticationModal(),
    );
  }
  
  @override
  ConsumerState<AuthenticationModal> createState() => _AuthenticationModalState();
}

class _AuthenticationModalState extends ConsumerState<AuthenticationModal> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Material Design 3 entrance animation
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Watch authentication state using Riverpod
    final authState = ref.watch(authNotifierProvider);    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog(
              elevation: 24, // Material Design 3 specification
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24), // MD3 standard padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildAuthForm(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, colorScheme, authState),
                    const SizedBox(height: 16),
                    _buildToggleMode(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }  
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.primary,
          child: Icon(
            Icons.person,
            color: colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sign In',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildAuthForm(BuildContext context, ColorScheme colorScheme) {
    // Form fields removed - simplified authentication modal
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, AuthState authState) {
    final isLoading = authState is AuthStateLoading;
    
    return Column(
      children: [
        // Google sign in button
        if (AuthConfig.enableSocialLogin)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _handleGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ),
        
        // Divider with "or"
        if (AuthConfig.enableSocialLogin && AuthConfig.enableDemoMode) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ],
          
        // Demo sign in button (for testing when auth is broken)
        if (AuthConfig.enableDemoMode) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _handleDemoSignIn,
              icon: const Icon(Icons.science),
              label: const Text('Demo Sign-In (Testing)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildToggleMode(BuildContext context) {
    // Toggle mode removed - simplified authentication modal
    return const SizedBox.shrink();
  }

  Future<void> _handleDemoSignIn() async {
    debugPrint('🧪 Demo sign-in attempt started');
    
    // Use Riverpod notifier for demo sign-in
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    try {
      await authNotifier.signInDemo();
      
      final currentState = ref.read(authNotifierProvider);
      
      if (currentState is AuthStateAuthenticated && mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Demo authentication successful! You now have unlimited grading actions.');
        debugPrint('✅ Demo sign-in successful - modal closed');
      } else if (currentState is AuthStateError && mounted) {
        _showSnackBar(currentState.message);
        debugPrint('❌ Demo sign-in failed: ${currentState.message}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Demo authentication failed');
        debugPrint('❌ Demo sign-in exception: $e');
      }
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    debugPrint('🔍 Google sign-in attempt started');
    
    // Use Riverpod notifier for Google sign-in
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    try {
      await authNotifier.signInWithGoogle();
      
      final currentState = ref.read(authNotifierProvider);
      
      if (currentState is AuthStateAuthenticated && mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Welcome to FlashMaster!');
        debugPrint('✅ Google sign-in successful - modal closed');
      } else if (currentState is AuthStateError && mounted) {
        _showSnackBar(currentState.message);
        debugPrint('❌ Google sign-in failed: ${currentState.message}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Google sign-in failed. Please try again.');
        debugPrint('❌ Google sign-in exception: $e');
      }
    }
  }  
  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
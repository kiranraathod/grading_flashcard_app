import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/authentication_service.dart';
import '../../services/guest_user_manager.dart';
import '../../utils/config.dart';

/// Material Design 3 authentication modal with progressive enhancement
/// 
/// Follows zero-disruption principle by only showing when authentication is enabled.
/// Implements modern authentication UX with accessibility-first design.
class AuthenticationModal extends StatefulWidget {
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
  State<AuthenticationModal> createState() => _AuthenticationModalState();
}

class _AuthenticationModalState extends State<AuthenticationModal> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  bool _isSignUp = false;
  bool _passwordVisible = false;
  
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
    
    // Focus first input after animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
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
                    const SizedBox(height: 20), // MD3 spacing
                    _buildUsageInfo(context),
                    const SizedBox(height: 24),
                    _buildAuthForm(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, colorScheme),
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
          _isSignUp ? 'Create Account' : 'Sign In',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp 
            ? 'Get unlimited flashcard grading actions'
            : 'Access your unlimited grading actions',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  Widget _buildUsageInfo(BuildContext context) {
    return Consumer<GuestUserManager>(
      builder: (context, guestManager, child) {
        if (!AuthConfig.enableUsageLimits) return const SizedBox.shrink();
        
        final message = guestManager.getUsageMessage();
        if (message.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAuthForm(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Email field
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        
        // Password field
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: !_passwordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleEmailAuth(),
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Consumer<AuthenticationService>(
      builder: (context, authService, child) {
        final isLoading = authService.authState == AuthState.loading;
        
        return Column(
          children: [
            // Primary action button (Email sign in/up)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : _handleEmailAuth,
                child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Divider with "or"
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
            
            const SizedBox(height: 12),
            
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
      },
    );
  }
  
  Widget _buildToggleMode(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignUp = !_isSignUp;
        });
      },
      child: Text(
        _isSignUp
          ? 'Already have an account? Sign in'
          : 'Don\'t have an account? Sign up',
      ),
    );
  }
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    
    debugPrint('🔍 Email auth attempt: ${_isSignUp ? "signup" : "signin"} for $email');
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    
    bool success;
    if (_isSignUp) {
      success = await authService.signUpWithEmail(email, password);
    } else {
      success = await authService.signInWithEmail(email, password);
    }
    
    debugPrint('🔍 Email auth result: $success');
    if (success && mounted) {
      Navigator.of(context).pop();
      _showSnackBar('Welcome to FlashMaster!');
      debugPrint('✅ Email auth successful - modal closed');
    } else if (mounted) {
      final errorMsg = authService.errorMessage ?? 'Authentication failed';
      _showSnackBar(errorMsg);
      debugPrint('❌ Email auth failed: $errorMsg');
    }
  }
  
  Future<void> _handleDemoSignIn() async {
    debugPrint('🧪 Demo sign-in attempt started');
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    
    final success = await authService.signInDemo();
    
    debugPrint('🧪 Demo sign-in result: $success');
    if (success && mounted) {
      Navigator.of(context).pop();
      _showSnackBar('Demo authentication successful! You now have 5 grading actions.');
      debugPrint('✅ Demo sign-in successful - modal closed');
    } else if (mounted) {
      _showSnackBar('Demo authentication failed');
      debugPrint('❌ Demo sign-in failed');
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    debugPrint('🔍 Google sign-in attempt started');
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    
    final success = await authService.signInWithGoogle();
    
    debugPrint('🔍 Google sign-in result: $success');
    if (success && mounted) {
      Navigator.of(context).pop();
      _showSnackBar('Welcome to FlashMaster!');
      debugPrint('✅ Google sign-in successful - modal closed');
    } else if (mounted) {
      final errorMsg = authService.errorMessage ?? 'Google sign-in failed';
      _showSnackBar(errorMsg);
      debugPrint('❌ Google sign-in failed: $errorMsg');
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}

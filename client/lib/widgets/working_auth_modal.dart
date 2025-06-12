import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_auth_provider.dart';

/// Simple authentication modal for consistent user experience
class WorkingAuthModal extends ConsumerStatefulWidget {
  final String reason;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const WorkingAuthModal({
    super.key,
    required this.reason,
    this.onSuccess,
    this.onCancel,
  });

  /// Show authentication modal with platform-specific design
  static Future<void> show(
    BuildContext context, {
    required String reason,
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) async {
    if (Platform.isIOS) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => WorkingAuthModal(
          reason: reason,
          onSuccess: onSuccess,
          onCancel: onCancel,
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: WorkingAuthModal(
            reason: reason,
            onSuccess: onSuccess,
            onCancel: onCancel,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<WorkingAuthModal> createState() => _WorkingAuthModalState();
}

class _WorkingAuthModalState extends ConsumerState<WorkingAuthModal> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication success
    ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthStateAuthenticated) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    });

    return Container(
      height: Platform.isIOS 
          ? MediaQuery.of(context).size.height * 0.85
          : null,
      constraints: Platform.isAndroid
          ? BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            )
          : null,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: Platform.isIOS
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPromptSection(),
                  const SizedBox(height: 32),
                  _buildAuthForm(),
                  const SizedBox(height: 24),
                  _buildSocialAuth(),
                  const SizedBox(height: 16),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    return Column(
      children: [
        Icon(
          _getPromptIcon(),
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          _getPromptTitle(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _getPromptMessage(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthStateLoading;

    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleEmailAuth,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isSignUp ? 'Create Account' : 'Sign In'),
          ),
        ),
        if (authState is AuthStateError)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              authState.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }  Widget _buildSocialAuth() {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthStateLoading;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : _handleGoogleAuth,
            icon: const Icon(Icons.login),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: isLoading ? null : _handleDemoAuth,
            icon: const Icon(Icons.science),
            label: const Text('Try Demo Mode'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
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
        ),
        if (!_isSignUp)
          TextButton(
            onPressed: _handleForgotPassword,
            child: const Text('Forgot password?'),
          ),
      ],
    );
  }

  // Helper methods for UI content
  IconData _getPromptIcon() {
    switch (widget.reason) {
      case 'save_progress':
        return Icons.bookmark_border;
      case 'unlock_unlimited':
        return Icons.all_inclusive;
      case 'sync_devices':
        return Icons.sync;
      case 'premium_features':
        return Icons.star_border;
      case 'flashcard_limit':
        return Icons.quiz_outlined;
      case 'interview_limit':
        return Icons.work_outline;
      default:
        return Icons.person_add_outlined;
    }
  }

  String _getPromptTitle() {
    switch (widget.reason) {
      case 'save_progress':
        return 'Save Your Progress';
      case 'unlock_unlimited':
        return 'Unlock Unlimited Access';
      case 'sync_devices':
        return 'Sync Across Devices';
      case 'premium_features':
        return 'Unlock Premium Features';
      case 'flashcard_limit':
        return 'Flashcard Limit Reached';
      case 'interview_limit':
        return 'Interview Practice Limit Reached';
      default:
        return 'Create Your Account';
    }
  }

  String _getPromptMessage() {
    switch (widget.reason) {
      case 'save_progress':
        return 'You\'ve made great progress! Create an account to save it forever.';
      case 'unlock_unlimited':
        return 'You\'re on fire! 🔥 Create an account for unlimited access.';
      case 'sync_devices':
        return 'Access your progress on all your devices with an account.';
      case 'premium_features':
        return 'Unlock advanced features and detailed analytics.';
      case 'flashcard_limit':
        return 'You\'ve reached your daily flashcard limit. Sign in for more!';
      case 'interview_limit':
        return 'You\'ve reached your daily interview practice limit. Sign in for more!';
      default:
        return 'Create an account to continue and save your progress.';
    }
  }  // Authentication action handlers
  void _handleEmailAuth() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
        ),
      );
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    if (_isSignUp) {
      authNotifier.signUpWithEmail(email, password);
    } else {
      authNotifier.signInWithEmail(email, password);
    }
  }

  void _handleGoogleAuth() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.signInWithGoogle();
  }

  void _handleDemoAuth() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.signInDemo();
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
        ),
      );
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.resetPassword(email);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset email sent. Check your inbox.'),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}

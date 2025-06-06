import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/supabase_auth_service.dart';
import '../services/usage_gate_service.dart';
import '../utils/design_system.dart';
import '../utils/colors.dart';

/// AuthenticationPopup displays when users reach usage limits
/// 
/// Non-dismissible popup that prompts users to sign in with Google
/// to save their progress and continue using the app.
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

class _AuthenticationPopupState extends State<AuthenticationPopup> {
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Consumer2<SupabaseAuthService, UsageGateService>(
      builder: (context, authService, usageGate, child) {
        return WillPopScope(
          onWillPop: () async => false, // Non-dismissible
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.borderRadiusLarge),
            ),            title: Row(
              children: [
                Icon(
                  Icons.save,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: DesignSystem.spacingMedium),
                Expanded(
                  child: Text(
                    'Save Your Progress',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'ve reached your trial limit! Sign in with Google to:',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: DesignSystem.spacingMedium),
                _buildBenefitItem('✨', 'Save all your progress'),
                _buildBenefitItem('🔄', 'Sync across devices'),
                _buildBenefitItem('🚀', 'Unlimited flashcard access'),
                _buildBenefitItem('🎯', 'Track your learning journey'),
                const SizedBox(height: DesignSystem.spacingLarge),
                if (_isAuthenticating || authService.isAuthenticating)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),            actions: [
              if (!_isAuthenticating && !authService.isAuthenticating) ...[
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingLarge,
                      vertical: DesignSystem.spacingMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: DesignSystem.spacingSmall),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isAuthenticating = true);
    
    try {
      final authService = context.read<SupabaseAuthService>();
      final usageGate = context.read<UsageGateService>();
      
      final success = await authService.signInWithGoogle();
      
      if (success && mounted) {
        usageGate.markAuthPromptHandled();
        widget.onAuthenticationComplete?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/usage_gate_service.dart';
import '../widgets/authentication_popup.dart';

/// Wrapper widget that enforces authentication gates for actions
/// 
/// Use this around any action that should respect usage limits.
/// Shows authentication popup when limits are reached.
class AuthenticatedAction extends StatelessWidget {
  final Widget child;
  final String actionType;
  final VoidCallback? onAction;
  final bool showDebugInfo;

  const AuthenticatedAction({
    super.key,
    required this.child,
    required this.actionType,
    this.onAction,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageGateService>(
      builder: (context, usageGate, _) {
        return GestureDetector(
          onTap: () => _handleTap(context, usageGate),
          child: Stack(
            children: [
              child,
              if (showDebugInfo) _buildDebugOverlay(usageGate),
              if (usageGate.shouldShowAuthPrompt) _buildAuthOverlay(context),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, UsageGateService usageGate) async {
    final canPerform = await usageGate.attemptAction(actionType: actionType);
    
    if (canPerform) {
      onAction?.call();
    } else {
      // Show authentication popup
      if (context.mounted) {
        _showAuthenticationDialog(context);
      }
    }
  }

  void _showAuthenticationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AuthenticationPopup(),
    );
  }

  Widget _buildDebugOverlay(UsageGateService usageGate) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${usageGate.getRemainingActions()}',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildAuthOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.lock, color: Colors.white, size: 48),
      ),
    );
  }
}

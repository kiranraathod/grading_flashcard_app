import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/config.dart';
import '../services/guest_session_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/usage_gate_service.dart';
import '../widgets/authentication_popup.dart';

/// Debug panel for testing authentication features
/// 
/// Provides easy controls for feature flags and testing different scenarios.
/// Only available in debug builds for development testing.
class AuthDebugPanel extends StatefulWidget {
  const AuthDebugPanel({super.key});

  @override
  State<AuthDebugPanel> createState() => _AuthDebugPanelState();
}

class _AuthDebugPanelState extends State<AuthDebugPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<GuestSessionService, SupabaseAuthService, UsageGateService>(
      builder: (context, guestSession, authService, usageGate, child) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Authentication Debug Panel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Feature flag controls
                  Text('Feature Flags', style: Theme.of(context).textTheme.titleSmall),
                  SwitchListTile(
                    title: Text('Enable Usage Limits', style: TextStyle(fontSize: 12)),
                    value: AppConfig.enableUsageLimits,
                    onChanged: (value) {
                      setState(() {
                        AppConfig.enableUsageLimits = value;
                      });
                    },
                    dense: true,
                  ),
                  SwitchListTile(
                    title: Text('Enforce Authentication', style: TextStyle(fontSize: 12)),
                    value: AppConfig.enforceAuthentication,
                    onChanged: (value) {
                      setState(() {
                        AppConfig.enforceAuthentication = value;
                      });
                    },
                    dense: true,
                  ),
                  
                  const SizedBox(height: 16),
                  Text('Current Status', style: Theme.of(context).textTheme.titleSmall),
                  
                  _buildStatusRow('Guest Session ID', _truncateId(guestSession.currentSessionId ?? 'None')),
                  _buildStatusRow('Usage Count', '${guestSession.usageCount}/${AppConfig.guestUsageLimit}'),
                  _buildStatusRow('Authenticated', authService.isAuthenticated ? 'Yes' : 'No'),
                  _buildStatusRow('User Email', authService.userEmail ?? 'None'),
                  
                  const SizedBox(height: 16),
                  Text('Actions', style: Theme.of(context).textTheme.titleSmall),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => guestSession.resetSession(),
                        child: const Text('Reset Session'),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => _simulateUsage(guestSession),
                        child: const Text('Simulate Usage'),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: _forceAuthPopup,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Force Auth Popup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 8)}...';
    }
    return id;
  }

  void _simulateUsage(GuestSessionService guestSession) async {
    await guestSession.trackUsage(actionType: 'debug_simulation');
    
    // Check if we should show auth popup after simulation
    if (guestSession.hasReachedLimit) {
      debugPrint('🚨 Usage limit reached after simulation');
      _checkAndShowAuthPopup();
    }
  }

  void _forceAuthPopup() {
    debugPrint('🚨 FORCE: Triggering authentication popup from debug panel');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AuthenticationPopup(),
    );
  }

  void _checkAndShowAuthPopup() {
    final guestSession = context.read<GuestSessionService>();
    final authService = context.read<SupabaseAuthService>();
    
    if (guestSession.hasReachedLimit && 
        !authService.isAuthenticated &&
        AppConfig.enableUsageLimits && 
        AppConfig.enforceAuthentication) {
      
      debugPrint('🚨 Auto-triggering auth popup due to usage limit');
      
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _forceAuthPopup();
        }
      });
    }
  }
}

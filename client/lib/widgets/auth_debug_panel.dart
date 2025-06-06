import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/config.dart';
import '../services/guest_session_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/usage_gate_service.dart';

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
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Authentication Debug Panel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // Feature flag controls
                _buildSectionTitle('Feature Flags'),                _buildSwitchRow(
                  'Enable Usage Limits',
                  AppConfig.enableUsageLimits,
                  (value) {
                    setState(() {
                      AppConfig.enableUsageLimits = value;
                    });
                  },
                ),
                _buildSwitchRow(
                  'Enforce Authentication',
                  AppConfig.enforceAuthentication,
                  (value) {
                    setState(() {
                      AppConfig.enforceAuthentication = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Current Status'),
                _buildStatusRow('Guest Session ID', guestSession.currentSessionId ?? 'None'),
                _buildStatusRow('Usage Count', '${guestSession.usageCount}/${AppConfig.guestUsageLimit}'),
                _buildStatusRow('Authenticated', authService.isAuthenticated ? 'Yes' : 'No'),
                _buildStatusRow('User Email', authService.userEmail ?? 'None'),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Actions'),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => guestSession.resetSession(),
                      child: const Text('Reset Session'),
                    ),
                    ElevatedButton(
                      onPressed: () => _simulateUsage(guestSession),
                      child: const Text('Simulate Usage'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _simulateUsage(GuestSessionService guestSession) {
    guestSession.trackUsage(actionType: 'debug_simulation');
  }
}

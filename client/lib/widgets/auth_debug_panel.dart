// Authentication Debug Panel
// File: client/lib/widgets/auth_debug_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../services/guest_user_manager.dart';
import '../services/supabase_service.dart';
import '../utils/config.dart';

class AuthDebugPanel extends StatefulWidget {
  const AuthDebugPanel({super.key});

  @override
  State<AuthDebugPanel> createState() => _AuthDebugPanelState();
}

class _AuthDebugPanelState extends State<AuthDebugPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthenticationService, GuestUserManager>(
      builder: (context, authService, guestManager, child) {
        final isAuthenticated = authService.isAuthenticated;
        final currentUser = authService.currentUser;
        final guestSessionId = guestManager.currentSessionId;
        final usageCount = guestManager.currentUsageCount;
        final maxActions =
            isAuthenticated
                ? AuthConfig.authenticatedMaxGradingActions
                : AuthConfig.guestMaxGradingActions;
        final remainingActions = maxActions - usageCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Debug Toggle Button (replaces "3 actions remaining today")
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded ? Icons.bug_report : Icons.developer_mode,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isExpanded
                          ? 'Debug Panel'
                          : '$remainingActions actions remaining today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Debug Panel Content
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authentication Debug Panel',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Feature Flags Section
                    _buildSection(context, 'Feature Flags', [
                      _buildStatusRow(
                        context,
                        'Enable Usage Limits',
                        AuthConfig.enableUsageLimits,
                      ),
                      _buildStatusRow(
                        context,
                        'Enforce Authentication',
                        AuthConfig.enableAuthentication,
                      ),
                      _buildStatusRow(
                        context,
                        'Guest Tracking',
                        AuthConfig.enableGuestTracking,
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Current Status Section
                    _buildSection(context, 'Current Status', [
                      _buildInfoRow(
                        context,
                        'Guest Session ID',
                        guestSessionId?.substring(0, 8) ?? 'None',
                      ),
                      _buildInfoRow(
                        context,
                        'Usage Count',
                        '$usageCount/$maxActions',
                      ),
                      _buildInfoRow(
                        context,
                        'Authenticated',
                        isAuthenticated ? 'Yes' : 'No',
                      ),
                      if (isAuthenticated)
                        _buildInfoRow(
                          context,
                          'User Email',
                          currentUser?.email ?? 'None',
                        ),
                    ]),

                    const SizedBox(height: 16),

                    // Service Status Section
                    _buildSection(context, 'Service Status', [
                      _buildStatusRow(
                        context,
                        'Supabase Service',
                        context.read<SupabaseService>().isInitialized,
                      ),
                      _buildStatusRow(
                        context,
                        'Auth Service',
                        authService.isInitialized,
                      ),
                      _buildStatusRow(
                        context,
                        'Guest Manager',
                        guestManager.isInitialized,
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              guestManager.resetSession();
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              guestManager.simulateUsage();
                              setState(() {});
                            },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Simulate Usage'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.tertiary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Additional Debug Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Information',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Session: ${guestSessionId ?? "Not initialized"}\n'
                            'Actions Used: $usageCount\n'
                            'Max Actions: $maxActions\n'
                            'Remaining: $remainingActions\n'
                            'Auth State: ${authService.currentAuthState}\n'
                            'User ID: ${currentUser?.id ?? "None"}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            size: 16,
            color:
                status
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:
                  status
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'ON' : 'OFF',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    status
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

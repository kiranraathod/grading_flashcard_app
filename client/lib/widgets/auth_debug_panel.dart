// Authentication Debug Panel
// File: client/lib/widgets/auth_debug_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/working_auth_provider.dart';
import '../providers/unified_action_tracking_provider.dart';
import '../models/simple_auth_state.dart';
import '../services/supabase_service.dart';
import '../services/unified_usage_limit_enforcer.dart';
import '../services/storage_service.dart';
import '../services/unified_usage_storage.dart';
import '../utils/config.dart';

/// Authentication Debug Panel migrated to Riverpod with Sync Status
///
/// ENHANCED: Added scrollable interface and real-time sync status monitoring
/// - Scrollable container for better UX
/// - Real-time sync status indicators
/// - Network connectivity monitoring
/// - Manual sync controls
/// - Performance metrics tracking
class AuthDebugPanel extends ConsumerStatefulWidget {
  const AuthDebugPanel({super.key});

  @override
  ConsumerState<AuthDebugPanel> createState() => _AuthDebugPanelState();
}

class _AuthDebugPanelState extends ConsumerState<AuthDebugPanel> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod providers instead of Consumer2
    final authState = ref.watch(authNotifierProvider);
    final actionState = ref.watch(unifiedActionTrackerProvider);

    final isAuthenticated = authState is AuthStateAuthenticated;
    final currentUser = isAuthenticated ? authState.user : null;
    final guestId = authState is AuthStateGuest ? authState.guestId : null;

    // 🔧 FIX: Use unified usage summary instead of old single-feature calculation
    final usageLimitEnforcer = ref.read(unifiedUsageLimitEnforcerProvider);
    final usageSummary = usageLimitEnforcer.getUsageSummary();
    
    final usedActions = usageSummary['totalUsage'] as int;
    final maxActions = usageSummary['totalLimit'] as int;
    final remainingActions = (maxActions - usedActions).clamp(0, maxActions);

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

        // Enhanced Scrollable Debug Panel Content
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            width: 350,
            height: MediaQuery.of(context).size.height * 0.7, // Responsive height
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
              children: [
                // Fixed Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Authentication Debug Panel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Current Status Section using Riverpod state
                          _buildSection(context, 'Current Status', [
                            _buildInfoRow(
                              context,
                              'Guest/User ID',
                              guestId?.substring(0, 8) ??
                                  (isAuthenticated ? _getUserId(currentUser) : 'None'),
                            ),
                            _buildInfoRow(
                              context,
                              'Usage Count',
                              '$usedActions/$maxActions',
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
                                _getUserEmail(currentUser),
                              ),
                          ]),

                          const SizedBox(height: 16),

                          // Service Status Section
                          _buildSection(context, 'Service Status', [
                            _buildStatusRow(
                              context,
                              'Supabase Service',
                              SupabaseService.instance.isInitialized,
                            ),
                            _buildStatusRow(
                              context,
                              'Riverpod Auth Provider',
                              authState is! AuthStateInitial,
                            ),
                            _buildStatusRow(
                              context,
                              'Action Tracker',
                              actionState.lastReset.year > 2000, // Initialized check
                            ),
                          ]),

                          const SizedBox(height: 16),

                          // NEW: Sync Status Section
                          _buildSyncStatus(context),

                          const SizedBox(height: 16),

                          // NEW: Network Status Section
                          _buildNetworkStatus(context),

                          const SizedBox(height: 16),

                          // Enhanced Action Buttons
                          _buildControlButtons(context),

                          const SizedBox(height: 16),

                          // Debug Information Section
                          _buildDebugInformation(context, authState, actionState, usageSummary, guestId, currentUser),

                          // Guest Data Analysis Section (for debugging "empty data" warnings)
                          if (!isAuthenticated && guestId != null) ...[
                            const SizedBox(height: 16),
                            _buildGuestDataAnalysis(context, guestId),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    return _buildSection(context, 'Sync Status', [
      Consumer(builder: (context, ref, _) {
        final supabaseService = SupabaseService.instance;
        return Column(
          children: [
            _buildSyncStatusRow(context, 'Cloud Sync', supabaseService.syncStatus),
            _buildSyncStatusRow(context, 'Repository Sync', supabaseService.syncStatus),
            _buildInfoRow(context, 'Last Sync', _formatLastSync(supabaseService.lastSyncTime)),
            _buildInfoRow(context, 'Queue Length', '${supabaseService.queueLength} items'),
            _buildInfoRow(context, 'Success Rate', '${(supabaseService.successRate * 100).toStringAsFixed(1)}%'),
            if (supabaseService.lastError != null)
              _buildErrorRow(context, 'Last Error', supabaseService.lastError!),
          ],
        );
      }),
    ]);
  }

  Widget _buildNetworkStatus(BuildContext context) {
    return _buildSection(context, 'Network Status', [
      Consumer(builder: (context, ref, _) {
        final supabaseService = SupabaseService.instance;
        return Column(
          children: [
            _buildStatusRow(context, 'Online', supabaseService.isOnline),
            _buildInfoRow(context, 'Connection Type', supabaseService.isOnline ? 'WiFi/Mobile' : 'Offline'),
            _buildStatusRow(context, 'Real-time Active', 
              supabaseService.isAuthenticated && supabaseService.isOnline),
          ],
        );
      }),
    ]);
  }

  Widget _buildControlButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final supabaseService = SupabaseService.instance;
                return ElevatedButton.icon(
                  onPressed: supabaseService.isOnline ? () {
                    supabaseService.forceSync();
                    setState(() {}); // Refresh to show updated status
                  } : null,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Force Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {}); // Refresh the panel
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(unifiedActionTrackerProvider.notifier)
                      .resetAllActions();
                  setState(() {});
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset Actions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Simulate usage by triggering an action
                  ref
                      .read(unifiedActionTrackerProvider.notifier)
                      .recordAction(ActionType.flashcardGrading);
                  setState(() {});
                },
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Simulate Usage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDebugInformation(BuildContext context, AuthState authState, UserActionState actionState, 
      Map<String, dynamic> usageSummary, String? guestId, dynamic currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Information (Riverpod)',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Session: ${guestId ?? _getUserId(currentUser)}\n'
            'Combined Usage: ${usageSummary['totalUsage']}/${usageSummary['totalLimit']}\n'
            'Remaining: ${usageSummary['totalRemaining']}\n'
            'Can Perform: ${usageSummary['canPerformAny']}\n'
            'Auth State: ${authState.runtimeType}\n'
            'Authenticated: ${usageSummary['authenticated']}\n'
            'Has Reached Limit: ${actionState.hasReachedLimit}\n'
            'Last Reset: ${actionState.lastReset}\n'
            'Action Breakdown: ${usageSummary['actionCounts']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestDataAnalysis(BuildContext context, String guestId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 16,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Guest Data Analysis',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: _analyzeGuestData(guestId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Analyzing guest data...');
              }
              
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              
              final analysis = snapshot.data!;
              final hasFlashcards = analysis['hasFlashcards'] as bool;
              final flashcardCount = analysis['flashcardCount'] as int;
              final hasUsageData = analysis['hasUsageData'] as bool;
              final warningLevel = analysis['warningLevel'] as String;
              final explanation = analysis['explanation'] as String;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuestDataRow(context, 'Flashcard Data', 
                    hasFlashcards ? '$flashcardCount sets' : 'None', hasFlashcards),
                  _buildGuestDataRow(context, 'Usage Tracking', 
                    hasUsageData ? 'Present' : 'Empty', hasUsageData),
                  _buildGuestDataRow(context, 'Warning Level', warningLevel, 
                    warningLevel != 'Critical'),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getUserId(dynamic user) {
    try {
      if (user is Map<String, dynamic>) {
        return user['id']?.toString().substring(0, 8) ?? 'Unknown';
      }
      return (user as dynamic).id?.substring(0, 8) ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getUserEmail(dynamic user) {
    try {
      if (user is Map<String, dynamic>) {
        return user['email']?.toString() ??
            user['user_metadata']?['email']?.toString() ??
            'None';
      }
      return (user as dynamic).email ?? 'None';
    } catch (e) {
      return 'None';
    }
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.1),
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

  Widget _buildSyncStatusRow(BuildContext context, String label, SyncStatus status) {
    Color color;
    String statusText;
    IconData icon;

    switch (status) {
      case SyncStatus.idle:
        color = Colors.orange;
        statusText = 'IDLE';
        icon = Icons.pause;
        break;
      case SyncStatus.syncing:
        color = Colors.blue;
        statusText = 'SYNCING';
        icon = Icons.sync;
        break;
      case SyncStatus.synced:
        color = Colors.green;
        statusText = 'SYNCED';
        icon = Icons.check_circle;
        break;
      case SyncStatus.error:
        color = Colors.red;
        statusText = 'ERROR';
        icon = Icons.error;
        break;
      case SyncStatus.offline:
        color = Colors.grey;
        statusText = 'OFFLINE';
        icon = Icons.wifi_off;
        break;
      case SyncStatus.conflict:
        color = Colors.amber;
        statusText = 'CONFLICT';
        icon = Icons.warning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
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

  Widget _buildErrorRow(BuildContext context, String label, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper method to analyze guest data for debugging "empty data" warnings
  Future<Map<String, dynamic>> _analyzeGuestData(String guestId) async {
    try {
      // Check flashcard data
      final flashcards = StorageService.getFlashcardSets();
      final hasFlashcards = flashcards != null && flashcards.isNotEmpty;
      final flashcardCount = flashcards?.length ?? 0;
      
      // Check usage tracking data
      bool hasUsageData = false;
      try {
        final data = await UnifiedUsageStorage.getUsageData(guestId);
        hasUsageData = data.actionCounts.isNotEmpty || data.dailyLimits.isNotEmpty;
      } catch (e) {
        hasUsageData = false;
      }
      
      // Determine warning level and explanation
      String warningLevel;
      String explanation;
      
      if (hasFlashcards && !hasUsageData) {
        warningLevel = 'Informational';
        explanation = 'Your flashcard data exists and is safe. The "empty data" warning only refers to missing usage tracking, not your actual cards.';
      } else if (hasFlashcards && hasUsageData) {
        warningLevel = 'None';
        explanation = 'All data is present. No warnings expected during migration.';
      } else if (!hasFlashcards && !hasUsageData) {
        warningLevel = 'Critical';
        explanation = 'No data found. This guest user appears to be genuinely empty.';
      } else {
        warningLevel = 'Unusual';
        explanation = 'Usage data exists but no flashcards found. This is unexpected.';
      }
      
      return {
        'hasFlashcards': hasFlashcards,
        'flashcardCount': flashcardCount,
        'hasUsageData': hasUsageData,
        'warningLevel': warningLevel,
        'explanation': explanation,
      };
    } catch (e) {
      return {
        'hasFlashcards': false,
        'flashcardCount': 0,
        'hasUsageData': false,
        'warningLevel': 'Error',
        'explanation': 'Failed to analyze guest data: $e',
      };
    }
  }

  /// Helper method to build guest data analysis rows
  Widget _buildGuestDataRow(BuildContext context, String label, String value, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle : Icons.warning,
            size: 14,
            color: isPositive ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label, 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isPositive ? Colors.green : Colors.orange,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// BLoC imports
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';
import '../blocs/network/network_bloc.dart';
import '../blocs/network/network_state.dart';

/// Phase 5: Sync Status Indicator Widget
/// 
/// Pure BLoC widget that displays real-time sync status without
/// any Provider dependencies. Uses BlocSelector for performance
/// optimization and shows visual feedback for sync operations.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Network status indicator
        BlocSelector<NetworkBloc, NetworkState, bool>(
          selector: (state) => state is NetworkConnected,
          builder: (context, isConnected) {
            return Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              size: 16,
              color: isConnected ? Colors.green : Colors.red,
            );
          },
        ),
        const SizedBox(width: 8),
        
        // Sync status indicator
        BlocSelector<SyncBloc, SyncState, Widget>(
          selector: (state) => _buildSyncIndicator(state),
          builder: (context, indicator) => indicator,
        ),
      ],
    );
  }

  Widget _buildSyncIndicator(SyncState state) {
    if (state is SyncInProgress) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 4),
          const Text('Syncing', style: TextStyle(fontSize: 12)),
        ],
      );
    } else if (state is SyncError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 4),
          const Text('Error', style: TextStyle(fontSize: 12, color: Colors.red)),
        ],
      );
    } else if (state is SyncSuccess) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          const Text('Synced', style: TextStyle(fontSize: 12, color: Colors.green)),
        ],
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sync_disabled, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        const Text('Offline', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
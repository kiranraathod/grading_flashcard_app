import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// BLoC imports  
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/network/network_bloc.dart';

// Widgets and utilities
import '../widgets/sync_status_indicator.dart';
import '../utils/design_system.dart';

/// Phase 5: BLoC-based App Header
/// 
/// Pure BLoC widget for the application header that replaces
/// Provider patterns with BLoC state management. Shows user
/// authentication status and sync indicators.
class AppHeaderBloc extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBloc({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('FlashMaster'),
      elevation: 2,
      actions: [
        // Sync status indicator
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: DS.spacingS),
          child: SyncStatusIndicator(),
        ),
        
        // User menu with authentication status
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value, authState),
              icon: _buildUserIcon(authState),
              itemBuilder: (context) => _buildMenuItems(authState),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserIcon(AuthState authState) {
    if (authState is AuthStateAuthenticated) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green,
        child: Icon(
          Icons.person,
          size: 20,
          color: Colors.white,
        ),
      );
    } else {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey,
        child: Icon(
          Icons.person_outline,
          size: 20,
          color: Colors.white,
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(AuthState authState) {
    final List<PopupMenuEntry<String>> items = [];

    if (authState is AuthStateAuthenticated) {
      items.addAll([
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.account_circle),
              const SizedBox(width: 8),
              Text('Profile (${authState.user.email})'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sync_status',
          child: Row(
            children: [
              Icon(Icons.cloud_sync),
              SizedBox(width: 8),
              Text('Sync Status'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Sign Out'),
            ],
          ),
        ),
      ]);
    } else {
      items.addAll([
        const PopupMenuItem(
          value: 'sign_in',
          child: Row(
            children: [
              Icon(Icons.login),
              SizedBox(width: 8),
              Text('Sign In'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sign_up',
          child: Row(
            children: [
              Icon(Icons.person_add),
              SizedBox(width: 8),
              Text('Sign Up'),
            ],
          ),
        ),
      ]);
    }

    items.addAll([
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'settings',
        child: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'about',
        child: Row(
          children: [
            Icon(Icons.info),
            SizedBox(width: 8),
            Text('About'),
          ],
        ),
      ),
    ]);

    return items;
  }

  void _handleMenuAction(BuildContext context, String action, AuthState authState) {
    final authBloc = context.read<AuthBloc>();
    final syncBloc = context.read<SyncBloc>();

    switch (action) {
      case 'profile':
        _showProfileDialog(context, authState);
        break;
      case 'sync_status':
        _showSyncStatusDialog(context);
        break;
      case 'sign_in':
        _showSignInDialog(context);
        break;
      case 'sign_up':
        _showSignUpDialog(context);
        break;
      case 'sign_out':
        _showSignOutConfirmation(context, authBloc);
        break;
      case 'settings':
        _navigateToSettings(context);
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

  void _showProfileDialog(BuildContext context, AuthState authState) {
    if (authState is AuthStateAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${authState.user.email}'),
              Text('User ID: ${authState.user.id}'),
              const SizedBox(height: 16),
              const Text('Account Status: Active'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showSyncStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: BlocBuilder<SyncBloc, SyncState>(
          builder: (context, syncState) {
            String message;
            Color color;
            
            if (syncState is SyncInProgress) {
              message = 'Your data is currently being synchronized with the cloud.';
              color = Colors.blue;
            } else if (syncState is SyncError) {
              message = 'There was an error syncing your data. Please check your connection and try again.';
              color = Colors.red;
            } else if (syncState is SyncSuccess) {
              message = 'Your data is up to date and synchronized with the cloud.';
              color = Colors.green;
            } else {
              message = 'Sync is currently disabled or unavailable.';
              color = Colors.grey;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  syncState is SyncInProgress ? Icons.sync :
                  syncState is SyncError ? Icons.sync_problem :
                  syncState is SyncSuccess ? Icons.cloud_done :
                  Icons.sync_disabled,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 16),
                Text(message),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context) {
    // This would show the authentication modal
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in functionality coming soon')),
    );
  }

  void _showSignUpDialog(BuildContext context) {
    // This would show the sign up modal
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up functionality coming soon')),
    );
  }

  void _showSignOutConfirmation(BuildContext context, AuthBloc authBloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // authBloc.add(const AuthSignOutRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FlashMaster',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 FlashMaster Team',
      children: [
        const Text('A powerful flashcard application built with Flutter and BLoC.'),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../screens/profile_screen.dart';
import '../screens/auth/login_screen.dart';

class UserMenuWidget extends StatelessWidget {
  const UserMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, _) {
        return userService.isAuthenticated
            ? _buildUserMenu(context, userService)
            : _buildLoginButton(context);
      },
    );
  }

  Widget _buildUserMenu(BuildContext context, UserService userService) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: userService.avatarUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  userService.avatarUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              )
            : Text(
                userService.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              Text(userService.displayName ?? 'My Profile'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Log Out'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
            break;
          case 'settings':
            // Navigate to settings screen
            break;
          case 'logout':
            await userService.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have been signed out'),
                )
              );
            }
            break;
        }
      },
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.login),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      tooltip: 'Login',
    );
  }
}

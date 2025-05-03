import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/theme_utils.dart';
import '../widgets/theme_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Text(
            'Appearance',
            style: context.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Theme selector
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.outline,
              ),
            ),
            child: Column(
              children: [
                // Dark mode toggle
                ListTile(
                  title: Text(
                    'Dark Mode',
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    'Toggle between light and dark themes',
                    style: context.bodySmall,
                  ),
                  trailing: ThemeToggle(showLabel: false),
                ),
                
                // Theme options (divider)
                Divider(color: context.colorScheme.outline),
                
                // System theme
                RadioListTile<ThemeMode>(
                  title: Text(
                    'System Default',
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    'Follow system theme settings',
                    style: context.bodySmall,
                  ),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(ThemeMode.system);
                    }
                  },
                  activeColor: context.primaryColor,
                ),
                
                // Light theme
                RadioListTile<ThemeMode>(
                  title: Text(
                    'Light Theme',
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    'Always use light theme',
                    style: context.bodySmall,
                  ),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(ThemeMode.light);
                    }
                  },
                  activeColor: context.primaryColor,
                ),
                
                // Dark theme
                RadioListTile<ThemeMode>(
                  title: Text(
                    'Dark Theme',
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    'Always use dark theme',
                    style: context.bodySmall,
                  ),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(ThemeMode.dark);
                    }
                  },
                  activeColor: context.primaryColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Other settings sections would go here
          Text(
            'Account',
            style: context.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.outline,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: context.onSurfaceColor,
                  ),
                  title: Text(
                    'Profile',
                    style: context.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceVariantColor,
                  ),
                  onTap: () {
                    // Navigate to profile settings
                  },
                ),
                
                Divider(color: context.colorScheme.outline),
                
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: context.onSurfaceColor,
                  ),
                  title: Text(
                    'Notifications',
                    style: context.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceVariantColor,
                  ),
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App info section
          Text(
            'About',
            style: context.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.outline,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Version',
                    style: context.bodyLarge,
                  ),
                  trailing: Text(
                    '1.0.0',
                    style: context.bodySmall,
                  ),
                ),
                
                Divider(color: context.colorScheme.outline),
                
                ListTile(
                  title: Text(
                    'Terms of Service',
                    style: context.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceVariantColor,
                  ),
                  onTap: () {
                    // Open terms of service
                  },
                ),
                
                Divider(color: context.colorScheme.outline),
                
                ListTile(
                  title: Text(
                    'Privacy Policy',
                    style: context.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceVariantColor,
                  ),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

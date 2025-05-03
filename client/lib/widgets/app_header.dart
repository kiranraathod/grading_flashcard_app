import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';
import '../screens/settings_screen.dart';
import '../widgets/theme_toggle.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo/Brand
          Row(
            children: [
              Icon(
                Icons.book_outlined,
                color: context.primaryColor,
                size: 20
              ),
              const SizedBox(width: 8),
              Text(
                'FlashMaster',
                style: context.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.onSurfaceColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Search bar
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.isDarkMode 
                    ? const Color(0xFF2C2C2E).withValues(red: 44.0, green: 44.0, blue: 46.0, alpha: 204.0)  // Semi-transparent for better depth
                    : context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.isDarkMode 
                      ? Colors.white.withValues(red: 255.0, green: 255.0, blue: 255.0, alpha: 25.0)
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.isDarkMode 
                        ? Colors.white.withValues(red: 255.0, green: 255.0, blue: 255.0, alpha: 178.0)
                        : context.onSurfaceVariantColor,
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        color: context.onSurfaceColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Find flashcards on any topic',
                        hintStyle: TextStyle(
                          color: context.isDarkMode 
                              ? Colors.white.withValues(red: 255.0, green: 255.0, blue: 255.0, alpha: 102.0)
                              : context.onSurfaceVariantColor,
                          fontSize: 14
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Action buttons
          Row(
            children: [
              // Achievements
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: context.onSurfaceVariantColor,
                  size: 20
                ),
                tooltip: 'Achievements',
              ),
              
              const SizedBox(width: 8),
              
              // Dark mode toggle - This is the fix for the missing dark icon
              const ThemeToggleButton(),
              
              const SizedBox(width: 8),
              
              // Settings
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: Icon(
                  Icons.settings_outlined,
                  color: context.onSurfaceVariantColor,
                  size: 20
                ),
                tooltip: 'Settings',
              ),
              
              const SizedBox(width: 16),
              
              // Profile dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                icon: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: context.primaryColor,
                      child: Icon(
                        Icons.person,
                        color: context.onPrimaryColor,
                        size: 16
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: context.onSurfaceVariantColor,
                      size: 14
                    ),
                  ],
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 8),
                        const Text('Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      break;
                    case 'logout':
                      // Handle logout
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

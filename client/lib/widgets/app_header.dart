import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/theme_utils.dart';
import '../screens/settings_screen.dart';
import '../widgets/theme_toggle.dart';
import '../screens/search/search_results_screen.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});
  
  // Public method to focus the search field
  void focusSearch(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppHeaderState>();
    state?._searchFocusNode.requestFocus();
  }

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  // Helper method to navigate to search results
  void _navigateToSearchResults(BuildContext context, String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialQuery: query,
        ),
      ),
    );
  }
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).appTitle,
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
                    ? const Color(0xFF2C2C2E)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: InkWell(
                onTap: () {
                  _searchFocusNode.requestFocus();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: context.isDarkMode 
                          ? Colors.white.withValues(alpha: 0.7)
                          : context.onSurfaceVariantColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: context.isDarkMode 
                                ? Colors.white.withValues(alpha: 0.5)
                                : context.onSurfaceVariantColor,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: context.onSurfaceVariantColor,
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                },
                              )
                            : null,
                        ),
                        onChanged: (value) {
                          // Force update to show/hide clear button
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _navigateToSearchResults(context, value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
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
                  size: 20,
                ),
                tooltip: 'Achievements',
              ),
              
              const SizedBox(width: 8),
              
              // Dark mode toggle - This is the fix for the missing dark icon
              const ThemeToggleButton(),
              
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
                        size: 16,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: context.onSurfaceVariantColor,
                      size: 14,
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
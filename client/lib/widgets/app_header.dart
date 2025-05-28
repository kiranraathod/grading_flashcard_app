import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
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
      height: DS.buttonHeightXl,
      padding: const EdgeInsets.symmetric(horizontal: DS.spacingM),
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
                size: DS.iconSizeS,
              ),
              const SizedBox(width: DS.spacingXs),
              Text(
                AppLocalizations.of(context).appTitle,
                style: context.titleLarge?.copyWith(
                  fontSize: DS.isSmallScreen(context) ? 16 : 18,
                  fontWeight: FontWeight.w500,
                  color: context.onSurfaceColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: DS.spacingL),
          
          // Search bar
          Expanded(
            child: Container(
              height: DS.inputHeightL - 12, // 36px total
              padding: const EdgeInsets.symmetric(horizontal: DS.spacingS),
              decoration: BoxDecoration(
                color: context.isDarkMode 
                    ? context.surfaceVariantColor
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DS.borderRadiusFull),
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
                      color: context.onSurfaceVariantColor,
                      size: DS.iconSizeXs + 2, // 18px total
                    ),
                    const SizedBox(width: DS.spacingXs),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).search,
                          hintStyle: TextStyle(
                            color: context.onSurfaceVariantColor,
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
                                  size: DS.iconSizeXs,
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
          
          const SizedBox(width: DS.spacingL),
          
          // Action buttons
          Row(
            children: [
              // Dark mode toggle - This is the fix for the missing dark icon
              const ThemeToggleButton(),
              
              const SizedBox(width: DS.spacingM),
              
              // Profile dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, DS.avatarSizeM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                ),
                icon: Row(
                  children: [
                    CircleAvatar(
                      radius: DS.avatarSizeXs * 0.58, // ~14px radius
                      backgroundColor: context.primaryColor,
                      child: Icon(
                        Icons.person,
                        color: context.onPrimaryColor,
                        size: DS.iconSizeXs,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: context.onSurfaceVariantColor,
                      size: DS.iconSizeXs - 2, // 14px total
                    ),
                  ],
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: DS.iconSizeXs + 2), // 18px total
                        const SizedBox(width: DS.spacingXs),
                        Text(AppLocalizations.of(context).profile),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: DS.iconSizeXs + 2), // 18px total
                        const SizedBox(width: DS.spacingXs),
                        Text(AppLocalizations.of(context).settings),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_outlined, size: DS.iconSizeXs + 2), // 18px total
                        const SizedBox(width: DS.spacingXs),
                        Text(AppLocalizations.of(context).logout),
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
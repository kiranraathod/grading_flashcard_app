import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/theme_provider.dart';
import '../screens/settings_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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
          // Logo/Brand Section
          if (!DS.isExtraSmallScreen(context))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_outlined,
                  color: context.primaryColor,
                  size: DS.iconSizeS,
                ),
                SizedBox(width: DS.spacingXs),
                Text(
                  AppLocalizations.of(context).appTitle,
                  style: context.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.onSurfaceColor,
                  ),
                ),
              ],
            ),
          
          // Spacing after logo
          if (!DS.isExtraSmallScreen(context))
            const SizedBox(width: DS.spacingM)
          else
            const SizedBox(width: DS.spacing2xs),
          
          // Search Bar
          Expanded(
            child: Container(
              height: 36,
              constraints: BoxConstraints(
                minWidth: DS.isExtraSmallScreen(context) ? 150 : 200,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: DS.isExtraSmallScreen(context) ? 6 : DS.spacingS,
              ),
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
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.onSurfaceVariantColor,
                    size: DS.isExtraSmallScreen(context) ? 14 : 16,
                  ),
                  SizedBox(width: DS.isExtraSmallScreen(context) ? 4 : DS.spacingXs),
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
                                setState(() {});
                              },
                            )
                          : null,
                      ),
                      onChanged: (value) {
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
          
          // Spacing before actions
          SizedBox(width: DS.isExtraSmallScreen(context) ? 8 : DS.spacingM),
          
          // Action buttons with perfect alignment
          _buildActionButtons(context, themeProvider),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeProvider themeProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme Toggle Button
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: themeProvider.isDarkMode 
                  ? Colors.white 
                  : context.onSurfaceColor,
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                key: ValueKey<bool>(themeProvider.isDarkMode),
                size: 20,
              ),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.isDarkMode
                ? AppLocalizations.of(context).switchToLightMode
                : AppLocalizations.of(context).switchToDarkMode,
          ),
        ),
        
        const SizedBox(width: 8), // Space between buttons
        
        // Profile Menu Button  
        SizedBox(
          width: 40,
          height: 40,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: context.primaryColor,
                child: Icon(
                  Icons.person,
                  color: context.onPrimaryColor,
                  size: 18,
                ),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).profile),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).settings),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, size: 18),
                    const SizedBox(width: 8),
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
        ),
      ],
    );
  }
}

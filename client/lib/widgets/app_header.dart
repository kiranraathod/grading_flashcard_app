import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/theme_provider.dart';
import '../utils/config.dart';
import '../screens/settings_screen.dart';
import '../screens/search/search_results_screen.dart';
import '../services/authentication_service.dart';
import '../services/guest_user_manager.dart';
import 'auth/authentication_modal.dart';

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
        
        // Profile Menu Button with Authentication Enhancement
        SizedBox(
          width: 40,
          height: 40,
          child: Consumer2<AuthenticationService, GuestUserManager>(
            builder: (context, authService, guestManager, child) {
              return PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: _buildProfileAvatar(context, authService),
                ),
                itemBuilder: (_) => _buildMenuItems(context, authService, guestManager),
                onSelected: (value) => _handleMenuSelection(value, context, authService),
              );
            },
          ),
        ),
      ],
    );
  }
}

  /// Build profile avatar with authentication status indication
  Widget _buildProfileAvatar(BuildContext context, AuthenticationService authService) {
    final isAuthenticated = AuthConfig.enableAuthentication && authService.isAuthenticated;
    
    return Stack(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isAuthenticated 
            ? Colors.green 
            : context.primaryColor,
          child: Icon(
            Icons.person,
            color: context.onPrimaryColor,
            size: 18,
          ),
        ),
        // Authentication status indicator
        if (AuthConfig.enableAuthentication && isAuthenticated)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build menu items based on authentication state
  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context, 
    AuthenticationService authService, 
    GuestUserManager guestManager,
  ) {
    final items = <PopupMenuEntry<String>>[];
    
    // Usage tracking info (if enabled)
    if (AuthConfig.enableUsageLimits && !authService.isAuthenticated) {
      final usageMessage = guestManager.getUsageMessage();
      if (usageMessage.isNotEmpty) {
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                usageMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
        items.add(const PopupMenuDivider());
      }
    }
    
    // Authentication-based menu items
    if (AuthConfig.enableAuthentication) {
      if (authService.isAuthenticated) {
        // Authenticated user menu
        items.addAll([
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Text(authService.currentUser?.email ?? 'Profile'),
              ],
            ),
          ),
        ]);
      } else {
        // Guest user menu
        items.addAll([
          PopupMenuItem(
            value: 'sign_in',
            child: Row(
              children: [
                const Icon(Icons.login_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Sign In'),
              ],
            ),
          ),
        ]);
      }
      items.add(const PopupMenuDivider());
    }
    
    // Always present menu items
    items.addAll([
      PopupMenuItem(
        value: 'settings',
        child: Row(
          children: [
            const Icon(Icons.settings_outlined, size: 18),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).settings),
          ],
        ),
      ),
    ]);
    
    // Sign out option for authenticated users
    if (AuthConfig.enableAuthentication && authService.isAuthenticated) {
      items.addAll([
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_outlined, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).logout),
            ],
          ),
        ),
      ]);
    }
    
    return items;
  }
  /// Handle menu item selection
  void _handleMenuSelection(String value, BuildContext context, AuthenticationService authService) {
    switch (value) {
      case 'sign_in':
        if (AuthConfig.enableAuthentication) {
          AuthenticationModal.show(context);
        }
        break;
        
      case 'profile':
        // Handle profile navigation
        debugPrint('Profile selected');
        break;
        
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
        
      case 'logout':
        if (AuthConfig.enableAuthentication) {
          _handleSignOut(context, authService);
        }
        break;
    }
  }
  
  /// Handle user sign out
  Future<void> _handleSignOut(BuildContext context, AuthenticationService authService) async {
    // Store ScaffoldMessenger reference before async call to avoid BuildContext across async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final success = await authService.signOut();
    
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Successfully signed out'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

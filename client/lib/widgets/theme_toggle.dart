import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/colors.dart';

class ThemeToggle extends StatelessWidget {
  final bool showLabel;

  const ThemeToggle({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Text(
            isDarkMode
                ? AppLocalizations.of(context).darkMode
                : AppLocalizations.of(context).lightMode,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label:
              isDarkMode
                  ? AppLocalizations.of(context).switchToLightTheme
                  : AppLocalizations.of(context).switchToDarkTheme,
          child: InkWell(
            onTap: () {
              // Play sound feedback (optional)
              HapticFeedback.lightImpact();

              themeProvider.toggleTheme();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 50,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color:
                    isDarkMode
                        ? AppColors.primaryDark.withValues(
                          red: AppColors.primaryDark.r.toDouble(),
                          green: AppColors.primaryDark.g.toDouble(),
                          blue: AppColors.primaryDark.b.toDouble(),
                          alpha: 102.0,
                        )
                        : AppColors.primary.withValues(
                          red: AppColors.primary.r.toDouble(),
                          green: AppColors.primary.g.toDouble(),
                          blue: AppColors.primary.b.toDouble(),
                          alpha: 102.0,
                        ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutQuart,
                alignment:
                    isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        key: ValueKey<bool>(isDarkMode),
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return RepaintBoundary(
      // Add RepaintBoundary to prevent unnecessary repaints
      child: Semantics(
        button: true,
        label:
            themeProvider.isDarkMode
                ? AppLocalizations.of(context).switchToLightTheme
                : AppLocalizations.of(context).switchToDarkTheme,
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              key: ValueKey<bool>(themeProvider.isDarkMode),
              color:
                  themeProvider.isDarkMode
                      ? Colors.white
                      : AppColors.textPrimary,
            ),
          ),
          onPressed: () {
            // Haptic feedback for better user experience
            HapticFeedback.selectionClick(); // Changed to selection click for subtler feedback

            // Log theme change event (if you have analytics set up)
            _logThemeChange(
              themeProvider.isDarkMode,
              !themeProvider.isDarkMode,
            );

            themeProvider.toggleTheme();
          },
          tooltip:
              themeProvider.isDarkMode
                  ? AppLocalizations.of(context).switchToLightMode
                  : AppLocalizations.of(context).switchToDarkMode,
        ),
      ),
    );
  }

  // Analytics logging - implement this based on your analytics setup
  void _logThemeChange(bool fromDarkMode, bool toDarkMode) {
    // If you're using Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'theme_changed',
    //   parameters: {
    //     'from': fromDarkMode ? 'dark' : 'light',
    //     'to': toDarkMode ? 'dark' : 'light',
    //     'method': 'header_button',
    //   },
    // );

    // If you're using another analytics service, implement accordingly
    debugPrint(
      'Theme changed from ${fromDarkMode ? 'dark' : 'light'} to ${toDarkMode ? 'dark' : 'light'}',
    );
  }
}

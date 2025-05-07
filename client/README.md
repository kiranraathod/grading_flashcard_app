# Flutter Theme Documentation

This directory contains documentation related to the app's theming system and color implementations.

## Overview

The flashcard application uses Flutter's Material 3 theming system to create a consistent and visually appealing user interface. The theme implementation has evolved from using a grey color scheme to a teal color scheme, with proper support for both light and dark modes.

## Theme Documentation Files

| File | Description |
|------|-------------|
| [Grey Theme Implementation](grey_theme_implementation.md) | Details about the grey theme implementation that was previously used in the app |
| [Teal Color Implementation](teal_color_implementation.md) | Comprehensive guide to the Material 3 teal color implementation |
| [Teal Color Implementation Report](teal_color_implementation_report.md) | Report on the changes made to migrate from grey to teal theme |

## Theme System Architecture

The app's theme system consists of several key components:

1. **Color Definitions** (`lib/utils/colors.dart`)
   - Core color constants
   - Helper methods for retrieving colors based on theme mode

2. **Theme Configuration** (`lib/utils/app_themes.dart`)
   - Light and dark theme definitions
   - Component-specific theming

3. **Theme Extensions** (`lib/utils/theme_extensions.dart`)
   - Custom theme properties not covered by Material 3
   - Support for gradients, shadows, and other special styling

4. **Theme Provider** (`lib/utils/theme_provider.dart`)
   - State management for theme switching
   - Theme persistence with SharedPreferences

5. **Theme Utilities** (`lib/utils/theme_utils.dart`)
   - Extension methods for context-based theme property access
   - Helper classes for common styling patterns

## Theme Usage Guidelines

When working with the theme system, follow these best practices:

1. **Use Context Extensions**
   ```dart
   // Preferred approach
   Color primaryColor = context.primaryColor;
   ```

2. **Respect Color Roles**
   ```dart
   // Use semantic color roles
   color: context.colorScheme.primaryContainer,
   foregroundColor: context.colorScheme.onPrimaryContainer,
   ```

3. **Dynamic Theme Support**
   ```dart
   // Handle both light and dark modes
   Color textColor = context.isDarkMode 
       ? AppColors.textPrimaryDark 
       : AppColors.textPrimary;
   ```

4. **Use Themed Components**
   ```dart
   // Use the pre-styled component helpers
   decoration: ThemedComponents.cardDecoration(context),
   ```

## Related Files

Additional files related to theming in the app:

- `lib/utils/design_system.dart` - Design tokens and reusable styles
- `lib/utils/theme.dart` - Legacy theme utilities
- `lib/utils/THEME_GUIDE.md` - Internal documentation about theme usage
- `lib/widgets/theme_toggle.dart` - UI component for switching themes
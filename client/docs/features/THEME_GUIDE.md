# FlashMaster Theme Guide

This guide explains how theming is implemented in the FlashMaster app and provides best practices for maintaining consistent theming across the application.

## Overview

FlashMaster uses a comprehensive theming system that fully supports Material 3 design principles, dynamic color adaptation, and dark mode functionality. The theme system is designed to be maintainable, flexible, and compliant with Flutter best practices.

## Architecture

### Core Components

1. **AppThemes** (`app_themes.dart`): Defines the light and dark themes with Material 3 configuration
2. **AppThemeExtension** (`theme_extensions.dart`): Extends theme functionality with custom properties
3. **ThemeProvider** (`theme_provider.dart`): Manages theme state and persistence
4. **ThemeUtils** (`theme_utils.dart`): Provides convenient extensions for accessing theme properties
5. **DynamicColor**: Supports Android 12+ dynamic color theming

### Color System

All colors are centralized in `colors.dart` with separate variants for light and dark modes:

```dart
// Light mode colors
static const Color primary = Color(0xFF10B981);  // Emerald-600
static const Color secondary = Color(0xFF8B5CF6); // Purple-600

// Dark mode colors  
static const Color primaryDark = Color(0xFF34D399);  // Emerald-400
static const Color secondaryDark = Color(0xFFA78BFA); // Purple-400
```

## Usage Guidelines

### Never Use Hardcoded Colors

❌ **Don't do this:**
```dart
Container(
  color: Colors.grey.shade200,
  child: Text(
    'Example',
    style: TextStyle(color: Colors.grey.shade600),
  ),
)
```

✅ **Do this instead:**
```dart
Container(
  color: context.colorScheme.surfaceVariant,
  child: Text(
    'Example',
    style: context.textTheme.bodyMedium,
  ),
)
```

### Use Theme Extensions for Custom Properties

The app uses `AppThemeExtension` for properties not included in the standard theme:

```dart
// Access gradient colors
final gradient = ThemedGradient.getCardGradient(context);

// Access custom colors
final successColor = context.successColor;
final warningColor = context.warningColor;
```

### Theme-Aware Widgets

Use our custom widgets that automatically adapt to the theme:

```dart
// Themed gradient container
ThemedGradientContainer(
  isInterview: false,
  child: YourContent(),
)
```

### Convenient Theme Extensions

The `theme_utils.dart` file provides convenient extensions:

```dart
// Check theme mode
bool isDark = context.isDarkMode;

// Access theme properties
context.primaryColor
context.surfaceColor
context.backgroundColor
context.errorColor

// Access text styles
context.bodyLarge
context.titleMedium
context.headlineSmall

// Access custom theme properties
context.successColor
context.warningColor
context.cardGradientStart
context.cardGradientEnd
```

## Material 3 Compliance

The app follows Material 3 guidelines:

1. **ColorScheme**: Uses `ColorScheme.fromSeed()` for consistent color generation
2. **Surface Tint**: Applies elevation overlay automatically in dark mode
3. **Typography**: Implements Material 3 type scale with Google Fonts
4. **Components**: Uses Material 3 component theming

## Dark Mode Implementation

### Automatic Adaptation

Widgets automatically adapt to dark mode when using theme properties:

```dart
// This automatically works in both light and dark modes
Text(
  'Hello',
  style: context.bodyLarge,
)
```

### Manual Dark Mode Check

When needed, check the current theme mode:

```dart
if (context.isDarkMode) {
  // Dark mode specific logic
} else {
  // Light mode specific logic
}
```

## Dynamic Color Support

The app supports Android 12+ dynamic color:

```dart
DynamicColorBuilder(
  builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    // App automatically uses dynamic colors when available
  },
)
```

## Best Practices

1. **Always use theme properties** instead of direct colors
2. **Use semantic color names** (e.g., `context.errorColor` instead of `Colors.red`)
3. **Test in both light and dark modes** before committing changes
4. **Use ThemeExtensions** for app-specific properties
5. **Avoid creating new color constants** - add them to `colors.dart` if necessary
6. **Use context extensions** for cleaner code
7. **Respect Material 3 guidelines** for elevation, typography, and spacing

## Adding New Theme Properties

To add new theme properties:

1. Add color constants to `colors.dart`
2. Update `AppThemeExtension` with new properties
3. Update light and dark theme instances
4. Add convenient getters in `theme_utils.dart`

Example:
```dart
// In colors.dart
static const Color newFeature = Color(0xFF...);
static const Color newFeatureDark = Color(0xFF...);

// In theme_extensions.dart
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color? newFeatureColor;
  // ... rest of implementation
}

// In theme_utils.dart
extension ThemeExtensions on BuildContext {
  Color get newFeatureColor => appTheme.newFeatureColor!;
}
```

## Migration from Legacy Code

When migrating old code with hardcoded colors:

1. Identify all hardcoded colors (`Colors.`, `Color(0x`)
2. Replace with appropriate theme properties
3. Test in both light and dark modes
4. Update any custom widgets to use theme extensions

## Testing Theme Implementation

1. **Visual Testing**: Switch between light/dark modes
2. **Dynamic Color**: Test on Android 12+ devices
3. **Widget Testing**: Verify theme properties in tests
4. **Accessibility**: Check color contrast ratios

## Common Pitfalls

1. **Using Colors.transparent**: Sometimes doesn't work as expected in dark mode
2. **Hardcoded opacity**: Use `withOpacity()` on theme colors instead
3. **Direct color comparison**: Theme colors may vary with dynamic theming
4. **Missing dark mode testing**: Always test both modes before releasing

## Resources

- [Material 3 Design Guidelines](https://m3.material.io/)
- [Flutter Theme Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [Dynamic Color Documentation](https://pub.dev/packages/dynamic_color)

## Conclusion

Following this guide ensures a consistent, maintainable, and accessible theme implementation throughout the FlashMaster app. Always prioritize theme properties over hardcoded values and test thoroughly across different theme modes.

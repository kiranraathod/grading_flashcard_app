# Dark Mode Implementation Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Components](#components)
4. [Implementation Steps](#implementation-steps)
5. [Theme Configuration](#theme-configuration)
6. [Usage Guide](#usage-guide)
7. [Best Practices](#best-practices)
8. [Testing](#testing)

## Overview

This document outlines the implementation of Dark Mode in the Flashcard App. The Dark Mode feature provides users with a visually comfortable alternative interface, especially in low-light environments, and follows system-wide preferences.

The implementation provides:
- Light, Dark, and System theme options
- Consistent UI elements across theme modes
- Persistent user preferences
- Accessible theme toggling through multiple UI elements

## Architecture

The Dark Mode implementation follows a provider-based architecture:

1. **Theme Provider**: Central manager for theme state and user preferences
2. **Theme Definitions**: Predefined light and dark themes with corresponding colors
3. **UI Components**: Theme-aware widgets that adapt to the selected theme
4. **Settings Screen**: Dedicated UI for managing theme preferences 

## Components

### ThemeProvider

The `ThemeProvider` class is the central component for managing theme state:

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
                        (_themeMode == ThemeMode.system && 
                         WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  // Methods for loading/saving preferences and toggling themes
  ...
}
```

### Theme Definitions

The `AppThemes` class contains comprehensive theme definitions for both light and dark modes:

```dart
static ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    // Other color definitions
  ),
  // Widget theme definitions
);

static ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryDark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryDark,
    secondary: AppColors.secondaryDark,
    // Other color definitions
  ),
  // Widget theme definitions
);
```

### Color System

The color system has been expanded with dark mode variants:

```dart
// Light mode colors
static const Color primary = Color(0xFF10B981);  
static const Color secondary = Color(0xFF8B5CF6);

// Dark mode versions
static const Color primaryDark = Color(0xFF34D399);  
static const Color secondaryDark = Color(0xFFA78BFA);
```

### Theme Toggle Widgets

Two widgets for toggling the theme:

1. **ThemeToggle**: A switch with optional label
2. **ThemeToggleButton**: An icon-only button for more compact UI areas

### Settings Screen

A dedicated screen for theme preferences with:
- Toggle switch for quick theme switching
- Radio options for Light, Dark, and System themes
- Persistent settings using SharedPreferences

## Implementation Steps

1. **Theme Provider Setup**
   - Create ThemeProvider class
   - Add methods for theme management
   - Implement persistence with SharedPreferences

2. **Theme Definitions**
   - Create light and dark ThemeData objects
   - Define color schemes for both themes
   - Configure widget themes (AppBar, Card, etc.)

3. **Color System Update**
   - Add dark mode variants for all colors
   - Create helper methods for theme-aware color selection

4. **UI Components**
   - Create ThemeToggle widgets
   - Update existing UI components to be theme-aware

5. **Integration**
   - Register ThemeProvider in the widget tree
   - Add theme toggle to app header
   - Create settings screen for theme management
   - Connect theme provider to Material app

## Theme Configuration

### Light Theme

The light theme uses:
- White backgrounds
- Light surface colors
- Green primary color (#10B981)
- Dark text on light backgrounds

### Dark Theme

The dark theme uses:
- Dark backgrounds (#121212, #1E1E1E)
- Dark surface colors with subtle contrast
- Brighter green primary color (#34D399)
- Light text on dark backgrounds

### Dynamic Components

UI components that adapt to themes include:
- Cards and containers
- Text fields and inputs
- Buttons and icons
- List tiles and dividers

## Usage Guide

### Accessing Current Theme

```dart
// In a widget build method
final themeProvider = Provider.of<ThemeProvider>(context);
final isDarkMode = themeProvider.isDarkMode;

// Use theme-aware styling
return Container(
  color: isDarkMode ? Colors.grey[800] : Colors.white,
  child: Text(
    'Hello World',
    style: TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  ),
);
```

### Toggling Theme

```dart
// Toggle between light and dark
themeProvider.toggleTheme();

// Set specific theme mode
themeProvider.setThemeMode(ThemeMode.system);
```

### Theme Toggle Widget

Place the ThemeToggle widget in your UI:

```dart
// Toggle with label
ThemeToggle(showLabel: true)

// Icon-only toggle
ThemeToggleButton()
```

## Best Practices

1. **Use Theme-Aware Colors**
   - Always use `AppColors.getTextPrimary(isDarkMode)` instead of hardcoding colors
   - Access the current theme through Provider.of<ThemeProvider>

2. **Test Both Themes**
   - Regularly check UI components in both light and dark modes
   - Ensure sufficient contrast in both themes

3. **Consistent Spacing**
   - Maintain the same spacing in both themes for consistent user experience

4. **Gradual Transitions**
   - Use animations when switching themes to avoid jarring changes

5. **System Theme Support**
   - Always respect the system theme when the user selects this option

## Testing

Test the dark mode implementation by:

1. Toggling between themes using the ThemeToggle widget
2. Checking system theme integration
3. Verifying theme persistence after app restart
4. Testing all UI components in both light and dark modes
5. Ensuring accessibility requirements are met in both themes

---

This dark mode implementation provides a comprehensive solution that enhances user experience, especially in low-light environments, while maintaining visual consistency across the application.
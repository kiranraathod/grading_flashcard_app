# Context Extensions Documentation

**Complete Guide to ThemeUtils Context Extensions**

## 🎯 Overview

The `theme_utils.dart` file provides powerful context extensions that make accessing theme properties intuitive and efficient. This guide documents all available extensions and their proper usage.

## 🏗️ Core Theme Access Extensions

### Basic Theme Properties
```dart
extension ThemeGetter on BuildContext {
  // Access the complete theme
  ThemeData get theme => Theme.of(this);
  
  // Access the color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  // Access the text theme
  TextTheme get textTheme => theme.textTheme;
}
```

### Usage Examples
```dart
// Get complete theme object
final themeData = context.theme;

// Access color scheme directly
final colorScheme = context.colorScheme;

// Access text theme directly
final textTheme = context.textTheme;
```

## 🎨 Color Access Extensions

### Primary Color Properties
```dart
// Primary brand colors
Color get primaryColor => colorScheme.primary;
Color get onPrimaryColor => colorScheme.onPrimary;

// Secondary brand colors
Color get secondaryColor => colorScheme.secondary;
Color get onSecondaryColor => colorScheme.onSecondary;

// Error colors
Color get errorColor => colorScheme.error;
Color get onErrorColor => colorScheme.onError;
```

### Surface and Background Colors
```dart
// Surface colors for cards and elevated elements
Color get surfaceColor => colorScheme.surface;
Color get onSurfaceColor => colorScheme.onSurface;

// Background colors for screens
Color get backgroundColor => theme.scaffoldBackgroundColor;

// Surface variants for different elevation levels
Color get surfaceVariantColor => colorScheme.surfaceContainerHighest;
Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;

// Outline colors for borders
Color get outlineColor => colorScheme.outline;
```

### Feedback Colors with Dark Mode Support
```dart
// Success colors (teal-based for consistency)
Color get successColor => isDarkMode ? AppColors.successDark : AppColors.success;

// Warning colors
Color get warningColor => isDarkMode ? AppColors.warningDark : AppColors.warning;

// Info colors
Color get infoColor => isDarkMode ? AppColors.infoDark : AppColors.info;

// Shadow colors optimized for theme
Color get shadowColor => isDarkMode 
  ? Colors.black.withValues(alpha: 0.3) 
  : Colors.black.withValues(alpha: 0.1);
```

### Usage Examples
```dart
// Use primary colors
Container(
  color: context.primaryColor,
  child: Text(
    'Primary text',
    style: context.bodyLarge?.copyWith(
      color: context.onPrimaryColor,
    ),
  ),
)

// Use surface colors for cards
Card(
  color: context.surfaceColor,
  child: Text(
    'Card content',
    style: context.bodyMedium?.copyWith(
      color: context.onSurfaceColor,
    ),
  ),
)

// Use feedback colors
Container(
  color: context.successColor,
  child: Icon(Icons.check, color: Colors.white),
)
```

## 📝 Typography Access Extensions

### Material 3 Typography Scale
```dart
// Display styles (largest)
TextStyle? get displayLarge => textTheme.displayLarge;
TextStyle? get displayMedium => textTheme.displayMedium;
TextStyle? get displaySmall => textTheme.displaySmall;

// Headline styles
TextStyle? get headlineLarge => textTheme.headlineLarge;
TextStyle? get headlineMedium => textTheme.headlineMedium;
TextStyle? get headlineSmall => textTheme.headlineSmall;

// Title styles
TextStyle? get titleLarge => textTheme.titleLarge;
TextStyle? get titleMedium => textTheme.titleMedium;
TextStyle? get titleSmall => textTheme.titleSmall;

// Body styles (most common)
TextStyle? get bodyLarge => textTheme.bodyLarge;
TextStyle? get bodyMedium => textTheme.bodyMedium;
TextStyle? get bodySmall => textTheme.bodySmall;

// Label styles (buttons, captions)
TextStyle? get labelLarge => textTheme.labelLarge;
TextStyle? get labelMedium => textTheme.labelMedium;
TextStyle? get labelSmall => textTheme.labelSmall;
```

### Typography Usage Patterns
```dart
// Page titles
Text('Page Title', style: context.headlineLarge);

// Section headers
Text('Section Header', style: context.headlineMedium);

// Subsection titles
Text('Subsection', style: context.titleLarge);

// Primary content
Text('Main content goes here', style: context.bodyLarge);

// Secondary content
Text('Additional information', style: context.bodyMedium);

// Small details
Text('Caption or small text', style: context.bodySmall);

// Button labels
Text('BUTTON TEXT', style: context.labelLarge);
```

### Custom Typography with Theme Colors
```dart
Text(
  'Custom styled text',
  style: context.bodyLarge?.copyWith(
    color: context.primaryColor,
    fontWeight: FontWeight.w600,
  ),
)

Text(
  'Error message',
  style: context.bodyMedium?.copyWith(
    color: context.errorColor,
    fontWeight: FontWeight.w500,
  ),
)
```

## 🌙 Theme Mode Detection

### Dark Mode Check
```dart
// Check if currently in dark mode
bool get isDarkMode {
  final themeProvider = Provider.of<ThemeProvider>(this, listen: false);
  return themeProvider.isDarkMode;
}
```

### Usage Patterns
```dart
// Conditional styling based on theme mode
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    border: Border.all(
      color: context.isDarkMode 
        ? Colors.grey.shade700 
        : Colors.grey.shade300,
    ),
  ),
)

// Different icons for different themes
Icon(
  context.isDarkMode ? Icons.dark_mode : Icons.light_mode,
  color: context.primaryColor,
)

// Theme-specific gradients
LinearGradient(
  colors: context.isDarkMode
    ? [AppColors.cardGradientStartDark, AppColors.cardGradientEndDark]
    : [AppColors.cardGradientStart, AppColors.cardGradientEnd],
)
```

## 🎨 Custom Theme Extensions Access

### App Theme Extension
```dart
// Access custom theme extension
AppThemeExtension get appTheme => theme.extension<AppThemeExtension>()!;
```

### Custom Properties Available
```dart
// Gradient colors for cards
context.appTheme.cardGradientStart
context.appTheme.cardGradientEnd

// Interview-specific gradients
context.appTheme.interviewGradientStart
context.appTheme.interviewGradientEnd

// Custom feedback colors
context.appTheme.successColor
context.appTheme.warningColor

// Custom shadows
context.appTheme.cardShadow

// Search bar specific (dark mode)
context.appTheme.searchBarBackground
context.appTheme.searchBarBorder
context.appTheme.searchBarInnerShadow
context.appTheme.primaryDarkHover
```

### Usage Examples
```dart
// Use custom gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.appTheme.cardGradientStart!,
        context.appTheme.cardGradientEnd!,
      ],
    ),
  ),
)

// Use custom shadows
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    boxShadow: context.appTheme.cardShadow,
  ),
)
```

## 📐 Geometry and Layout Extensions

### Border Radius Properties
```dart
// Standard border radius for consistency
BorderRadiusGeometry get cardBorderRadius => BorderRadius.circular(16.0);
BorderRadiusGeometry get buttonBorderRadius => BorderRadius.circular(12.0);
BorderRadiusGeometry get smallBorderRadius => BorderRadius.circular(8.0);
```

### Padding Properties
```dart
// Standard padding for consistency
EdgeInsets get screenPadding => const EdgeInsets.all(16.0);
EdgeInsets get cardPadding => const EdgeInsets.all(16.0);
```

### Elevation and Shadow Properties
```dart
// Card elevation that adapts to theme
double get cardElevation => isDarkMode ? 0.0 : 1.0;

// Theme-appropriate shadows
List<BoxShadow>? get cardShadow => isDarkMode 
  ? null 
  : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
```

### Usage Examples
```dart
// Standard card with theme-appropriate styling
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: context.cardBorderRadius,
    boxShadow: context.cardShadow,
  ),
  padding: context.cardPadding,
  child: content,
)

// Buttons with consistent border radius
ElevatedButton(
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: context.buttonBorderRadius,
    ),
  ),
  child: Text('Button'),
)

// Screen with standard padding
Scaffold(
  body: Padding(
    padding: context.screenPadding,
    child: content,
  ),
)
```

## 🎨 Helper Classes for Advanced Theming

### ThemedColors Class
```dart
// Access gradient helpers
LinearGradient cardGradient = ThemedColors.cardGradient(
  context,
  isInterview: false,
);

// Access color helpers
Color textPrimary = ThemedColors.getTextPrimary(context);
Color textSecondary = ThemedColors.getTextSecondary(context);
Color surface = ThemedColors.getSurfaceColor(context);
Color background = ThemedColors.getBackgroundColor(context);
```

### ThemedGradient Class
```dart
// Get card gradients
LinearGradient flashcardGradient = ThemedGradient.getCardGradient(
  context,
  isInterview: false,
);

LinearGradient interviewGradient = ThemedGradient.getCardGradient(
  context,
  isInterview: true,
);
```

### ThemedComponents Class
```dart
// Get standard card decoration
BoxDecoration cardDecoration = ThemedComponents.cardDecoration(context);

// Get card decoration with gradient
BoxDecoration gradientDecoration = ThemedComponents.cardDecorationWithGradient(
  context,
  isInterview: false,
);
```

## 🔧 Advanced Extension Usage

### Custom Color Extensions
```dart
// Fix for withOpacity to use new withValues API
extension ColorWithOpacityFix on Color {
  Color withOpacityFix(double opacity) {
    return withValues(alpha: opacity);
  }
  
  Color withValues({required double alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha);
  }
}
```

### Performance-Optimized Access
```dart
// Cache theme provider access for multiple uses
Widget build(BuildContext context) {
  final isDark = context.isDarkMode; // Cache the check
  
  return Container(
    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    child: Text(
      'Content',
      style: context.bodyLarge?.copyWith(
        color: isDark 
          ? AppColors.textPrimaryDark 
          : AppColors.textPrimary,
      ),
    ),
  );
}
```

## 🧪 Testing Context Extensions

### Testing Theme Access
```dart
testWidgets('context extensions work correctly', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Builder(
        builder: (context) {
          // Test color access
          expect(context.primaryColor, AppColors.primary);
          expect(context.surfaceColor, AppColors.surfaceLight);
          
          // Test typography access
          expect(context.bodyLarge, isNotNull);
          expect(context.titleMedium, isNotNull);
          
          // Test dark mode detection
          expect(context.isDarkMode, false);
          
          return Container();
        },
      ),
      initialThemeMode: ThemeMode.light,
    ),
  );
});
```

## ⚠️ Common Pitfalls and Solutions

### Pitfall: Using Extensions Without Provider
```dart
// ❌ This will crash if ThemeProvider is not in widget tree
bool isDark = context.isDarkMode;

// ✅ Safe usage with error handling
bool isDark = false;
try {
  isDark = context.isDarkMode;
} catch (e) {
  // Fallback to system brightness
  isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
}
```

### Pitfall: Not Listening to Theme Changes
```dart
// ❌ Won't update when theme changes
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode; // listen: false by default
    return Container(color: isDark ? Colors.black : Colors.white);
  }
}

// ✅ Properly listens to theme changes
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          color: themeProvider.isDarkMode ? Colors.black : Colors.white,
        );
      },
    );
  }
}
```

## 📚 Related Documentation

- [Usage Patterns](usage-patterns.md) - Learn how to use these extensions in practice
- [Semantic Colors](semantic-colors.md) - Understand the AppColors system
- [Theme Extensions](../customization/theme-extensions.md) - Learn about custom extensions
- [Component Examples](../examples/component-examples.md) - See real implementations

---

**These context extensions provide a powerful, intuitive API for accessing theme properties throughout the FlashMaster application. Use them consistently for maintainable, theme-aware components.**

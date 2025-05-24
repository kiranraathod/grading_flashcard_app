# Common Theme Patterns

**Reusable Patterns for Consistent Theme Implementation**

## 🎯 Essential Patterns

### 1. Basic Theme-Aware Container
```dart
// Standard pattern for theme-aware containers
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: context.cardBorderRadius,
    boxShadow: context.cardShadow,
  ),
  padding: context.cardPadding,
  child: content,
)
```

### 2. Conditional Theme Styling
```dart
// Pattern for dark/light mode conditional styling
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    border: Border.all(
      color: context.isDarkMode 
        ? Colors.grey.shade700 
        : Colors.grey.shade300,
      width: 1,
    ),
  ),
)
```

### 3. Semantic Color Usage
```dart
// Pattern for semantic color selection
Color getSemanticColor(String type, BuildContext context) {
  switch (type) {
    case 'success':
      return context.successColor;
    case 'error':
      return context.errorColor;
    case 'warning':
      return context.warningColor;
    default:
      return context.primaryColor;
  }
}
```

### 4. Gradient Background Pattern
```dart
// Standard gradient implementation
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: context.isDarkMode
        ? [AppColors.cardGradientStartDark, AppColors.cardGradientEndDark]
        : [AppColors.cardGradientStart, AppColors.cardGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: context.cardBorderRadius,
  ),
)
```

### 5. Responsive Typography Pattern
```dart
// Responsive text that adapts to theme and device
Text(
  content,
  style: context.bodyLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
    fontSize: _getResponsiveFontSize(context),
  ),
)

double _getResponsiveFontSize(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth > 1200) return 18; // Desktop
  if (screenWidth > 768) return 17;  // Tablet
  return 16; // Mobile
}
```

## 🎨 Advanced Patterns

### 6. Animated Theme Transitions
```dart
// Smooth theme change animations
AnimatedContainer(
  duration: context.themeTransitionDuration,
  curve: context.themeTransitionCurve,
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: context.cardBorderRadius,
  ),
  child: content,
)
```

### 7. Focus State Pattern
```dart
// Interactive elements with focus states
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: hasFocus 
        ? context.primaryColor 
        : Colors.transparent,
      width: context.focusBorderWidth,
    ),
    borderRadius: context.buttonBorderRadius,
  ),
)
```

### 8. Category-Based Theming
```dart
// Dynamic theming based on content category
Widget getCategoryThemedWidget(String category, Widget child) {
  final categoryColor = AppColors.getCategoryColor(
    category,
    isDarkMode: context.isDarkMode,
  );
  
  return Container(
    decoration: BoxDecoration(
      color: categoryColor.withValues(alpha: 0.1),
      border: Border.all(color: categoryColor),
      borderRadius: context.smallBorderRadius,
    ),
    child: child,
  );
}
```

## 🧩 Component Composition Patterns

### 9. Themed Card Factory
```dart
class ThemedCardFactory {
  static Widget createCard({
    required BuildContext context,
    required Widget child,
    bool isInterview = false,
    bool isElevated = true,
  }) {
    return Container(
      decoration: isInterview
        ? ThemedComponents.cardDecorationWithGradient(
            context,
            isInterview: true,
          )
        : ThemedComponents.cardDecoration(
            context,
            boxShadow: isElevated ? context.cardShadow : null,
          ),
      padding: context.cardPadding,
      child: child,
    );
  }
}
```

### 10. Status Indicator Pattern
```dart
Widget buildStatusIndicator(String status, BuildContext context) {
  final statusColor = AppColors.getStatusColor(
    status,
    isDarkMode: context.isDarkMode,
  );
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 8),
      Text(
        status.toUpperCase(),
        style: context.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
```

## 🔧 Utility Patterns

### 11. Theme-Aware Spacing
```dart
// Consistent spacing that adapts to theme
class ThemedSpacing {
  static Widget verticalSpace(BuildContext context, {double factor = 1}) {
    return SizedBox(height: context.componentSpacing * factor);
  }
  
  static Widget horizontalSpace(BuildContext context, {double factor = 1}) {
    return SizedBox(width: context.componentSpacing * factor);
  }
}
```

### 12. Performance-Optimized Theme Access
```dart
// Cache theme properties for multiple uses
Widget build(BuildContext context) {
  final themeData = ThemeCache.of(context);
  
  return Container(
    color: themeData.surfaceColor,
    child: Text(
      'Content',
      style: themeData.bodyLarge?.copyWith(
        color: themeData.textPrimary,
      ),
    ),
  );
}

class ThemeCache {
  final Color surfaceColor;
  final Color textPrimary;
  final TextStyle? bodyLarge;
  final bool isDarkMode;
  
  ThemeCache.of(BuildContext context)
    : surfaceColor = context.surfaceColor,
      textPrimary = AppColors.getTextPrimary(context.isDarkMode),
      bodyLarge = context.bodyLarge,
      isDarkMode = context.isDarkMode;
}
```

## 📱 Responsive Patterns

### 13. Adaptive Layout Pattern
```dart
Widget buildAdaptiveLayout(BuildContext context, Widget content) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 1200) {
    // Desktop layout
    return Padding(
      padding: EdgeInsets.all(context.componentSpacing * 2),
      child: content,
    );
  } else if (screenWidth > 768) {
    // Tablet layout
    return Padding(
      padding: EdgeInsets.all(context.componentSpacing * 1.5),
      child: content,
    );
  } else {
    // Mobile layout
    return Padding(
      padding: context.screenPadding,
      child: content,
    );
  }
}
```

### 14. Platform-Adaptive Theming
```dart
Widget buildPlatformAdaptiveWidget(BuildContext context) {
  if (Platform.isIOS) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12), // iOS style
      ),
    );
  } else {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.cardBorderRadius, // Material style
      ),
    );
  }
}
```

---

**These patterns provide tested, reusable solutions for common theme implementation scenarios, ensuring consistency across the application.**

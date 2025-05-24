# Semantic Colors Guide

**Complete Reference for the AppColors System**

## 🎯 Overview

The FlashMaster application uses a comprehensive semantic color system that provides meaningful, purpose-driven colors with full dark mode support. This guide explains how to use the AppColors system effectively.

## 🏗️ Core Color Categories

### Brand Colors
```dart
// Primary teal-based brand colors
static const Color primary = Color(0xFF009688);      // Teal-500
static const Color primaryDark = Color(0xFF4DB6AC);  // Teal-300 (dark mode)
static const Color accent = Color(0xFF00796B);       // Teal-700

// Secondary purple colors for variety
static const Color secondary = Color(0xFF8B5CF6);     // Purple-600
static const Color secondaryDark = Color(0xFFA78BFA); // Purple-400 (dark mode)
```

### Background and Surface Colors
```dart
// Background colors for entire screens
static const Color background = Color(0xFFF9FAFB);     // Gray-50
static const Color backgroundDark = Color(0xFF121216); // Dark background

// Surface colors for cards and elevated elements
static const Color surfaceLight = Colors.white;
static const Color surfaceDark = Color(0xFF2A2A30);    // Elevated dark surface
```

### Text Colors with High Contrast
```dart
// Light mode text colors
static const Color textPrimary = Color(0xFF1F2937);   // Gray-800
static const Color textSecondary = Color(0xFF4B5563); // Gray-600
static const Color textTertiary = Color(0xFF9CA3AF);  // Gray-400

// Dark mode text colors (optimized for readability)
static const Color textPrimaryDark = Colors.white;
static const Color textSecondaryDark = Color(0xFFF0F0F0); // High contrast
static const Color textTertiaryDark = Color(0xFFBFBFBF);  // Better contrast
```

## 🎨 Card and Component Colors

### Flashcard Gradients (Teal Theme)
```dart
// Light mode flashcard gradients
static const Color cardGradientStart = Color(0xFFE0F2F1); // Teal-50
static const Color cardGradientEnd = Color(0xFFB2DFDB);   // Teal-100

// Dark mode flashcard gradients
static const Color cardGradientStartDark = Color(0xFF00332C); // Dark teal
static const Color cardGradientEndDark = Color(0xFF004D40);   // Teal-900
```

### Interview Component Gradients (Purple Theme)
```dart
// Light mode interview gradients
static const Color interviewGradientStart = Color(0xFFEEF2FF); // Purple-50
static const Color interviewGradientEnd = Color(0xFFE0E7FF);   // Indigo-50

// Dark mode interview gradients
static const Color interviewGradientStartDark = Color(0xFF1F1D35); // Rich purple
static const Color interviewGradientEndDark = Color(0xFF292449);   // Rich indigo
```

### Usage Examples
```dart
// Flashcard component with teal gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: context.isDarkMode
        ? [AppColors.cardGradientStartDark, AppColors.cardGradientEndDark]
        : [AppColors.cardGradientStart, AppColors.cardGradientEnd],
    ),
  ),
)

// Interview component with purple gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: context.isDarkMode
        ? [AppColors.interviewGradientStartDark, AppColors.interviewGradientEndDark]
        : [AppColors.interviewGradientStart, AppColors.interviewGradientEnd],
    ),
  ),
)
```

## 📊 Feedback and Status Colors

### Feedback Colors
```dart
// Success (using teal for brand consistency)
static const Color success = Color(0xFF009688);      // Teal-500
static const Color successDark = Color(0xFF4DB6AC);  // Teal-300

// Warning colors
static const Color warning = Color(0xFFF59E0B);      // Amber-500
static const Color warningDark = Color(0xFFFBBF24);  // Amber-400

// Error colors
static const Color error = Color(0xFFEF4444);        // Red-500
static const Color errorDark = Color(0xFFF87171);    // Red-400

// Info colors
static const Color info = Color(0xFF3B82F6);         // Blue-500
static const Color infoDark = Color(0xFF60A5FA);     // Blue-400
```

### Grade Colors
```dart
// Light mode grades
static const Color gradeA = Color(0xFF4CAF50);  // Green-500
static const Color gradeB = Color(0xFF8BC34A);  // Light Green-500
static const Color gradeC = Color(0xFFFF9800);  // Orange-500
static const Color gradeD = Color(0xFFFF5722);  // Deep Orange-500
static const Color gradeF = Color(0xFFF44336);  // Red-500

// Dark mode grades (more vibrant)
static const Color gradeADark = Color(0xFF66BB6A);  // Green-400
static const Color gradeBDark = Color(0xFF9CCC65);  // Light Green-400
static const Color gradeCDark = Color(0xFFFFB74D);  // Orange-400
static const Color gradeDDark = Color(0xFFFF8A65);  // Deep Orange-400
static const Color gradeFDark = Color(0xFFE57373);  // Red-400
```

### Usage Examples
```dart
// Success message
Container(
  color: context.isDarkMode ? AppColors.successDark : AppColors.success,
  child: Text(
    'Success!',
    style: TextStyle(color: Colors.white),
  ),
)

// Grade display
Container(
  color: AppColors.getGradeColor('A', isDarkMode: context.isDarkMode),
  child: Text('A', style: TextStyle(color: Colors.white)),
)
```

## 🏷️ Category Colors for Interview Questions

### Technical Categories
```dart
// Light mode category colors
static const Color categoryTechnical = Color(0xFF1E3A8A);    // Blue-800
static const Color categoryBehavioral = Color(0xFF064E3B);   // Emerald-800
static const Color categoryLeadership = Color(0xFF4C1D95);   // Violet-800
static const Color categorySituational = Color(0xFF854D0E);  // Amber-800
static const Color categoryGeneral = Color(0xFF991B1B);      // Red-800
static const Color categoryDefault = Color(0xFF374151);      // Gray-700

// Dark mode category colors (lighter for better contrast)
static const Color categoryTechnicalDark = Color(0xFF93C5FD);    // Blue-300
static const Color categoryBehavioralDark = Color(0xFF6EE7B7);   // Emerald-300
static const Color categoryLeadershipDark = Color(0xFFC4B5FD);   // Violet-300
static const Color categorySituationalDark = Color(0xFFFDE68A);  // Amber-300
static const Color categoryGeneralDark = Color(0xFFFCA5A5);      // Red-300
static const Color categoryDefaultDark = Color(0xFFD1D5DB);      // Gray-300
```

### Usage with Helper Methods
```dart
// Get category color automatically
Color categoryColor = AppColors.getCategoryColor(
  'technical',
  isDarkMode: context.isDarkMode,
);

// Use in chips or badges
Chip(
  label: Text('Technical'),
  backgroundColor: AppColors.getCategoryColor(
    'technical',
    isDarkMode: context.isDarkMode,
  ).withValues(alpha: 0.2),
  labelStyle: TextStyle(
    color: AppColors.getCategoryColor(
      'technical',
      isDarkMode: context.isDarkMode,
    ),
  ),
)
```

## 🎯 Helper Methods for Dynamic Colors

### Category Color Helper
```dart
static Color getCategoryColor(String category, {bool isDarkMode = false}) {
  if (isDarkMode) {
    switch (category.toLowerCase()) {
      case 'technical':
      case 'data science':
        return categoryTechnicalDark;
      case 'behavioral':
        return categoryBehavioralDark;
      case 'leadership':
        return categoryLeadershipDark;
      case 'situational':
        return categorySituationalDark;
      case 'general':
        return categoryGeneralDark;
      default:
        return categoryDefaultDark;
    }
  } else {
    // Light mode logic...
  }
}
```

### Difficulty Color Helper
```dart
static Color getDifficultyColor(String difficulty, {bool isDarkMode = false}) {
  if (isDarkMode) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return successDark;    // Teal for easy
      case 'medium':
        return warningDark;    // Amber for medium
      case 'hard':
        return errorDark;      // Red for hard
      default:
        return textSecondaryDark;
    }
  } else {
    // Light mode logic...
  }
}
```

### Progress Color Helper
```dart
static Color getProgressColor(int progress, {bool isDarkMode = false}) {
  if (isDarkMode) {
    if (progress >= 70) return primaryDark;     // Excellent: Teal
    if (progress >= 40) return warningDark;     // Good: Amber
    if (progress > 0) return infoDark;          // Started: Blue
    return textTertiaryDark;                    // Not started: Gray
  } else {
    if (progress >= 70) return primary;        // Excellent: Teal
    if (progress >= 40) return warning;        // Good: Amber
    if (progress > 0) return info;             // Started: Blue
    return textTertiary;                       // Not started: Gray
  }
}
```

### Usage Examples
```dart
// Progress indicator with semantic color
LinearProgressIndicator(
  value: progress / 100,
  valueColor: AlwaysStoppedAnimation<Color>(
    AppColors.getProgressColor(progress, isDarkMode: context.isDarkMode),
  ),
)

// Difficulty badge
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.getDifficultyColor(
      'medium',
      isDarkMode: context.isDarkMode,
    ).withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'Medium',
    style: TextStyle(
      color: AppColors.getDifficultyColor(
        'medium',
        isDarkMode: context.isDarkMode,
      ),
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

## 🏗️ Container and Surface Helpers

### Surface Color Helpers
```dart
// Get appropriate surface color for theme
static Color getSurfaceColor(bool isDarkMode) {
  return isDarkMode ? surfaceDark : surfaceLight;
}

// Get appropriate background color for theme
static Color getBackgroundColor(bool isDarkMode) {
  return isDarkMode ? backgroundDark : background;
}

// Get container color for current theme
static Color getContainerColor(bool isDarkMode) {
  return isDarkMode ? surfaceContainer : surfaceContainerLight;
}

// Get divider color for current theme
static Color getDividerColor(bool isDarkMode) {
  return isDarkMode ? divider : dividerLight;
}
```

### Text Color Helpers
```dart
// Get primary text color for theme
static Color getTextPrimary(bool isDarkMode) {
  return isDarkMode ? textPrimaryDark : textPrimary;
}

// Get secondary text color for theme
static Color getTextSecondary(bool isDarkMode) {
  return isDarkMode ? textSecondaryDark : textSecondary;
}
```

### Usage in Components
```dart
// Themed container
Container(
  color: AppColors.getSurfaceColor(context.isDarkMode),
  child: Text(
    'Content',
    style: TextStyle(
      color: AppColors.getTextPrimary(context.isDarkMode),
    ),
  ),
)

// Themed divider
Divider(
  color: AppColors.getDividerColor(context.isDarkMode),
)
```

## 🎨 Advanced Color Usage Patterns

### Opacity and Transparency
```dart
// Create semi-transparent versions for backgrounds
final backgroundOverlay = AppColors.primary.withValues(alpha: 0.1);

// Create hover states
final hoverColor = AppColors.primary.withValues(alpha: 0.05);

// Create disabled states
final disabledColor = AppColors.textSecondary.withValues(alpha: 0.5);
```

### Color Combinations for Accessibility
```dart
// High contrast combinations that work in both themes
class ColorCombinations {
  static ColorPair primaryOnSurface(bool isDarkMode) {
    return ColorPair(
      foreground: isDarkMode ? AppColors.primaryDark : AppColors.primary,
      background: AppColors.getSurfaceColor(isDarkMode),
    );
  }
  
  static ColorPair errorOnSurface(bool isDarkMode) {
    return ColorPair(
      foreground: isDarkMode ? AppColors.errorDark : AppColors.error,
      background: AppColors.getSurfaceColor(isDarkMode),
    );
  }
}

class ColorPair {
  final Color foreground;
  final Color background;
  
  ColorPair({required this.foreground, required this.background});
}
```

## 🧪 Testing Semantic Colors

### Color Accessibility Testing
```dart
testWidgets('colors meet accessibility standards', (tester) async {
  // Test light mode contrast ratios
  final lightPrimary = AppColors.primary;
  final lightSurface = AppColors.surfaceLight;
  expect(
    calculateContrastRatio(lightPrimary, lightSurface),
    greaterThan(4.5), // WCAG AA standard
  );
  
  // Test dark mode contrast ratios
  final darkPrimary = AppColors.primaryDark;
  final darkSurface = AppColors.surfaceDark;
  expect(
    calculateContrastRatio(darkPrimary, darkSurface),
    greaterThan(4.5), // WCAG AA standard
  );
});
```

### Color Usage Testing
```dart
testWidgets('helper methods return correct colors', (tester) async {
  // Test category colors
  expect(
    AppColors.getCategoryColor('technical', isDarkMode: false),
    AppColors.categoryTechnical,
  );
  
  expect(
    AppColors.getCategoryColor('technical', isDarkMode: true),
    AppColors.categoryTechnicalDark,
  );
  
  // Test difficulty colors
  expect(
    AppColors.getDifficultyColor('easy', isDarkMode: false),
    AppColors.success,
  );
  
  expect(
    AppColors.getDifficultyColor('easy', isDarkMode: true),
    AppColors.successDark,
  );
});
```

## ❌ Common Mistakes to Avoid

### Don't Create Custom Color Constants
```dart
// ❌ Bad - creates maintenance issues
class MyColors {
  static const customBlue = Color(0xFF1234AB);
}

// ✅ Good - add to AppColors system
// Add to AppColors class following naming conventions
```

### Don't Use Colors.* Directly
```dart
// ❌ Bad - doesn't adapt to theme
Container(color: Colors.grey.shade200)

// ✅ Good - uses semantic color
Container(color: AppColors.getSurfaceColor(context.isDarkMode))
```

### Don't Ignore Dark Mode Variants
```dart
// ❌ Bad - only works in light mode
Container(color: AppColors.primary)

// ✅ Good - adapts to theme mode
Container(
  color: context.isDarkMode ? AppColors.primaryDark : AppColors.primary,
)
```

## 📐 Color Naming Conventions

### Naming Pattern
1. **Base name**: Describes the semantic purpose (primary, success, error)
2. **Dark suffix**: Add "Dark" for dark mode variants
3. **Descriptive context**: Include context when needed (cardGradientStart)

### Examples of Good Names
```dart
static const Color primary = Color(0xFF009688);
static const Color primaryDark = Color(0xFF4DB6AC);
static const Color cardGradientStart = Color(0xFFE0F2F1);
static const Color cardGradientStartDark = Color(0xFF00332C);
static const Color categoryTechnical = Color(0xFF1E3A8A);
static const Color categoryTechnicalDark = Color(0xFF93C5FD);
```

## 📚 Related Documentation

- [Usage Patterns](usage-patterns.md) - Learn how to use these colors in components
- [Context Extensions](context-extensions.md) - Access colors through context extensions
- [Theme Extensions](../customization/theme-extensions.md) - Extend the color system
- [Component Examples](../examples/component-examples.md) - See colors in real implementations

---

**The semantic color system provides a robust foundation for consistent, accessible, and maintainable theming throughout the FlashMaster application.**

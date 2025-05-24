# Theme Usage Patterns for Developers

**Comprehensive Guide to Using the FlashMaster Theme System**

## 🎯 Overview

This guide provides developers with practical patterns for implementing theme-aware components in the FlashMaster application. Follow these patterns to ensure consistent theming across all components.

## 🏗️ Basic Theme-Aware Component Pattern

### Standard Implementation
```dart
class ThemeAwareWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Use semantic background colors
      color: context.surfaceColor,
      child: Column(
        children: [
          Text(
            'Primary Text',
            // Use theme typography with semantic colors
            style: context.bodyLarge?.copyWith(
              color: context.isDarkMode 
                ? AppColors.textPrimaryDark 
                : AppColors.textPrimary,
            ),
          ),
          Text(
            'Secondary Text',
            style: context.bodyMedium?.copyWith(
              color: context.isDarkMode 
                ? AppColors.textSecondaryDark 
                : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Why This Pattern Works
- ✅ **Semantic Colors**: Uses context.surfaceColor instead of hardcoded colors
- ✅ **Theme Typography**: Leverages context.bodyLarge from Material 3 system
- ✅ **Dark Mode Awareness**: Checks context.isDarkMode for conditional styling
- ✅ **Maintainable**: Easy to update when theme system changes

## 🎨 Color Usage Patterns

### Primary Colors
```dart
// For primary brand elements
Container(
  color: context.primaryColor,
  child: Text(
    'Primary Action',
    style: context.labelLarge?.copyWith(
      color: context.onPrimaryColor,
    ),
  ),
)
```

### Surface and Background Colors
```dart
// For cards and elevated surfaces
Card(
  color: context.surfaceColor,
  child: Container(
    // For screen backgrounds
    color: context.backgroundColor,
    child: content,
  ),
)
```

### Feedback Colors
```dart
// Success feedback
Container(
  color: context.successColor,
  child: Icon(
    Icons.check,
    color: Colors.white,
  ),
)

// Error feedback
Container(
  color: context.errorColor,
  child: Text(
    'Error Message',
    style: context.bodyMedium?.copyWith(
      color: context.onErrorColor,
    ),
  ),
)

// Warning feedback
Container(
  color: context.warningColor,
  child: warningContent,
)
```

### Semantic Color Helper Methods
```dart
// Use AppColors helper methods for semantic meanings
Container(
  color: AppColors.getDifficultyColor(
    'easy', 
    isDarkMode: context.isDarkMode,
  ),
)

Container(
  color: AppColors.getCategoryColor(
    'technical',
    isDarkMode: context.isDarkMode,
  ),
)

Container(
  color: AppColors.getGradeColor(
    'A',
    isDarkMode: context.isDarkMode,
  ),
)
```

## 📝 Typography Patterns

### Material 3 Typography Scale
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Large display text
    Text('Main Heading', style: context.displayLarge),
    
    // Section headings
    Text('Section Title', style: context.headlineMedium),
    
    // Subsection headings
    Text('Subsection', style: context.titleLarge),
    
    // Primary body text
    Text('Body content', style: context.bodyLarge),
    
    // Secondary body text
    Text('Additional info', style: context.bodyMedium),
    
    // Small supplementary text
    Text('Caption text', style: context.bodySmall),
    
    // Button labels
    Text('Button Text', style: context.labelLarge),
  ],
)
```

### Custom Typography with Theme Colors
```dart
Text(
  'Custom styled text',
  style: context.bodyLarge?.copyWith(
    color: context.isDarkMode 
      ? AppColors.textPrimaryDark 
      : AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
)
```

## 🃏 Card and Container Patterns

### Basic Themed Card
```dart
Container(
  decoration: ThemedComponents.cardDecoration(context),
  padding: context.cardPadding,
  child: content,
)
```

### Gradient Card (Flashcard Style)
```dart
Container(
  decoration: ThemedComponents.cardDecorationWithGradient(
    context,
    isInterview: false, // Use flashcard gradient
  ),
  child: content,
)
```

### Interview-Style Gradient Card
```dart
Container(
  decoration: ThemedComponents.cardDecorationWithGradient(
    context,
    isInterview: true, // Use interview gradient
  ),
  child: content,
)
```

### Custom Gradient Pattern
```dart
Container(
  decoration: BoxDecoration(
    gradient: ThemedColors.cardGradient(
      context,
      isInterview: false,
    ),
    borderRadius: context.cardBorderRadius,
    boxShadow: context.cardShadow,
  ),
  child: content,
)
```

## 🔘 Interactive Element Patterns

### Themed Buttons
```dart
// Primary button with theme colors
ElevatedButton(
  onPressed: onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: context.primaryColor,
    foregroundColor: context.onPrimaryColor,
  ),
  child: Text('Primary Action'),
)

// Secondary button
OutlinedButton(
  onPressed: onPressed,
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: context.primaryColor),
    foregroundColor: context.primaryColor,
  ),
  child: Text('Secondary Action'),
)
```

### Themed Input Fields
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Input Label',
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: context.isDarkMode 
          ? Colors.grey.shade700 
          : Colors.grey.shade300,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: context.primaryColor,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: context.errorColor,
      ),
    ),
  ),
)
```

### Themed Switches and Toggles
```dart
Switch(
  value: switchValue,
  onChanged: onChanged,
  activeColor: context.primaryColor,
  inactiveThumbColor: context.isDarkMode 
    ? Colors.grey.shade600 
    : Colors.grey.shade400,
)
```

## 📊 Data Visualization Patterns

### Progress Indicators
```dart
LinearProgressIndicator(
  value: progress,
  backgroundColor: context.isDarkMode 
    ? Colors.grey.shade700 
    : Colors.grey.shade300,
  valueColor: AlwaysStoppedAnimation<Color>(
    AppColors.getProgressColor(
      (progress * 100).round(),
      isDarkMode: context.isDarkMode,
    ),
  ),
)
```

### Chart Elements
```dart
// For chart colors that adapt to theme
List<Color> getChartColors(BuildContext context) {
  if (context.isDarkMode) {
    return [
      AppColors.primaryDark,
      AppColors.secondaryDark,
      AppColors.successDark,
      AppColors.warningDark,
    ];
  } else {
    return [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
    ];
  }
}
```

## 🎭 Conditional Theming Patterns

### Dark Mode Specific Styling
```dart
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: context.surfaceColor,
      border: Border.all(
        color: context.isDarkMode 
          ? Colors.grey.shade700 
          : Colors.grey.shade300,
      ),
      // Dark mode gets different shadow
      boxShadow: context.isDarkMode 
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
    ),
    child: content,
  );
}
```

### Category-Based Conditional Colors
```dart
Color getCategoryBackgroundColor(String category, BuildContext context) {
  final baseColor = AppColors.getCategoryColor(
    category,
    isDarkMode: context.isDarkMode,
  );
  
  // Return a lighter version for backgrounds
  return baseColor.withValues(alpha: 0.1);
}
```

## 🧪 Testing Your Theme-Aware Components

### Basic Theme Testing Pattern
```dart
testWidgets('widget adapts to theme changes', (tester) async {
  // Test light mode
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: YourThemeAwareWidget(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  
  // Verify light mode colors
  expect(
    tester.widget<Container>(find.byType(Container)).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      AppColors.surfaceLight,
    ),
  );
  
  // Switch to dark mode
  await ThemeTestUtils.switchToDarkTheme(tester);
  
  // Verify dark mode colors
  expect(
    tester.widget<Container>(find.byType(Container)).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      AppColors.surfaceDark,
    ),
  );
});
```

## ❌ Common Anti-Patterns to Avoid

### Don't Use Hardcoded Colors
```dart
// ❌ Bad - hardcoded colors
Container(
  color: Colors.grey.shade200,
  child: Text(
    'Text',
    style: TextStyle(color: Colors.grey.shade800),
  ),
)

// ✅ Good - theme-aware colors
Container(
  color: context.surfaceColor,
  child: Text(
    'Text',
    style: context.bodyLarge,
  ),
)
```

### Don't Ignore Dark Mode
```dart
// ❌ Bad - doesn't adapt to dark mode
Container(
  color: Colors.white,
  child: Text(
    'Text',
    style: TextStyle(color: Colors.black),
  ),
)

// ✅ Good - adapts to both modes
Container(
  color: context.surfaceColor,
  child: Text(
    'Text',
    style: context.bodyLarge?.copyWith(
      color: context.isDarkMode 
        ? AppColors.textPrimaryDark 
        : AppColors.textPrimary,
    ),
  ),
)
```

### Don't Create Custom Color Constants
```dart
// ❌ Bad - custom color constants
class CustomColors {
  static const myBlue = Color(0xFF1234AB);
}

// ✅ Good - add to AppColors system
// Add to AppColors class and follow naming conventions
```

## 🎯 Performance Considerations

### Use RepaintBoundary for Theme Animations
```dart
RepaintBoundary(
  child: AnimatedContainer(
    duration: Duration(milliseconds: 150),
    color: context.primaryColor,
    child: content,
  ),
)
```

### Avoid Rebuilding Large Widget Trees
```dart
// ✅ Good - only rebuild what needs to change
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
    return Container(
      color: context.surfaceColor, // Only this rebuilds
      child: StaticChildWidget(), // This doesn't rebuild
    );
  },
)
```

## 🔄 Migration Pattern for Existing Widgets

### Step-by-Step Migration Process
1. **Identify hardcoded colors**: Search for `Color(0x`, `Colors.`, and hex values
2. **Replace with semantic colors**: Use appropriate AppColors or context colors
3. **Add dark mode support**: Use `context.isDarkMode` for conditional styling
4. **Test both themes**: Verify appearance in light and dark modes
5. **Add theme tests**: Include tests for theme adaptation

### Migration Example
```dart
// Before migration
Container(
  color: Color(0xFFF5F5F5), // Hardcoded light gray
  child: Text(
    'Content',
    style: TextStyle(
      color: Color(0xFF333333), // Hardcoded dark gray
      fontSize: 16,
    ),
  ),
)

// After migration
Container(
  color: context.surfaceColor, // Semantic surface color
  child: Text(
    'Content',
    style: context.bodyLarge?.copyWith(
      color: context.isDarkMode 
        ? AppColors.textPrimaryDark 
        : AppColors.textPrimary,
    ),
  ),
)
```

## 📚 Related Documentation

- [Context Extensions Guide](context-extensions.md) - Learn about available context methods
- [Semantic Colors Guide](semantic-colors.md) - Understand the AppColors system
- [Typography Guide](typography.md) - Master theme typography
- [Component Examples](../examples/component-examples.md) - See real-world implementations
- [Testing Requirements](../maintenance/testing-requirements.md) - Ensure proper testing

---

**Follow these patterns consistently to create beautiful, accessible, and maintainable theme-aware components in the FlashMaster application.**

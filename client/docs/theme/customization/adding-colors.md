# Adding Colors to the Semantic Color System

**Step-by-Step Guide for Extending the AppColors System**

## 🎯 Overview

This guide explains how to properly add new semantic colors to the FlashMaster theme system while maintaining consistency, accessibility, and dark mode support.

## 🏗️ Understanding the Color System Structure

### Current Color Categories
1. **Brand Colors**: primary, secondary, accent
2. **Background/Surface**: background, surface, container colors
3. **Text Colors**: primary, secondary, tertiary text
4. **Feedback Colors**: success, warning, error, info
5. **Grade Colors**: A, B, C, D, F grades
6. **Category Colors**: technical, behavioral, leadership, etc.
7. **Gradient Colors**: card and interview gradients

### Naming Convention Pattern
```dart
// Base color for light mode
static const Color semanticName = Color(0xFFHEXVAL);

// Dark mode variant
static const Color semanticNameDark = Color(0xFFHEXVAL);

// Context-specific variants
static const Color semanticNameContext = Color(0xFFHEXVAL);
static const Color semanticNameContextDark = Color(0xFFHEXVAL);
```

## 🎨 Step 1: Define New Semantic Colors

### Example: Adding "Focus" Colors
```dart
// In lib/utils/colors.dart, add to appropriate section

// Focus colors for highlighting active elements
static const Color focus = Color(0xFF6366F1);        // Indigo-500
static const Color focusDark = Color(0xFF818CF8);    // Indigo-400

// Focus background (subtle)
static const Color focusBackground = Color(0xFFEEF2FF);     // Indigo-50
static const Color focusBackgroundDark = Color(0xFF1E1B4B); // Indigo-900

// Focus border (more prominent)
static const Color focusBorder = Color(0xFF4F46E5);        // Indigo-600
static const Color focusBorderDark = Color(0xFF6366F1);    // Indigo-500
```

### Example: Adding Status Colors
```dart
// Status colors for different states
static const Color pending = Color(0xFFF59E0B);       // Amber-500
static const Color pendingDark = Color(0xFFFBBF24);   // Amber-400

static const Color approved = Color(0xFF10B981);      // Emerald-500
static const Color approvedDark = Color(0xFF34D399);  // Emerald-400

static const Color rejected = Color(0xFFEF4444);      // Red-500
static const Color rejectedDark = Color(0xFFF87171);  // Red-400

static const Color inReview = Color(0xFF8B5CF6);      // Purple-500
static const Color inReviewDark = Color(0xFFA78BFA);  // Purple-400
```

## 🔧 Step 2: Add Helper Methods

### Basic Color Helper
```dart
// Add to AppColors class
static Color getFocusColor(bool isDarkMode) {
  return isDarkMode ? focusDark : focus;
}

static Color getFocusBackgroundColor(bool isDarkMode) {
  return isDarkMode ? focusBackgroundDark : focusBackground;
}

static Color getFocusBorderColor(bool isDarkMode) {
  return isDarkMode ? focusBorderDark : focusBorder;
}
```

### Status-Based Helper Method
```dart
// Helper method for status colors
static Color getStatusColor(String status, {bool isDarkMode = false}) {
  if (isDarkMode) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingDark;
      case 'approved':
        return approvedDark;
      case 'rejected':
        return rejectedDark;
      case 'in_review':
      case 'review':
        return inReviewDark;
      default:
        return textSecondaryDark;
    }
  } else {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'approved':
        return approved;
      case 'rejected':
        return rejected;
      case 'in_review':
      case 'review':
        return inReview;
      default:
        return textSecondary;
    }
  }
}
```

### Complex Color Helper with Variants
```dart
// Helper for focus colors with intensity levels
static Color getFocusColorWithIntensity(
  String intensity, {
  bool isDarkMode = false,
}) {
  if (isDarkMode) {
    switch (intensity.toLowerCase()) {
      case 'subtle':
        return focusBackgroundDark;
      case 'medium':
        return focusDark.withValues(alpha: 0.7);
      case 'strong':
        return focusDark;
      case 'border':
        return focusBorderDark;
      default:
        return focusDark;
    }
  } else {
    switch (intensity.toLowerCase()) {
      case 'subtle':
        return focusBackground;
      case 'medium':
        return focus.withValues(alpha: 0.7);
      case 'strong':
        return focus;
      case 'border':
        return focusBorder;
      default:
        return focus;
    }
  }
}
```

## 📱 Step 3: Update Theme Extensions (Optional)

### For App-Wide Custom Colors
```dart
// In lib/utils/theme_extensions.dart

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // ... existing properties ...
  
  // Add new custom properties
  final Color? focusColor;
  final Color? focusBackgroundColor;
  final Color? focusBorderColor;

  const AppThemeExtension({
    // ... existing parameters ...
    this.focusColor,
    this.focusBackgroundColor,
    this.focusBorderColor,
  });

  // Update light theme extension
  static const light = AppThemeExtension(
    // ... existing properties ...
    focusColor: AppColors.focus,
    focusBackgroundColor: AppColors.focusBackground,
    focusBorderColor: AppColors.focusBorder,
  );

  // Update dark theme extension
  static const dark = AppThemeExtension(
    // ... existing properties ...
    focusColor: AppColors.focusDark,
    focusBackgroundColor: AppColors.focusBackgroundDark,
    focusBorderColor: AppColors.focusBorderDark,
  );

  @override
  AppThemeExtension copyWith({
    // ... existing parameters ...
    Color? focusColor,
    Color? focusBackgroundColor,
    Color? focusBorderColor,
  }) {
    return AppThemeExtension(
      // ... existing assignments ...
      focusColor: focusColor ?? this.focusColor,
      focusBackgroundColor: focusBackgroundColor ?? this.focusBackgroundColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    
    return AppThemeExtension(
      // ... existing lerp assignments ...
      focusColor: Color.lerp(focusColor, other.focusColor, t),
      focusBackgroundColor: Color.lerp(focusBackgroundColor, other.focusBackgroundColor, t),
      focusBorderColor: Color.lerp(focusBorderColor, other.focusBorderColor, t),
    );
  }
}
```

## 🔧 Step 4: Add Context Extensions (Optional)

### For Frequently Used Colors
```dart
// In lib/utils/theme_utils.dart, add to ThemeGetter extension

extension ThemeGetter on BuildContext {
  // ... existing getters ...
  
  // New focus color getters
  Color get focusColor => isDarkMode ? AppColors.focusDark : AppColors.focus;
  Color get focusBackgroundColor => isDarkMode 
    ? AppColors.focusBackgroundDark 
    : AppColors.focusBackground;
  Color get focusBorderColor => isDarkMode 
    ? AppColors.focusBorderDark 
    : AppColors.focusBorder;
}
```

### Using Theme Extensions
```dart
// Alternative: Access through theme extensions
extension ThemeGetter on BuildContext {
  Color get focusColor => appTheme.focusColor!;
  Color get focusBackgroundColor => appTheme.focusBackgroundColor!;
  Color get focusBorderColor => appTheme.focusBorderColor!;
}
```

## 🎨 Step 5: Usage Examples

### Basic Usage
```dart
// Using helper methods (recommended)
Container(
  color: AppColors.getFocusColor(context.isDarkMode),
  child: content,
)

// Using context extensions
Container(
  color: context.focusColor,
  child: content,
)
```

### Status Usage
```dart
// Status indicator
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.getStatusColor(
      'approved',
      isDarkMode: context.isDarkMode,
    ).withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: AppColors.getStatusColor(
        'approved',
        isDarkMode: context.isDarkMode,
      ),
    ),
  ),
  child: Text(
    'Approved',
    style: context.labelSmall?.copyWith(
      color: AppColors.getStatusColor(
        'approved',
        isDarkMode: context.isDarkMode,
      ),
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### Focus State Usage
```dart
// Focus-aware input field
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: hasFocus 
        ? context.focusBorderColor 
        : Colors.grey.shade300,
      width: hasFocus ? 2 : 1,
    ),
    backgroundColor: hasFocus 
      ? context.focusBackgroundColor 
      : Colors.transparent,
  ),
  child: TextFormField(
    // ... field configuration
  ),
)
```

## 🧪 Step 6: Add Tests

### Color Value Tests
```dart
// In test/theme/unit/colors_test.dart
group('Focus Colors', () {
  test('should have correct light mode colors', () {
    expect(AppColors.focus, const Color(0xFF6366F1));
    expect(AppColors.focusBackground, const Color(0xFFEEF2FF));
    expect(AppColors.focusBorder, const Color(0xFF4F46E5));
  });

  test('should have correct dark mode colors', () {
    expect(AppColors.focusDark, const Color(0xFF818CF8));
    expect(AppColors.focusBackgroundDark, const Color(0xFF1E1B4B));
    expect(AppColors.focusBorderDark, const Color(0xFF6366F1));
  });

  test('helper methods should return correct colors', () {
    expect(
      AppColors.getFocusColor(false),
      AppColors.focus,
    );
    expect(
      AppColors.getFocusColor(true),
      AppColors.focusDark,
    );
  });
});

group('Status Colors', () {
  test('should return correct status colors', () {
    expect(
      AppColors.getStatusColor('approved', isDarkMode: false),
      AppColors.approved,
    );
    expect(
      AppColors.getStatusColor('approved', isDarkMode: true),
      AppColors.approvedDark,
    );
  });
});
```

### Accessibility Tests
```dart
// Test contrast ratios
test('new colors meet accessibility standards', () {
  // Test focus color contrast
  final focusOnSurface = calculateContrastRatio(
    AppColors.focus,
    AppColors.surfaceLight,
  );
  expect(focusOnSurface, greaterThan(4.5)); // WCAG AA

  final focusDarkOnSurface = calculateContrastRatio(
    AppColors.focusDark,
    AppColors.surfaceDark,
  );
  expect(focusDarkOnSurface, greaterThan(4.5)); // WCAG AA
});
```

### Widget Tests
```dart
testWidgets('new colors work in theme switching', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Container(
        color: AppColors.getFocusColor(false), // Light mode
      ),
      initialThemeMode: ThemeMode.light,
    ),
  );

  // Verify light mode color
  final lightContainer = tester.widget<Container>(find.byType(Container));
  expect(lightContainer.color, AppColors.focus);

  // Switch to dark mode
  await ThemeTestUtils.switchToDarkTheme(tester);

  // Should update to dark color if using context extensions
  // Manual verification needed for static usage
});
```

## 📐 Step 7: Accessibility Considerations

### Contrast Ratio Verification
```dart
// Use tools to verify WCAG compliance
double calculateContrastRatio(Color foreground, Color background) {
  // Implementation of WCAG contrast ratio calculation
  // Should return >= 4.5 for AA compliance
  // Should return >= 7.0 for AAA compliance
}
```

### Color Blindness Testing
- Test colors with common color blindness simulators
- Ensure semantic meaning isn't lost with color alone
- Use additional visual indicators (icons, patterns)

### High Contrast Mode Support
```dart
// Support for high contrast preferences
static Color getHighContrastColor(Color baseColor, bool isDarkMode) {
  // Return higher contrast version if accessibility settings require it
  final isHighContrast = PlatformDispatcher.instance.accessibilityFeatures.highContrast;
  
  if (isHighContrast) {
    return isDarkMode ? Colors.white : Colors.black;
  }
  
  return baseColor;
}
```

## ✅ Step 8: Documentation

### Update Color Documentation
Add your new colors to the semantic colors documentation:

```markdown
### Focus Colors
```dart
// For highlighting active/focused elements
static const Color focus = Color(0xFF6366F1);
static const Color focusDark = Color(0xFF818CF8);

// Usage
Container(
  color: AppColors.getFocusColor(context.isDarkMode),
  child: focusedContent,
)
```

### Update Usage Patterns
Add examples of how to use the new colors in the usage patterns documentation.

## ❌ Common Mistakes to Avoid

### Don't Skip Dark Mode Variants
```dart
// ❌ Bad - only light mode color
static const Color newFeature = Color(0xFF1234AB);

// ✅ Good - both light and dark mode
static const Color newFeature = Color(0xFF1234AB);
static const Color newFeatureDark = Color(0xFF5678CD);
```

### Don't Use Inconsistent Naming
```dart
// ❌ Bad - inconsistent naming
static const Color focusBlue = Color(0xFF6366F1);
static const Color focusedBlue = Color(0xFF818CF8);

// ✅ Good - consistent naming
static const Color focus = Color(0xFF6366F1);
static const Color focusDark = Color(0xFF818CF8);
```

### Don't Forget Helper Methods
```dart
// ❌ Bad - forces manual theme checking everywhere
Container(
  color: context.isDarkMode ? AppColors.focusDark : AppColors.focus,
)

// ✅ Good - provides helper method
Container(
  color: AppColors.getFocusColor(context.isDarkMode),
)
```

### Don't Skip Accessibility Testing
- Always verify contrast ratios
- Test with color blindness simulators
- Ensure usability without color alone

## 🔄 Migration Strategy

### For Existing Hardcoded Colors
1. **Identify the semantic purpose** of the hardcoded color
2. **Choose appropriate color values** that match the design system
3. **Add to AppColors** following the naming convention
4. **Create helper methods** for easy usage
5. **Add context extensions** if frequently used
6. **Update all usage locations** to use the new semantic color
7. **Add comprehensive tests** for the new colors
8. **Update documentation** with usage examples

### Gradual Rollout
1. Add new colors to the system
2. Update one component at a time
3. Test each component thoroughly
4. Document usage patterns as you go
5. Share knowledge with the team

## 📚 Related Documentation

- [Semantic Colors Guide](semantic-colors.md) - Understanding the current color system
- [Usage Patterns](usage-patterns.md) - How to use colors in components
- [Context Extensions](context-extensions.md) - Accessing colors through context
- [Testing Requirements](../maintenance/testing-requirements.md) - Proper testing procedures

---

**Follow this systematic approach to add new semantic colors that maintain the consistency, accessibility, and maintainability of the FlashMaster theme system.**

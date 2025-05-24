# Migration Guide

**Converting Hardcoded Colors to Theme-Aware Implementation**

## 🎯 Migration Overview

This guide helps you convert existing components with hardcoded colors to use the FlashMaster theme system.

## 🔍 Step 1: Identify Hardcoded Colors

### Search Patterns
```bash
# Find hardcoded colors
grep -r "Color(0x" lib/
grep -r "Colors\." lib/
grep -r "#[0-9A-Fa-f]" lib/

# Find potential theme issues
grep -r "TextStyle(" lib/
grep -r "BoxDecoration(" lib/
```

### Common Hardcoded Patterns
```dart
// ❌ Hardcoded color values
Color(0xFF123456)
Colors.grey.shade200
Colors.blue
#FF0000

// ❌ Hardcoded text styles
TextStyle(color: Colors.black, fontSize: 16)

// ❌ Hardcoded decorations
BoxDecoration(color: Colors.white)
```

## 🔄 Step 2: Migration Patterns

### Background Colors
```dart
// Before
Container(
  color: Colors.grey.shade100,
  child: content,
)

// After
Container(
  color: context.surfaceColor,
  child: content,
)
```

### Text Colors
```dart
// Before
Text(
  'Content',
  style: TextStyle(
    color: Colors.black87,
    fontSize: 16,
  ),
)

// After
Text(
  'Content',
  style: context.bodyLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
  ),
)
```

### Primary/Brand Colors
```dart
// Before
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF2196F3),
  ),
  child: Text('Button'),
)

// After
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: context.primaryColor,
  ),
  child: Text('Button'),
)
```

### Feedback Colors
```dart
// Before
Container(
  color: Colors.red,
  child: Text('Error'),
)

// After
Container(
  color: context.errorColor,
  child: Text('Error'),
)
```

## 🎨 Step 3: Complex Migrations

### Custom Color Classes
```dart
// Before
class CustomColors {
  static const primary = Color(0xFF1976D2);
  static const secondary = Color(0xFF424242);
}

// After - Add to AppColors
// In colors.dart:
static const Color customPrimary = Color(0xFF1976D2);
static const Color customPrimaryDark = Color(0xFF42A5F5);
static const Color customSecondary = Color(0xFF424242);
static const Color customSecondaryDark = Color(0xFF757575);
```

### Conditional Styling
```dart
// Before
Container(
  color: widget.isSelected ? Colors.blue : Colors.grey,
)

// After
Container(
  color: widget.isSelected 
    ? context.primaryColor 
    : AppColors.getTextSecondary(context.isDarkMode),
)
```

### Gradient Migrations
```dart
// Before
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue.shade100, Colors.blue.shade200],
    ),
  ),
)

// After
Container(
  decoration: BoxDecoration(
    gradient: ThemedColors.cardGradient(context),
  ),
)
```

## 🧪 Step 4: Testing Migration

### Before/After Comparison
```dart
testWidgets('migrated component matches original appearance', (tester) async {
  // Test in light mode
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: MigratedComponent(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  
  // Verify appearance matches original design
  await expectLater(
    find.byType(MigratedComponent),
    matchesGoldenFile('migrated_component_light.png'),
  );
  
  // Test in dark mode (new capability)
  await ThemeTestUtils.switchToDarkTheme(tester);
  
  await expectLater(
    find.byType(MigratedComponent),
    matchesGoldenFile('migrated_component_dark.png'),
  );
});
```

## 📋 Migration Checklist

### ✅ For Each Component
- [ ] Replace hardcoded colors with semantic colors
- [ ] Add dark mode support
- [ ] Update text styles to use theme typography
- [ ] Test in both light and dark modes
- [ ] Verify accessibility compliance
- [ ] Update component tests
- [ ] Add golden file tests if visual

### ✅ Quality Assurance
- [ ] No hardcoded colors remain
- [ ] Dark mode looks intentional, not broken
- [ ] Animations work smoothly
- [ ] Performance is maintained
- [ ] Accessibility standards met

## 🔧 Automated Migration Tools

### VS Code Snippets
```json
{
  "theme-aware-container": {
    "prefix": "tcontainer",
    "body": [
      "Container(",
      "  decoration: BoxDecoration(",
      "    color: context.surfaceColor,",
      "    borderRadius: context.cardBorderRadius,",
      "    boxShadow: context.cardShadow,",
      "  ),",
      "  padding: context.cardPadding,",
      "  child: $1,",
      ")"
    ]
  }
}
```

### Find and Replace Patterns
```bash
# Replace common hardcoded colors
sed -i 's/Colors\.grey\.shade200/context.surfaceColor/g' lib/**/*.dart
sed -i 's/Colors\.black87/AppColors.getTextPrimary(context.isDarkMode)/g' lib/**/*.dart
```

## 🎯 Common Migration Challenges

### Challenge 1: Complex Color Logic
```dart
// Before - complex conditional
Color getStatusColor(String status) {
  if (status == 'active') return Colors.green;
  if (status == 'warning') return Colors.orange;
  return Colors.red;
}

// After - use semantic helper
Color getStatusColor(String status, BuildContext context) {
  return AppColors.getStatusColor(status, isDarkMode: context.isDarkMode);
}
```

### Challenge 2: Third-Party Widgets
```dart
// When third-party widgets don't support themes
Theme(
  data: Theme.of(context).copyWith(
    // Override specific colors for third-party widget
    primaryColor: context.primaryColor,
  ),
  child: ThirdPartyWidget(),
)
```

## 📚 Post-Migration Best Practices

### Code Review
- Verify all changes follow theme patterns
- Check dark mode appearance
- Test accessibility compliance
- Confirm performance is maintained

### Documentation
- Update component documentation
- Add theme usage examples
- Document any custom patterns used

### Monitoring
- Watch for theme-related issues
- Monitor performance metrics
- Gather user feedback on dark mode

---

**Systematic migration ensures consistent theme implementation while maintaining design quality and adding dark mode support.**

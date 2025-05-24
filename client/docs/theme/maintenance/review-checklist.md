# Code Review Checklist for Theme Consistency

**Comprehensive Checklist for Theme-Related Code Reviews**

## 🎯 Pre-Review Quick Check

### ✅ Basic Theme Compliance
- [ ] No hardcoded colors (search for `Color(0x`, `Colors.`, hex values)
- [ ] Uses semantic color names (`AppColors.primary` vs `Colors.blue`)
- [ ] Includes dark mode support where applicable
- [ ] Uses theme typography (`context.bodyLarge` vs custom TextStyle)
- [ ] Tests included for theme-related changes

## 🎨 Color Usage Review

### ✅ Semantic Color Usage
- [ ] **Primary Brand Colors**: Uses `AppColors.primary`/`primaryDark`
- [ ] **Background Colors**: Uses `context.surfaceColor`/`backgroundColor`
- [ ] **Text Colors**: Uses `AppColors.getTextPrimary(isDarkMode)`
- [ ] **Feedback Colors**: Uses `context.successColor`/`errorColor`/`warningColor`
- [ ] **Category Colors**: Uses `AppColors.getCategoryColor()`
- [ ] **Status Colors**: Uses appropriate semantic methods

### ✅ Dark Mode Support
- [ ] All custom colors have dark mode variants
- [ ] Conditional styling uses `context.isDarkMode`
- [ ] Contrast ratios maintained (>4.5 for AA compliance)
- [ ] No hardcoded light-only or dark-only colors

### ❌ Color Anti-Patterns to Reject
- [ ] `Colors.grey.shade200` → Use `context.surfaceColor`
- [ ] `Color(0xFF123456)` → Add to AppColors system
- [ ] Single color for both light/dark → Add dark variant
- [ ] Hardcoded opacity → Use semantic color with opacity

## 📝 Typography Review

### ✅ Typography Standards
- [ ] **Material 3 Scale**: Uses `context.bodyLarge`, `titleMedium`, etc.
- [ ] **Custom Styles**: Extends theme typography vs creating new TextStyle
- [ ] **Color Consistency**: Text colors use theme-aware colors
- [ ] **Accessibility**: Supports text scaling (1.0-2.0x)

### ✅ Typography Patterns
```dart
// ✅ Good - extends theme typography
Text(
  'Content',
  style: context.bodyLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
    fontWeight: FontWeight.w600,
  ),
)

// ❌ Bad - custom typography
Text(
  'Content',
  style: TextStyle(
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w600,
  ),
)
```

## 🧩 Component Review Standards

### ✅ Theme-Aware Components
- [ ] **Container Colors**: Uses `context.surfaceColor`
- [ ] **Decorations**: Uses `ThemedComponents.cardDecoration()`
- [ ] **Borders**: Uses theme-appropriate border colors
- [ ] **Shadows**: Uses `context.cardShadow` or theme shadows
- [ ] **Gradients**: Uses `ThemedColors.cardGradient()`

### ✅ Interactive Elements
- [ ] **Buttons**: Uses theme button styles or extends them
- [ ] **Input Fields**: Uses theme input decoration
- [ ] **Focus States**: Uses `AppColors.getFocusColor()`
- [ ] **Hover States**: Implements theme-aware hover colors

## 🔧 Context Extensions Usage

### ✅ Proper Context Access
- [ ] Uses `context.primaryColor` vs `Theme.of(context).colorScheme.primary`
- [ ] Uses `context.isDarkMode` for theme checks
- [ ] Uses `context.bodyLarge` for typography
- [ ] Caches multiple accesses: `final appTheme = context.appTheme`

### ✅ Extension Patterns
```dart
// ✅ Good - clean context usage
Container(
  color: context.surfaceColor,
  child: Text(
    'Content',
    style: context.bodyLarge,
  ),
)

// ❌ Verbose - direct theme access
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Content',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
)
```

## 🧪 Testing Requirements

### ✅ Theme Test Coverage
- [ ] **Light Mode Test**: Verifies light theme appearance
- [ ] **Dark Mode Test**: Verifies dark theme appearance
- [ ] **Theme Switching**: Tests theme toggle functionality
- [ ] **Accessibility**: Tests with different text scales
- [ ] **Performance**: Verifies smooth theme transitions

### ✅ Required Test Patterns
```dart
testWidgets('adapts to theme changes', (tester) async {
  // Test light mode
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: YourWidget(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  
  ThemeTestUtils.expectThemeColors(
    tester.element(find.byType(YourWidget)),
    false, // shouldBeDarkMode
  );
  
  // Test dark mode
  await ThemeTestUtils.switchToDarkTheme(tester);
  
  ThemeTestUtils.expectThemeColors(
    tester.element(find.byType(YourWidget)),
    true, // shouldBeDarkMode
  );
});
```

## 📱 Responsive Design Review

### ✅ Responsive Theme Usage
- [ ] **Adaptive Sizing**: Uses responsive spacing/sizing
- [ ] **Platform Adaptation**: Considers iOS/Android differences
- [ ] **Screen Sizes**: Works on phone/tablet/desktop
- [ ] **Orientation**: Handles portrait/landscape correctly

## ⚡ Performance Review

### ✅ Performance Standards
- [ ] **RepaintBoundary**: Used for animated theme elements
- [ ] **Efficient Rebuilds**: Uses Consumer/Selector appropriately
- [ ] **Cached Access**: Caches multiple theme property accesses
- [ ] **Animation Performance**: Smooth 60fps theme transitions

### ✅ Performance Patterns
```dart
// ✅ Good - cached theme access
Widget build(BuildContext context) {
  final appTheme = context.appTheme;
  final isDark = context.isDarkMode;
  
  return RepaintBoundary(
    child: AnimatedContainer(
      duration: appTheme.themeTransitionDuration!,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    ),
  );
}
```

## 🔍 Code Quality Standards

### ✅ Code Organization
- [ ] **File Structure**: Theme changes in appropriate files
- [ ] **Naming**: Follows semantic naming conventions
- [ ] **Documentation**: Comments explain theme customizations
- [ ] **Consistency**: Matches existing theme patterns

### ✅ Maintainability
- [ ] **DRY Principle**: Reuses existing theme utilities
- [ ] **Extensibility**: Easy to add new theme variants
- [ ] **Readability**: Clear, self-documenting code
- [ ] **Error Handling**: Graceful fallbacks for theme properties

## 🎯 Priority Review Areas

### 🔴 Critical (Must Fix)
- Hardcoded colors that break dark mode
- Missing accessibility contrast requirements
- Performance issues during theme switching
- Breaking existing theme patterns

### 🟡 Important (Should Fix)
- Non-semantic color usage
- Missing dark mode variants
- Inconsistent typography patterns
- Missing theme tests

### 🟢 Nice to Have (Consider)
- Additional theme customization options
- Enhanced animation effects
- Improved developer experience utilities
- Extended accessibility features

## 📋 Review Approval Criteria

### ✅ Ready for Approval
- [ ] All color usage is semantic and theme-aware
- [ ] Dark mode support is complete and tested
- [ ] Typography follows Material 3 standards
- [ ] Performance is maintained during theme operations
- [ ] Tests cover light/dark mode scenarios
- [ ] Code follows established patterns
- [ ] Accessibility standards are met
- [ ] Documentation is updated if needed

### ❌ Needs Work Before Approval
- Any hardcoded colors remain
- Dark mode is broken or missing
- Theme switching causes performance issues
- Tests are missing or inadequate
- Accessibility violations exist
- Code doesn't follow established patterns

## 🔧 Review Tools and Commands

### Quick Search Commands
```bash
# Find hardcoded colors
grep -r "Color(0x" lib/
grep -r "Colors\." lib/

# Find missing dark mode checks
grep -r "isDarkMode" lib/ --include="*.dart"

# Find potential theme issues
grep -r "TextStyle(" lib/
grep -r "BoxDecoration(" lib/
```

### Test Commands
```bash
# Run theme tests
flutter test test/theme/

# Run with coverage
flutter test --coverage test/theme/

# Run accessibility tests
flutter test test/accessibility/
```

---

**Use this checklist to ensure consistent, maintainable, and accessible theme implementation across the FlashMaster application.**

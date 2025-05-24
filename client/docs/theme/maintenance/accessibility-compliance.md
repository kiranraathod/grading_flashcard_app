# Accessibility Compliance for Theme System

**WCAG 2.1 AA Compliance Standards and Verification**

## 🎯 Accessibility Standards

### WCAG 2.1 AA Requirements
- **Contrast Ratio**: ≥4.5:1 for normal text, ≥3:1 for large text
- **Color Independence**: Information not conveyed by color alone
- **Text Scaling**: Support up to 200% scaling without horizontal scrolling
- **Focus Indicators**: Visible focus states for interactive elements

## 🎨 Color Accessibility

### Contrast Ratio Testing
```dart
double calculateContrastRatio(Color foreground, Color background) {
  final fLum = _getLuminance(foreground);
  final bLum = _getLuminance(background);
  final lighter = math.max(fLum, bLum);
  final darker = math.min(fLum, bLum);
  return (lighter + 0.05) / (darker + 0.05);
}

// Usage in tests
test('primary text meets contrast requirements', () {
  final ratio = calculateContrastRatio(
    AppColors.textPrimary,
    AppColors.surfaceLight,
  );
  expect(ratio, greaterThan(4.5)); // WCAG AA
});
```

### Color-Independent Design
```dart
// ✅ Good - uses icon + color + text
ListTile(
  leading: Icon(
    Icons.check_circle,
    color: AppColors.success,
  ),
  title: Text('Success: Task completed'),
  subtitle: Text('✓ Verified'), // Additional indicator
)

// ❌ Bad - color only
Container(
  color: AppColors.success, // Only indicator
  child: Text('Success'),
)
```

## 🔤 Typography Accessibility

### Text Scaling Support
```dart
// Responsive text that scales properly
Text(
  'Scalable content',
  style: context.bodyLarge?.copyWith(
    // Automatically scales with system settings
    color: AppColors.getTextPrimary(context.isDarkMode),
  ),
  // Clamp scaling to prevent extreme sizes
  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 2.0),
)
```

### Font Size Guidelines
- **Minimum**: 16px for body text (scales to 32px at 200%)
- **Touch Targets**: Minimum 44px tap targets
- **Line Height**: 1.4-1.6 for readability

## 🎯 Focus and Navigation

### Focus Indicators
```dart
// Theme-aware focus styling
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: hasFocus 
        ? AppColors.getFocusColor(context.isDarkMode)
        : Colors.transparent,
      width: 2,
    ),
    borderRadius: context.buttonBorderRadius,
  ),
  child: button,
)
```

### Semantic Markup
```dart
Semantics(
  button: true,
  enabled: isEnabled,
  label: 'Switch to ${context.isDarkMode ? 'light' : 'dark'} theme',
  child: ThemeToggleButton(),
)
```

## 🧪 Accessibility Testing

### Automated Testing
```dart
// Test text scaling
testWidgets('supports text scaling', (tester) async {
  for (double scale in [1.0, 1.5, 2.0]) {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaleFactor: scale),
        child: YourWidget(),
      ),
    );
    
    // Verify no overflow
    expect(tester.takeException(), isNull);
  }
});

// Test contrast ratios
group('Accessibility', () {
  test('all theme colors meet WCAG AA standards', () {
    final colorPairs = [
      (AppColors.textPrimary, AppColors.surfaceLight),
      (AppColors.textPrimaryDark, AppColors.surfaceDark),
      (AppColors.primary, Colors.white),
      // ... test all critical color combinations
    ];
    
    for (final (fg, bg) in colorPairs) {
      final ratio = calculateContrastRatio(fg, bg);
      expect(ratio, greaterThan(4.5), 
        reason: 'Insufficient contrast: $fg on $bg');
    }
  });
});
```

### Manual Testing Checklist
- [ ] Screen reader compatibility (TalkBack/VoiceOver)
- [ ] High contrast mode support
- [ ] Keyboard navigation functionality
- [ ] Voice control compatibility
- [ ] Reduced motion preferences

## 🔧 Platform-Specific Considerations

### iOS Accessibility
```dart
// Respect iOS accessibility settings
final accessibilityFeatures = MediaQuery.of(context).accessibilityFeatures;

if (accessibilityFeatures.boldText) {
  // Use bolder font weights
}

if (accessibilityFeatures.highContrast) {
  // Use higher contrast colors
}
```

### Android Accessibility
```dart
// Material You and accessibility
final dynamicColors = await DynamicColorPlugin.getCorePalette();
if (dynamicColors != null && accessibilityConsidered) {
  // Use system colors with accessibility validation
}
```

## 📚 Resources and Tools

### Testing Tools
- **Flutter Inspector**: Check semantic tree
- **Accessibility Scanner** (Android): Automated accessibility testing
- **Colour Contrast Analyser**: Manual contrast ratio testing
- **axe DevTools**: Web accessibility testing

### Design Guidelines
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [Apple Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

**Accessibility compliance ensures the FlashMaster theme system is usable by everyone, meeting international standards for inclusive design.**

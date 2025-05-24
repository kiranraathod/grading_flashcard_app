# Theme Testing Requirements

**Essential Testing Standards for Theme-Related Changes**

## 🎯 Testing Overview

All theme-related changes must include comprehensive tests covering light/dark modes, accessibility, and performance.

## 🧪 Required Test Categories

### 1. Unit Tests (`test/theme/unit/`)
```dart
// Test color values and helper methods
group('AppColors', () {
  test('helper methods return correct colors', () {
    expect(AppColors.getGradeColor('A', isDarkMode: false), AppColors.gradeA);
    expect(AppColors.getGradeColor('A', isDarkMode: true), AppColors.gradeADark);
  });
});
```

### 2. Widget Tests (`test/theme/widget/`)
```dart
// Test component theme adaptation
testWidgets('component adapts to theme changes', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: YourComponent(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  
  // Verify light mode
  ThemeTestUtils.expectThemeColors(
    tester.element(find.byType(YourComponent)),
    false,
  );
  
  // Switch to dark mode
  await ThemeTestUtils.switchToDarkTheme(tester);
  
  // Verify dark mode
  ThemeTestUtils.expectThemeColors(
    tester.element(find.byType(YourComponent)),
    true,
  );
});
```

### 3. Performance Tests (`test/theme/performance/`)
```dart
// Test theme switching performance
testWidgets('theme switching is performant', (tester) async {
  await tester.pumpWidget(/* setup */);
  
  await ThemeTestUtils.expectPerformantThemeSwitch(
    tester,
    maxDuration: Duration(milliseconds: 200),
  );
});
```

### 4. Accessibility Tests (`test/theme/accessibility/`)
```dart
// Test contrast ratios and text scaling
test('colors meet WCAG standards', () {
  final contrastRatio = calculateContrastRatio(
    AppColors.primary,
    AppColors.surfaceLight,
  );
  expect(contrastRatio, greaterThan(4.5)); // WCAG AA
});
```

### 5. Golden Tests (`test/theme/golden/`)
```dart
// Visual regression tests
testWidgets('component appearance is consistent', (tester) async {
  await tester.pumpWidget(/* setup */);
  
  await expectLater(
    find.byType(YourComponent),
    matchesGoldenFile('component_light.png'),
  );
});
```

## 📋 Test Checklist for PRs

### ✅ Required for All Theme Changes
- [ ] Light mode widget test
- [ ] Dark mode widget test  
- [ ] Theme switching test
- [ ] Accessibility compliance test
- [ ] Performance benchmark test

### ✅ Required for New Components
- [ ] Golden file test (light mode)
- [ ] Golden file test (dark mode)
- [ ] Responsive layout test
- [ ] Text scaling test (1.0x to 2.0x)

### ✅ Required for Color Changes
- [ ] Contrast ratio verification
- [ ] Helper method unit tests
- [ ] Visual regression tests
- [ ] Color blindness consideration

## 🔧 Testing Utilities

### ThemeTestUtils Usage
```dart
// Standard theme test setup
await tester.pumpWidget(
  ThemeTestUtils.createThemeTestWidget(
    child: ComponentUnderTest(),
    initialThemeMode: ThemeMode.light,
  ),
);

// Theme switching helpers
await ThemeTestUtils.switchToDarkTheme(tester);
await ThemeTestUtils.switchToLightTheme(tester);
await ThemeTestUtils.toggleTheme(tester);

// Performance testing
await ThemeTestUtils.expectPerformantThemeSwitch(tester);

// Color verification
ThemeTestUtils.expectThemeColors(context, shouldBeDarkMode);
```

## ⚡ Performance Standards

### Required Benchmarks
- **Theme Switch Time**: <150ms (target: <200ms)
- **Animation Frame Rate**: 60fps maintained
- **Memory Usage**: No leaks during theme changes
- **CPU Usage**: Minimal impact during transitions

### Performance Test Pattern
```dart
testWidgets('theme performance test', (tester) async {
  final stopwatch = Stopwatch();
  
  await tester.pumpWidget(/* setup */);
  
  stopwatch.start();
  await ThemeTestUtils.toggleTheme(tester);
  stopwatch.stop();
  
  expect(
    stopwatch.elapsed,
    lessThan(Duration(milliseconds: 150)),
  );
});
```

## 🎨 Accessibility Testing

### WCAG Compliance Requirements
- **AA Standard**: Contrast ratio ≥ 4.5:1
- **AAA Standard**: Contrast ratio ≥ 7:1 (preferred)
- **Text Scaling**: Support 1.0x to 2.0x scaling
- **Color Independence**: Semantic meaning without color

### Accessibility Test Examples
```dart
// Contrast ratio test
test('text has sufficient contrast', () {
  expect(
    calculateContrastRatio(AppColors.textPrimary, AppColors.surfaceLight),
    greaterThan(4.5),
  );
});

// Text scaling test
testWidgets('supports text scaling', (tester) async {
  for (double scale in [1.0, 1.5, 2.0]) {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaleFactor: scale),
        child: YourWidget(),
      ),
    );
    
    expect(tester.takeException(), isNull);
  }
});
```

## 🔍 Test Coverage Requirements

### Minimum Coverage Standards
- **Theme Provider**: 95% coverage
- **Color Utilities**: 90% coverage
- **Theme Extensions**: 85% coverage
- **Context Extensions**: 90% coverage
- **Component Theming**: 80% coverage

### Coverage Commands
```bash
# Generate coverage report
flutter test --coverage

# View coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📱 Multi-Platform Testing

### Test Matrix
- **iOS**: iPhone/iPad simulators
- **Android**: Various API levels (21+)
- **Web**: Chrome/Firefox/Safari
- **Desktop**: Windows/macOS/Linux

### Platform-Specific Considerations
```dart
testWidgets('platform adaptation', (tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  
  await tester.pumpWidget(/* test iOS behavior */);
  
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  
  await tester.pumpWidget(/* test Android behavior */);
  
  debugDefaultTargetPlatformOverride = null;
});
```

---

**Comprehensive testing ensures theme reliability, performance, and accessibility across all supported platforms and use cases.**

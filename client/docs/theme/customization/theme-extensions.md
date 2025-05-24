# Custom Theme Extensions Development

**Advanced Guide to Extending the FlashMaster Theme System**

## 🎯 Overview

This guide explains how to create and manage custom theme extensions in FlashMaster, allowing you to add app-specific theme properties that aren't covered by Material 3's standard theme system.

## 🏗️ Understanding Theme Extensions

### What Are Theme Extensions?
Theme extensions allow you to add custom properties to Flutter's theme system that can be accessed alongside standard theme properties. They provide:

- **Type Safety**: Compile-time checking for custom theme properties
- **Theme Switching**: Automatic adaptation when themes change
- **Lerp Support**: Smooth animations between theme changes
- **Context Access**: Easy access through context extensions

### Current Theme Extension Structure
```dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // Custom gradient colors
  final Color? cardGradientStart;
  final Color? cardGradientEnd;
  final Color? interviewGradientStart;
  final Color? interviewGradientEnd;
  
  // Custom feedback colors
  final Color? successColor;
  final Color? warningColor;
  
  // Custom visual effects
  final List<BoxShadow>? cardShadow;
  
  // Search-specific properties
  final Color? searchBarBackground;
  final Color? searchBarBorder;
  final Color? searchBarInnerShadow;
  final Color? primaryDarkHover;
}
```

## 🔧 Step 1: Adding New Properties

### Example: Adding Animation Properties
```dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // ... existing properties ...
  
  // New animation properties
  final Duration? themeTransitionDuration;
  final Curve? themeTransitionCurve;
  final Duration? cardHoverDuration;
  final Curve? cardHoverCurve;
  
  // New spacing properties
  final double? cardSpacing;
  final double? componentSpacing;
  final EdgeInsets? screenMargin;
  
  // New border properties
  final BorderRadius? largeBorderRadius;
  final BorderRadius? extraLargeBorderRadius;
  final double? borderWidth;
  final double? focusBorderWidth;

  const AppThemeExtension({
    // ... existing parameters ...
    this.themeTransitionDuration,
    this.themeTransitionCurve,
    this.cardHoverDuration,
    this.cardHoverCurve,
    this.cardSpacing,
    this.componentSpacing,
    this.screenMargin,
    this.largeBorderRadius,
    this.extraLargeBorderRadius,
    this.borderWidth,
    this.focusBorderWidth,
  });
}
```

### Example: Adding Complex Visual Properties
```dart
// Custom gradient definitions
final LinearGradient? primaryGradient;
final LinearGradient? secondaryGradient;
final LinearGradient? backgroundGradient;

// Custom decoration properties
final BoxDecoration? cardDecoration;
final BoxDecoration? buttonDecoration;
final BoxDecoration? inputDecoration;

// Custom text styles (beyond Material 3)
final TextStyle? brandTextStyle;
final TextStyle? captionTextStyle;
final TextStyle? overlineTextStyle;
```

## 🎨 Step 2: Define Light and Dark Variants

### Light Theme Extension
```dart
static const light = AppThemeExtension(
  // ... existing light properties ...
  
  // Animation properties
  themeTransitionDuration: Duration(milliseconds: 150),
  themeTransitionCurve: Curves.easeOutQuart,
  cardHoverDuration: Duration(milliseconds: 100),
  cardHoverCurve: Curves.easeOutCubic,
  
  // Spacing properties
  cardSpacing: 16.0,
  componentSpacing: 24.0,
  screenMargin: EdgeInsets.all(16.0),
  
  // Border properties
  largeBorderRadius: BorderRadius.all(Radius.circular(20.0)),
  extraLargeBorderRadius: BorderRadius.all(Radius.circular(28.0)),
  borderWidth: 1.0,
  focusBorderWidth: 2.0,
  
  // Custom gradients
  primaryGradient: LinearGradient(
    colors: [Color(0xFF009688), Color(0xFF00796B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  
  // Custom decorations
  cardDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
    boxShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
);
```

### Dark Theme Extension
```dart
static const dark = AppThemeExtension(
  // ... existing dark properties ...
  
  // Same animation properties (usually consistent)
  themeTransitionDuration: Duration(milliseconds: 150),
  themeTransitionCurve: Curves.easeOutQuart,
  cardHoverDuration: Duration(milliseconds: 100),
  cardHoverCurve: Curves.easeOutCubic,
  
  // Same spacing properties
  cardSpacing: 16.0,
  componentSpacing: 24.0,
  screenMargin: EdgeInsets.all(16.0),
  
  // Same border properties
  largeBorderRadius: BorderRadius.all(Radius.circular(20.0)),
  extraLargeBorderRadius: BorderRadius.all(Radius.circular(28.0)),
  borderWidth: 1.0,
  focusBorderWidth: 2.0,
  
  // Dark mode gradients
  primaryGradient: LinearGradient(
    colors: [Color(0xFF4DB6AC), Color(0xFF80CBC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  
  // Dark mode decorations
  cardDecoration: BoxDecoration(
    color: Color(0xFF2A2A30),
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
    boxShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  ),
);
```

## 🔄 Step 3: Implement Required Methods

### CopyWith Method
```dart
@override
AppThemeExtension copyWith({
  // ... existing parameters ...
  Duration? themeTransitionDuration,
  Curve? themeTransitionCurve,
  Duration? cardHoverDuration,
  Curve? cardHoverCurve,
  double? cardSpacing,
  double? componentSpacing,
  EdgeInsets? screenMargin,
  BorderRadius? largeBorderRadius,
  BorderRadius? extraLargeBorderRadius,
  double? borderWidth,
  double? focusBorderWidth,
  LinearGradient? primaryGradient,
  BoxDecoration? cardDecoration,
}) {
  return AppThemeExtension(
    // ... existing assignments ...
    themeTransitionDuration: themeTransitionDuration ?? this.themeTransitionDuration,
    themeTransitionCurve: themeTransitionCurve ?? this.themeTransitionCurve,
    cardHoverDuration: cardHoverDuration ?? this.cardHoverDuration,
    cardHoverCurve: cardHoverCurve ?? this.cardHoverCurve,
    cardSpacing: cardSpacing ?? this.cardSpacing,
    componentSpacing: componentSpacing ?? this.componentSpacing,
    screenMargin: screenMargin ?? this.screenMargin,
    largeBorderRadius: largeBorderRadius ?? this.largeBorderRadius,
    extraLargeBorderRadius: extraLargeBorderRadius ?? this.extraLargeBorderRadius,
    borderWidth: borderWidth ?? this.borderWidth,
    focusBorderWidth: focusBorderWidth ?? this.focusBorderWidth,
    primaryGradient: primaryGradient ?? this.primaryGradient,
    cardDecoration: cardDecoration ?? this.cardDecoration,
  );
}
```

### Lerp Method for Smooth Transitions
```dart
@override
AppThemeExtension lerp(AppThemeExtension? other, double t) {
  if (other is! AppThemeExtension) return this;
  
  return AppThemeExtension(
    // ... existing lerp assignments ...
    
    // Duration lerping
    themeTransitionDuration: t < 0.5 
      ? themeTransitionDuration 
      : other.themeTransitionDuration,
    
    // Curve lerping (discrete)
    themeTransitionCurve: t < 0.5 
      ? themeTransitionCurve 
      : other.themeTransitionCurve,
    
    // Numeric lerping
    cardSpacing: lerpDouble(cardSpacing, other.cardSpacing, t),
    componentSpacing: lerpDouble(componentSpacing, other.componentSpacing, t),
    borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
    focusBorderWidth: lerpDouble(focusBorderWidth, other.focusBorderWidth, t),
    
    // EdgeInsets lerping
    screenMargin: EdgeInsets.lerp(screenMargin, other.screenMargin, t),
    
    // BorderRadius lerping
    largeBorderRadius: BorderRadius.lerp(largeBorderRadius, other.largeBorderRadius, t),
    extraLargeBorderRadius: BorderRadius.lerp(extraLargeBorderRadius, other.extraLargeBorderRadius, t),
    
    // Complex object lerping (often discrete)
    primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
    cardDecoration: t < 0.5 ? cardDecoration : other.cardDecoration,
  );
}
```

## 🔧 Step 4: Add Context Extensions

### Basic Property Access
```dart
// In lib/utils/theme_utils.dart
extension ThemeGetter on BuildContext {
  // ... existing getters ...
  
  // Animation properties
  Duration get themeTransitionDuration => appTheme.themeTransitionDuration!;
  Curve get themeTransitionCurve => appTheme.themeTransitionCurve!;
  Duration get cardHoverDuration => appTheme.cardHoverDuration!;
  Curve get cardHoverCurve => appTheme.cardHoverCurve!;
  
  // Spacing properties
  double get cardSpacing => appTheme.cardSpacing!;
  double get componentSpacing => appTheme.componentSpacing!;
  EdgeInsets get screenMargin => appTheme.screenMargin!;
  
  // Border properties
  BorderRadius get largeBorderRadius => appTheme.largeBorderRadius!;
  BorderRadius get extraLargeBorderRadius => appTheme.extraLargeBorderRadius!;
  double get borderWidth => appTheme.borderWidth!;
  double get focusBorderWidth => appTheme.focusBorderWidth!;
  
  // Visual properties
  LinearGradient get primaryGradient => appTheme.primaryGradient!;
  BoxDecoration get cardDecoration => appTheme.cardDecoration!;
}
```

### Convenience Methods
```dart
extension ThemeGetter on BuildContext {
  // ... existing methods ...
  
  // Animated container helper
  Widget animatedContainer({
    required Widget child,
    Color? color,
    BoxDecoration? decoration,
  }) {
    return AnimatedContainer(
      duration: themeTransitionDuration,
      curve: themeTransitionCurve,
      decoration: decoration ?? cardDecoration,
      child: child,
    );
  }
  
  // Hover animation helper
  Widget hoverContainer({
    required Widget child,
    required bool isHovered,
    Color? baseColor,
    Color? hoverColor,
  }) {
    return AnimatedContainer(
      duration: cardHoverDuration,
      curve: cardHoverCurve,
      color: isHovered ? hoverColor : baseColor,
      child: child,
    );
  }
  
  // Spaced column helper
  Widget spacedColumn({
    required List<Widget> children,
    double? spacing,
  }) {
    return Column(
      children: children
        .expand((child) => [child, SizedBox(height: spacing ?? componentSpacing)])
        .take(children.length * 2 - 1)
        .toList(),
    );
  }
}
```

## 🎨 Step 5: Advanced Extension Patterns

### Conditional Properties
```dart
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // ... existing properties ...
  
  // Properties that might be null in some themes
  final Color? premiumFeatureColor;
  final Gradient? premiumGradient;
  final TextStyle? premiumTextStyle;
  
  // Computed properties
  Color get effectivePremiumColor => premiumFeatureColor ?? primaryColor;
  
  // Conditional decorations
  BoxDecoration get premiumCardDecoration {
    if (premiumGradient != null) {
      return BoxDecoration(
        gradient: premiumGradient,
        borderRadius: largeBorderRadius,
        boxShadow: cardShadow,
      );
    }
    return cardDecoration;
  }
}
```

### Dynamic Properties Based on Platform
```dart
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // ... existing properties ...
  
  // Platform-specific properties
  final double? iOSBlurRadius;
  final double? androidElevation;
  final bool? useMaterialYou;
  
  // Platform-aware getters
  double get effectiveBlurRadius {
    if (Platform.isIOS) return iOSBlurRadius ?? 10.0;
    if (Platform.isAndroid) return androidElevation ?? 4.0;
    return 6.0; // Default for other platforms
  }
  
  bool get shouldUseMaterialYou {
    return Platform.isAndroid && 
           useMaterialYou == true && 
           // Check Android version >= 12
           true; // Simplified for example
  }
}
```

## 🧪 Step 6: Testing Custom Extensions

### Extension Property Tests
```dart
// test/theme/unit/theme_extensions_test.dart
group('AppThemeExtension', () {
  test('should have correct light theme properties', () {
    const extension = AppThemeExtension.light;
    
    expect(extension.themeTransitionDuration, Duration(milliseconds: 150));
    expect(extension.cardSpacing, 16.0);
    expect(extension.borderWidth, 1.0);
    expect(extension.largeBorderRadius, BorderRadius.all(Radius.circular(20.0)));
  });
  
  test('should have correct dark theme properties', () {
    const extension = AppThemeExtension.dark;
    
    expect(extension.themeTransitionDuration, Duration(milliseconds: 150));
    expect(extension.cardSpacing, 16.0);
    expect(extension.borderWidth, 1.0);
  });
  
  test('copyWith should work correctly', () {
    const original = AppThemeExtension.light;
    final copied = original.copyWith(
      cardSpacing: 20.0,
      borderWidth: 2.0,
    );
    
    expect(copied.cardSpacing, 20.0);
    expect(copied.borderWidth, 2.0);
    expect(copied.themeTransitionDuration, original.themeTransitionDuration);
  });
  
  test('lerp should interpolate correctly', () {
    const light = AppThemeExtension.light;
    const dark = AppThemeExtension.dark;
    
    final lerped = light.lerp(dark, 0.5);
    
    // Test numeric interpolation
    final expectedSpacing = (light.cardSpacing! + dark.cardSpacing!) / 2;
    expect(lerped?.cardSpacing, expectedSpacing);
    
    // Test discrete properties
    expect(lerped?.themeTransitionCurve, light.themeTransitionCurve);
  });
});
```

### Context Extension Tests
```dart
testWidgets('context extensions work with custom properties', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Builder(
        builder: (context) {
          // Test custom property access
          expect(context.cardSpacing, 16.0);
          expect(context.themeTransitionDuration, Duration(milliseconds: 150));
          expect(context.largeBorderRadius, BorderRadius.all(Radius.circular(20.0)));
          
          return Container();
        },
      ),
    ),
  );
});
```

### Animation Tests
```dart
testWidgets('custom animations work correctly', (tester) async {
  bool isHovered = false;
  
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: StatefulBuilder(
        builder: (context, setState) {
          return context.hoverContainer(
            isHovered: isHovered,
            baseColor: Colors.white,
            hoverColor: Colors.grey.shade100,
            child: GestureDetector(
              onTap: () => setState(() => isHovered = !isHovered),
              child: Text('Hover me'),
            ),
          );
        },
      ),
    ),
  );
  
  // Trigger hover
  await tester.tap(find.text('Hover me'));
  await tester.pump();
  
  // Verify animation is running
  expect(tester.binding.hasScheduledFrame, true);
  
  // Complete animation
  await tester.pumpAndSettle();
  
  // Verify final state
  final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  expect(container.color, Colors.grey.shade100);
});
```

## 🎨 Step 7: Real-World Usage Examples

### Custom Card with Extensions
```dart
class CustomCard extends StatelessWidget {
  final Widget child;
  final bool isPremium;
  final bool isHovered;
  
  const CustomCard({
    Key? key,
    required this.child,
    this.isPremium = false,
    this.isHovered = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: context.cardHoverDuration,
      curve: context.cardHoverCurve,
      margin: EdgeInsets.all(context.cardSpacing / 2),
      decoration: isPremium 
        ? context.appTheme.premiumCardDecoration 
        : context.cardDecoration.copyWith(
            border: Border.all(
              color: isHovered 
                ? context.primaryColor 
                : Colors.transparent,
              width: context.borderWidth,
            ),
          ),
      child: Padding(
        padding: EdgeInsets.all(context.cardSpacing),
        child: child,
      ),
    );
  }
}
```

### Responsive Layout with Extensions
```dart
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  
  const ResponsiveLayout({Key? key, required this.children}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.screenMargin,
      child: context.spacedColumn(
        spacing: context.componentSpacing,
        children: children,
      ),
    );
  }
}
```

### Themed Animation Container
```dart
class ThemedAnimationContainer extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final Color? backgroundColor;
  
  const ThemedAnimationContainer({
    Key? key,
    required this.child,
    required this.isVisible,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: context.themeTransitionDuration,
      curve: context.themeTransitionCurve,
      opacity: isVisible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: context.themeTransitionDuration,
        curve: context.themeTransitionCurve,
        decoration: BoxDecoration(
          color: backgroundColor ?? context.surfaceColor,
          borderRadius: context.largeBorderRadius,
          border: Border.all(
            color: context.outlineColor,
            width: context.borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

## ⚠️ Best Practices and Considerations

### Performance Considerations
```dart
// ✅ Good - Cache extension access
Widget build(BuildContext context) {
  final appTheme = context.appTheme;
  
  return AnimatedContainer(
    duration: appTheme.themeTransitionDuration!,
    curve: appTheme.themeTransitionCurve!,
    // ... other properties
  );
}

// ❌ Avoid - Multiple extension accesses
Widget build(BuildContext context) {
  return AnimatedContainer(
    duration: context.appTheme.themeTransitionDuration!,
    curve: context.appTheme.themeTransitionCurve!,
    // ... accessing context.appTheme multiple times
  );
}
```

### Null Safety Considerations
```dart
// ✅ Good - Null-safe access with fallbacks
Color get effectiveColor => customColor ?? defaultColor;

// ✅ Good - Null assertion when guaranteed
Duration get duration => appTheme.duration!; // When guaranteed non-null

// ❌ Avoid - Unsafe null access
Duration get duration => appTheme.duration; // Might be null
```

### Backward Compatibility
```dart
// ✅ Good - Provide defaults for new properties
@override
AppThemeExtension copyWith({
  Duration? newProperty,
  // ... other properties
}) {
  return AppThemeExtension(
    newProperty: newProperty ?? this.newProperty ?? Duration(milliseconds: 200), // Default
    // ... other assignments
  );
}
```

## 📚 Related Documentation

- [Adding Colors](adding-colors.md) - Learn about extending the color system
- [Brand Customization](brand-customization.md) - Customize brand-specific themes
- [Context Extensions](../developer-guide/context-extensions.md) - Understand context access patterns
- [Testing Requirements](../maintenance/testing-requirements.md) - Proper testing for extensions

---

**Custom theme extensions provide powerful ways to extend Flutter's theme system with app-specific properties while maintaining type safety and smooth theme transitions.**

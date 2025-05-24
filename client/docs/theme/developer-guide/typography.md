# Typography Guide

**Complete Guide to Theme-Aware Typography in FlashMaster**

## 🎯 Overview

FlashMaster implements Material 3 typography with Google Fonts (Inter) and comprehensive theme support. This guide covers proper usage of the typography system for consistent, accessible text styling.

## 🏗️ Material 3 Typography Scale

### Display Styles (Largest Text)
```dart
// Display Large - 57px - For hero text, major headings
Text('Hero Title', style: context.displayLarge);

// Display Medium - 45px - For prominent headings
Text('Major Heading', style: context.displayMedium);

// Display Small - 36px - For large headings
Text('Large Heading', style: context.displaySmall);
```

### Headline Styles
```dart
// Headline Large - 32px - For page titles
Text('Page Title', style: context.headlineLarge);

// Headline Medium - 28px - For section headers
Text('Section Header', style: context.headlineMedium);

// Headline Small - 24px - For subsection headers
Text('Subsection Header', style: context.headlineSmall);
```

### Title Styles
```dart
// Title Large - 22px - For component titles
Text('Component Title', style: context.titleLarge);

// Title Medium - 16px - For smaller titles, list headers
Text('List Header', style: context.titleMedium);

// Title Small - 14px - For smallest titles
Text('Small Title', style: context.titleSmall);
```

### Body Styles (Most Common)
```dart
// Body Large - 16px - For primary content
Text('Main content goes here', style: context.bodyLarge);

// Body Medium - 14px - For secondary content
Text('Additional information', style: context.bodyMedium);

// Body Small - 12px - For captions, small details
Text('Caption or small text', style: context.bodySmall);
```

### Label Styles
```dart
// Label Large - 14px - For prominent buttons
Text('BUTTON TEXT', style: context.labelLarge);

// Label Medium - 12px - For standard buttons
Text('Button', style: context.labelMedium);

// Label Small - 11px - For small buttons, chips
Text('Chip', style: context.labelSmall);
```

## 🎨 Theme-Aware Typography Patterns

### Basic Theme-Aware Text
```dart
Text(
  'Theme-aware text',
  style: context.bodyLarge?.copyWith(
    color: context.isDarkMode 
      ? AppColors.textPrimaryDark 
      : AppColors.textPrimary,
  ),
)
```

### Semantic Color Typography
```dart
// Primary text with theme color
Text(
  'Primary text',
  style: context.bodyLarge?.copyWith(
    color: context.primaryColor,
  ),
)

// Error text
Text(
  'Error message',
  style: context.bodyMedium?.copyWith(
    color: context.errorColor,
    fontWeight: FontWeight.w500,
  ),
)

// Success text
Text(
  'Success message',
  style: context.bodyMedium?.copyWith(
    color: context.successColor,
    fontWeight: FontWeight.w500,
  ),
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
    height: 1.4, // Line height
  ),
)
```

## 📱 Responsive Typography

### Adaptive Font Sizes
```dart
// Font size that adapts to screen size
double adaptiveFontSize(BuildContext context, double baseFontSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 1200) {
    return baseFontSize * 1.2; // Desktop
  } else if (screenWidth > 768) {
    return baseFontSize * 1.1; // Tablet
  } else {
    return baseFontSize; // Mobile
  }
}

// Usage
Text(
  'Responsive text',
  style: context.bodyLarge?.copyWith(
    fontSize: adaptiveFontSize(context, 16),
  ),
)
```

### Accessibility-Aware Typography
```dart
// Text that respects system text scaling
Text(
  'Accessible text',
  style: context.bodyLarge?.copyWith(
    // Theme colors automatically adapt
    color: AppColors.getTextPrimary(context.isDarkMode),
  ),
  // Allows text scaling up to 200%
  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0),
)
```

## 🎯 Typography Patterns by Component Type

### Card Headers
```dart
// Standard card header
Text(
  'Card Title',
  style: context.titleLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
    fontWeight: FontWeight.w600,
  ),
)

// Card subtitle
Text(
  'Card subtitle',
  style: context.bodyMedium?.copyWith(
    color: AppColors.getTextSecondary(context.isDarkMode),
  ),
)
```

### Button Typography
```dart
// Primary button text
ElevatedButton(
  child: Text(
    'PRIMARY ACTION',
    style: context.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
)

// Secondary button text
OutlinedButton(
  child: Text(
    'Secondary Action',
    style: context.labelLarge?.copyWith(
      color: context.primaryColor,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### Form Field Typography
```dart
TextFormField(
  style: context.bodyLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
  ),
  decoration: InputDecoration(
    labelText: 'Field Label',
    labelStyle: context.bodyMedium?.copyWith(
      color: AppColors.getTextSecondary(context.isDarkMode),
    ),
    hintText: 'Hint text',
    hintStyle: context.bodyMedium?.copyWith(
      color: AppColors.getTextSecondary(context.isDarkMode),
    ),
  ),
)
```

### List Item Typography
```dart
ListTile(
  title: Text(
    'List Item Title',
    style: context.bodyLarge?.copyWith(
      color: AppColors.getTextPrimary(context.isDarkMode),
      fontWeight: FontWeight.w500,
    ),
  ),
  subtitle: Text(
    'List item subtitle',
    style: context.bodyMedium?.copyWith(
      color: AppColors.getTextSecondary(context.isDarkMode),
    ),
  ),
)
```

## 🎨 Special Typography Patterns

### Gradient Text
```dart
// Text with gradient effect (for special headings)
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [
      context.primaryColor,
      context.secondaryColor,
    ],
  ).createShader(bounds),
  child: Text(
    'Gradient Text',
    style: context.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white, // Required for ShaderMask
    ),
  ),
)
```

### Outlined Text
```dart
// Text with outline (for overlay text)
Stack(
  children: [
    // Outline
    Text(
      'Outlined Text',
      style: context.titleLarge?.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black,
      ),
    ),
    // Fill
    Text(
      'Outlined Text',
      style: context.titleLarge?.copyWith(
        color: Colors.white,
      ),
    ),
  ],
)
```

### Rich Text with Mixed Styles
```dart
RichText(
  text: TextSpan(
    style: context.bodyLarge?.copyWith(
      color: AppColors.getTextPrimary(context.isDarkMode),
    ),
    children: [
      TextSpan(text: 'Regular text with '),
      TextSpan(
        text: 'bold',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.primaryColor,
        ),
      ),
      TextSpan(text: ' and '),
      TextSpan(
        text: 'italic',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: context.secondaryColor,
        ),
      ),
      TextSpan(text: ' parts.'),
    ],
  ),
)
```

## 📊 Typography for Data Display

### Numbers and Statistics
```dart
// Large numbers (scores, statistics)
Text(
  '95%',
  style: context.displayMedium?.copyWith(
    color: AppColors.getProgressColor(95, isDarkMode: context.isDarkMode),
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()], // Monospace numbers
  ),
)

// Small numbers (counts, secondary stats)
Text(
  '12 items',
  style: context.bodySmall?.copyWith(
    color: AppColors.getTextSecondary(context.isDarkMode),
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)
```

### Grade Display
```dart
// Grade with appropriate color
Text(
  'A',
  style: context.titleLarge?.copyWith(
    color: AppColors.getGradeColor('A', isDarkMode: context.isDarkMode),
    fontWeight: FontWeight.bold,
  ),
)
```

### Category Labels
```dart
// Category chip text
Text(
  'Technical',
  style: context.labelMedium?.copyWith(
    color: AppColors.getCategoryColor(
      'technical',
      isDarkMode: context.isDarkMode,
    ),
    fontWeight: FontWeight.w600,
  ),
)
```

## 🔧 Custom Typography Components

### Themed Text Widget
```dart
class ThemedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  
  const ThemedText(
    this.text, {
    Key? key,
    this.baseStyle,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (baseStyle ?? context.bodyMedium)?.copyWith(
        color: color ?? AppColors.getTextPrimary(context.isDarkMode),
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

// Usage
ThemedText(
  'Automatically themed text',
  baseStyle: context.bodyLarge,
  fontWeight: FontWeight.w600,
)
```

### Adaptive Heading Widget
```dart
class AdaptiveHeading extends StatelessWidget {
  final String text;
  final int level; // 1-6, like HTML headings
  
  const AdaptiveHeading(this.text, {Key? key, this.level = 1}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    TextStyle? style;
    switch (level) {
      case 1:
        style = context.displayLarge;
        break;
      case 2:
        style = context.headlineLarge;
        break;
      case 3:
        style = context.headlineMedium;
        break;
      case 4:
        style = context.headlineSmall;
        break;
      case 5:
        style = context.titleLarge;
        break;
      case 6:
        style = context.titleMedium;
        break;
    }
    
    return Text(
      text,
      style: style?.copyWith(
        color: AppColors.getTextPrimary(context.isDarkMode),
      ),
    );
  }
}

// Usage
AdaptiveHeading('Page Title', level: 1),
AdaptiveHeading('Section Header', level: 2),
```

## 🧪 Testing Typography

### Typography Theme Testing
```dart
testWidgets('typography adapts to theme changes', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Text('Test text', style: context.bodyLarge),
      initialThemeMode: ThemeMode.light,
    ),
  );
  
  // Verify light mode text color
  final lightText = tester.widget<Text>(find.text('Test text'));
  expect(lightText.style?.color, AppColors.textPrimary);
  
  // Switch to dark mode
  await ThemeTestUtils.switchToDarkTheme(tester);
  
  // Verify dark mode text color
  final darkText = tester.widget<Text>(find.text('Test text'));
  expect(darkText.style?.color, AppColors.textPrimaryDark);
});
```

### Accessibility Testing
```dart
testWidgets('typography meets accessibility standards', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Column(
        children: [
          Text('Small text', style: context.bodySmall),
          Text('Medium text', style: context.bodyMedium),
          Text('Large text', style: context.bodyLarge),
        ],
      ),
    ),
  );
  
  // Test with different text scale factors
  for (double scale in [1.0, 1.5, 2.0]) {
    await tester.binding.setSurfaceSize(Size(400, 600));
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaleFactor: scale),
        child: /* your widget */,
      ),
    );
    
    // Verify no overflow occurs
    expect(tester.takeException(), isNull);
  }
});
```

## ❌ Typography Anti-Patterns

### Don't Use Hardcoded Colors
```dart
// ❌ Bad - hardcoded color
Text(
  'Text',
  style: TextStyle(color: Colors.grey.shade800),
)

// ✅ Good - theme-aware color
Text(
  'Text',
  style: context.bodyLarge?.copyWith(
    color: AppColors.getTextPrimary(context.isDarkMode),
  ),
)
```

### Don't Ignore Dark Mode
```dart
// ❌ Bad - only works in light mode
Text(
  'Text',
  style: context.bodyLarge?.copyWith(color: Colors.black),
)

// ✅ Good - adapts to theme
Text(
  'Text',
  style: context.bodyLarge?.copyWith(
    color: context.isDarkMode 
      ? AppColors.textPrimaryDark 
      : AppColors.textPrimary,
  ),
)
```

### Don't Create Custom TextStyles
```dart
// ❌ Bad - custom text style
final customStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
);

// ✅ Good - extend theme typography
final themeStyle = context.bodyLarge?.copyWith(
  fontWeight: FontWeight.w500,
);
```

## 📐 Typography Scale Guidelines

### Font Size Recommendations
- **Display**: 36px+ for hero content
- **Headline**: 24-32px for page/section titles
- **Title**: 16-22px for component titles
- **Body**: 14-16px for content (most common)
- **Label**: 11-14px for buttons and UI elements

### Line Height Guidelines
- **Display**: 1.2-1.3 for tight spacing
- **Headline**: 1.3-1.4 for good readability
- **Body**: 1.4-1.6 for comfortable reading
- **Label**: 1.2-1.4 for compact UI elements

### Font Weight Usage
- **Regular (400)**: Body text, standard content
- **Medium (500)**: Emphasis, secondary headings
- **Semi-bold (600)**: Primary headings, important text
- **Bold (700)**: Strong emphasis, display text

## 📚 Related Documentation

- [Usage Patterns](usage-patterns.md) - Learn component implementation patterns
- [Semantic Colors](semantic-colors.md) - Understand color usage with typography
- [Context Extensions](context-extensions.md) - Access typography through context
- [Component Examples](../examples/component-examples.md) - See typography in practice

---

**Consistent typography creates a professional, accessible, and maintainable user interface throughout the FlashMaster application.**

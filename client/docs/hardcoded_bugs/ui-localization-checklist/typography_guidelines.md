# Typography Guidelines for FlashMaster

## Overview
Comprehensive guidelines for typography usage in FlashMaster to ensure consistency, accessibility, and theme compliance.

## Typography Hierarchy

### Material 3 Typography Scale (Google Fonts Inter)
- **Display Large** (57px) - Hero headlines
- **Display Medium** (45px) - Large headlines  
- **Display Small** (36px) - Medium headlines
- **Headline Large** (32px) - Section headers
- **Headline Medium** (28px) - Sub-section headers
- **Headline Small** (24px) - Card titles
- **Title Large** (22px) - Large titles
- **Title Medium** (16px) - Medium titles
- **Title Small** (14px) - Small titles
- **Body Large** (16px) - Primary body text
- **Body Medium** (14px) - Secondary body text
- **Body Small** (12px) - Caption text
- **Label Large** (14px) - Button text
- **Label Medium** (12px) - Form labels
- **Label Small** (11px) - Small labels

## Usage Patterns

### ✅ RECOMMENDED: Theme-Aware Typography
```dart
// Use context extensions for theme-aware typography
Text('Page Title', style: context.headlineLarge)
Text('Section Header', style: context.titleLarge)
Text('Body content', style: context.bodyMedium)
Text('Caption text', style: context.bodySmall)
```

### ✅ ACCEPTABLE: Customized Theme-Aware Typography
```dart
// Customize theme-aware styles when needed
Text('Special Text', style: context.bodyMedium?.copyWith(
  fontWeight: FontWeight.bold,
  color: context.primaryColor,
))
```

### ❌ AVOID: Hardcoded Typography
```dart
// Don't use hardcoded colors or sizes
Text('Bad', style: TextStyle(fontSize: 16, color: Colors.grey))
```


## Responsive Typography

### Device-Specific Scaling
Typography automatically scales based on device type:
- **Phone**: 1.0x scale (base)
- **Small Phone**: 0.9x scale (< 360px width)
- **Tablet**: 1.1x scale
- **Desktop**: 1.0x scale
- **TV**: 1.2x scale

### Using Responsive Typography
```dart
// Automatic scaling with design system
Text('Title', style: DS.responsiveHeadingLarge(context))
Text('Body', style: DS.responsiveBodyMedium(context))
```

## Accessibility Compliance

### WCAG 2.1 Standards
- **Minimum Font Size**: 12px (AA compliance)
- **Recommended Size**: 14px (AAA compliance)
- **Touch Target Size**: 44px minimum

### Accessibility Helpers
```dart
// Ensure accessibility compliance
Text('Accessible', style: DS.accessibleBodyMedium(context))
Text('Small Text', style: DS.accessibleBodySmall(context))
```

## Migration Guide

### From DS Static Styles (Deprecated)
```dart
// OLD - Don't use (hardcoded colors)
Text('Title', style: DS.headingSmall)

// NEW - Use theme-aware method
Text('Title', style: DS.headingSmall(context))

// BEST - Use context extension
Text('Title', style: context.headlineSmall)
```

### From Inline TextStyle
```dart
// OLD - Hardcoded inline style
Text('Title', style: TextStyle(fontSize: 18, color: Colors.grey))

// NEW - Theme-aware style
Text('Title', style: context.titleMedium)
```

## Code Review Checklist
- ✅ All text uses theme-aware colors
- ✅ Font sizes meet accessibility standards (≥12px)
- ✅ Typography scales appropriately across devices
- ✅ No hardcoded TextStyle with fixed colors
- ✅ Consistent use of Material 3 typography scale

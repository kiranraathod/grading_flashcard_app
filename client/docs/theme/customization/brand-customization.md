# Brand Customization Guide

**Customizing FlashMaster's Visual Identity**

## 🎯 Overview

This guide explains how to customize FlashMaster's brand colors, typography, and visual identity while maintaining the robust theme system architecture.

## 🎨 Brand Color Customization

### Current Brand Identity
```dart
// Primary brand (Teal-based)
static const Color primary = Color(0xFF009688);      // Teal-500
static const Color primaryDark = Color(0xFF4DB6AC);  // Teal-300
static const Color accent = Color(0xFF00796B);       // Teal-700

// Secondary brand (Purple-based)
static const Color secondary = Color(0xFF8B5CF6);    // Purple-600
static const Color secondaryDark = Color(0xFFA78BFA); // Purple-400
```

### Customization Steps

#### 1. Choose Your Brand Colors
```dart
// Example: Blue-based brand
static const Color primary = Color(0xFF2563EB);      // Blue-600
static const Color primaryDark = Color(0xFF60A5FA);  // Blue-400
static const Color accent = Color(0xFF1D4ED8);       // Blue-700

// Example: Green-based brand
static const Color primary = Color(0xFF059669);      // Emerald-600
static const Color primaryDark = Color(0xFF34D399);  // Emerald-400
static const Color accent = Color(0xFF047857);       // Emerald-700
```

#### 2. Update Gradient Colors
```dart
// Flashcard gradients (match primary brand)
static const Color cardGradientStart = Color(0xFFDEF7FF); // Blue-50
static const Color cardGradientEnd = Color(0xFFBAE6FD);   // Blue-100
static const Color cardGradientStartDark = Color(0xFF0C2340); // Dark blue
static const Color cardGradientEndDark = Color(0xFF1E3A5F);   // Blue-900
```

#### 3. Update Success Colors (Optional)
```dart
// Keep success as primary brand color or customize
static const Color success = Color(0xFF059669);      // Use primary
static const Color successDark = Color(0xFF34D399);  // Use primaryDark
```

## 🔤 Typography Customization

### Current Typography (Inter Font)
```dart
// In app_themes.dart
return GoogleFonts.interTextTheme(baseTheme).copyWith(
  // Typography definitions...
);
```

### Custom Brand Font
```dart
// Example: Using Poppins
return GoogleFonts.poppinsTextTheme(baseTheme).copyWith(
  displayLarge: GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: textColor,
  ),
  // ... other styles
);

// Example: Using custom font
return TextTheme(
  displayLarge: TextStyle(
    fontFamily: 'YourCustomFont',
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: textColor,
  ),
  // ... other styles
);
```

## 🏗️ Logo and Branding Integration

### App Bar Branding
```dart
// In app_header.dart, customize the header
AppBar(
  title: Row(
    children: [
      // Custom logo
      Image.asset(
        'assets/images/your_logo.png',
        height: 32,
        width: 32,
      ),
      SizedBox(width: 12),
      Text(
        'Your App Name',
        style: context.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
        ),
      ),
    ],
  ),
)
```

### Splash Screen Branding
```dart
// Create branded splash screen
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.primaryColor,
        context.primaryColor.withValues(alpha: 0.8),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Your logo
        Image.asset('assets/images/logo_large.png'),
        SizedBox(height: 24),
        Text(
          'Your App Name',
          style: context.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
)
```

## 🎨 Visual Theme Customization

### Card Styling
```dart
// Custom card decorations in theme_extensions.dart
static const light = AppThemeExtension(
  cardDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(20.0)), // Rounded
    border: Border.all(
      color: Color(0xFFE5E7EB), // Light border
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x08000000), // Subtle shadow
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
);
```

### Button Styling
```dart
// In app_themes.dart, customize button theme
static ElevatedButtonThemeData _buildElevatedButtonTheme(Brightness brightness) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Larger
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), // More rounded
      ),
      backgroundColor: brightness == Brightness.light 
          ? AppColors.primary 
          : AppColors.primaryDark,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.poppins( // Custom font
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}
```

## 📱 Platform-Specific Customization

### iOS-Style Customization
```dart
// More iOS-like styling
static const iosStyle = AppThemeExtension(
  cardDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(12.0)), // iOS style
    boxShadow: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
);
```

### Material You Integration
```dart
// Enhanced Material You support
ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
  // Use dynamic color if available
  dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
)
```

## 🔧 Configuration-Based Customization

### Theme Configuration Class
```dart
class BrandConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final String fontFamily;
  final String appName;
  final String logoPath;
  
  const BrandConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.fontFamily,
    required this.appName,
    required this.logoPath,
  });
  
  // Predefined brand configurations
  static const flashMaster = BrandConfig(
    primaryColor: Color(0xFF009688),
    secondaryColor: Color(0xFF8B5CF6),
    fontFamily: 'Inter',
    appName: 'FlashMaster',
    logoPath: 'assets/images/flashmaster_logo.png',
  );
  
  static const customBrand = BrandConfig(
    primaryColor: Color(0xFF2563EB),
    secondaryColor: Color(0xFF7C3AED),
    fontFamily: 'Poppins',
    appName: 'StudyPro',
    logoPath: 'assets/images/studypro_logo.png',
  );
}
```

### Dynamic Theme Generation
```dart
class BrandThemeGenerator {
  static ThemeData generateLightTheme(BrandConfig config) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.getTextTheme(
        config.fontFamily,
        ThemeData.light().textTheme,
      ),
      // ... other theme properties
    );
  }
  
  static ThemeData generateDarkTheme(BrandConfig config) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.getTextTheme(
        config.fontFamily,
        ThemeData.dark().textTheme,
      ),
      // ... other theme properties
    );
  }
}
```

## 🧪 Testing Brand Customizations

### Visual Regression Testing
```dart
testWidgets('brand colors display correctly', (tester) async {
  await tester.pumpWidget(
    ThemeTestUtils.createThemeTestWidget(
      child: Container(color: AppColors.primary),
    ),
  );
  
  // Take golden screenshot
  await expectLater(
    find.byType(Container),
    matchesGoldenFile('brand_primary_color.png'),
  );
});
```

### Accessibility Testing
```dart
test('brand colors meet accessibility standards', () {
  final contrastRatio = calculateContrastRatio(
    AppColors.primary,
    Colors.white,
  );
  
  expect(contrastRatio, greaterThan(4.5)); // WCAG AA
});
```

## 📚 Related Documentation

- [Adding Colors](adding-colors.md) - Technical color implementation
- [Theme Extensions](theme-extensions.md) - Advanced customization
- [Semantic Colors](../developer-guide/semantic-colors.md) - Color system understanding
- [Testing Requirements](../maintenance/testing-requirements.md) - Testing custom themes

---

**Brand customization allows you to create a unique visual identity while maintaining the robust architecture of the FlashMaster theme system.**

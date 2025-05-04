import 'package:flutter/material.dart';
import 'theme_extensions.dart';

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  AppThemeExtension get appTheme => theme.extension<AppThemeExtension>()!;
  
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  // Semantic color getters
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => colorScheme.surface; // Use surface instead of deprecated background
  Color get errorColor => colorScheme.error;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSecondaryColor => colorScheme.onSecondary;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get onBackgroundColor => colorScheme.onSurface; // Use onSurface instead of deprecated onBackground
  Color get onErrorColor => colorScheme.onError;
  
  // Surface variants
  Color get surfaceVariantColor => colorScheme.surfaceContainerHighest; // Use surfaceContainerHighest instead of deprecated surfaceVariant
  Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;
  
  // Custom color getters from extension
  Color get successColor => appTheme.successColor!;
  Color get warningColor => appTheme.warningColor!;
  Color get cardGradientStart => appTheme.cardGradientStart!;
  Color get cardGradientEnd => appTheme.cardGradientEnd!;
  Color get interviewGradientStart => appTheme.interviewGradientStart!;
  Color get interviewGradientEnd => appTheme.interviewGradientEnd!;
  
  // Card shadow getter
  List<BoxShadow> get cardShadow => appTheme.cardShadow!;
  
  // Shadow color getter
  Color get shadowColor => colorScheme.shadow;
  
  // Primary hover color for dark mode
  Color? get primaryDarkHover => appTheme.primaryDarkHover;
  
  // Text style helpers
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
}

// Helper extension for Color to easily apply opacity
extension ColorExtension on Color {
  Color withOpacityValue(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((opacity * 255).round());
  }
  
  // Replaces the deprecated withOpacity() method
  Color withOpacityFix(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((opacity * 255).round());
  }
}

// Common gradient helper
class ThemedGradient {
  static LinearGradient getCardGradient(BuildContext context, {bool isInterview = false}) {
    final themeExtension = context.appTheme;
    
    return LinearGradient(
      colors: isInterview
          ? [
              themeExtension.interviewGradientStart!,
              themeExtension.interviewGradientEnd!,
            ]
          : [
              themeExtension.cardGradientStart!,
              themeExtension.cardGradientEnd!,
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

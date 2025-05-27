import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'theme_extensions.dart';
import 'theme_provider.dart';

// Extension methods for easy access to theme values
extension ThemeGetter on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Quick access to color values
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get errorColor => colorScheme.error;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get onErrorColor => colorScheme.onError;
  Color get onSecondaryColor => colorScheme.onSecondary;
  Color get surfaceVariantColor => colorScheme.surfaceContainerHighest;
  Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;
  Color get outlineColor => colorScheme.outline;
  
  // Additional color getters for feedback colors
  Color get successColor => isDarkMode ? AppColors.successDark : AppColors.success;
  Color get warningColor => isDarkMode ? AppColors.warningDark : AppColors.warning;
  Color get infoColor => isDarkMode ? AppColors.infoDark : AppColors.info;
  Color get shadowColor => isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1);
  
  // Text style access
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
  
  // Check dark mode status
  bool get isDarkMode {
    final themeProvider = Provider.of<ThemeProvider>(this, listen: false);
    return themeProvider.isDarkMode;
  }
  
  // Get theme extension
  AppThemeExtension get appTheme => theme.extension<AppThemeExtension>()!;
  
  // Common UI properties
  BorderRadiusGeometry get cardBorderRadius => BorderRadius.circular(16.0);
  BorderRadiusGeometry get buttonBorderRadius => BorderRadius.circular(12.0);
  BorderRadiusGeometry get smallBorderRadius => BorderRadius.circular(8.0);
  EdgeInsets get screenPadding => const EdgeInsets.all(16.0);
  EdgeInsets get cardPadding => const EdgeInsets.all(16.0);
  double get cardElevation => isDarkMode ? 0.0 : 1.0;
  List<BoxShadow>? get cardShadow => isDarkMode 
    ? null 
    : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}

// Provide custom themed colors for cards
class ThemedColors {
  static LinearGradient cardGradient(BuildContext context, {bool isInterview = false}) {
    if (isInterview) {
      return LinearGradient(
        colors: context.isDarkMode
            ? [AppColors.interviewGradientStartDark, AppColors.interviewGradientEndDark]
            : [AppColors.interviewGradientStart, AppColors.interviewGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: context.isDarkMode
            ? [AppColors.cardGradientStartDark, AppColors.cardGradientEndDark]
            : [AppColors.cardGradientStart, AppColors.cardGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
  
  static Color getTextPrimary(BuildContext context) => 
    AppColors.getTextPrimary(context.isDarkMode);
  
  static Color getTextSecondary(BuildContext context) => 
    AppColors.getTextSecondary(context.isDarkMode);
  
  static Color getSurfaceColor(BuildContext context) => 
    AppColors.getSurfaceColor(context.isDarkMode);
  
  static Color getBackgroundColor(BuildContext context) => 
    AppColors.getBackgroundColor(context.isDarkMode);
}

// Helper class for gradient styles
class ThemedGradient {
  static LinearGradient getCardGradient(BuildContext context, {bool isInterview = false}) {
    return ThemedColors.cardGradient(context, isInterview: isInterview);
  }
}

// UI Component helpers
class ThemedComponents {
  static BoxDecoration cardDecoration(BuildContext context, {
    Color? color,
    Gradient? gradient,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? context.surfaceColor,
      gradient: gradient,
      borderRadius: borderRadius ?? context.cardBorderRadius,
      boxShadow: boxShadow ?? context.cardShadow,
      border: border,
    );
  }
  
  static BoxDecoration cardDecorationWithGradient(BuildContext context, {
    bool isInterview = false,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      gradient: ThemedGradient.getCardGradient(context, isInterview: isInterview),
      borderRadius: borderRadius ?? context.cardBorderRadius,
      boxShadow: boxShadow ?? context.cardShadow,
      border: border,
    );
  }
}

// Add convenient extension methods for colors with opacity
extension ColorWithOpacityFix on Color {
  // Fix withOpacity to use new withValues API
  Color withOpacityFix(double opacity) {
    return withValues(alpha: opacity);
  }
}

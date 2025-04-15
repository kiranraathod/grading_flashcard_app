import 'package:flutter/material.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: DS.headingMedium,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DS.borderLarge,
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: DS.primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: DS.outlineButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(style: DS.ghostButtonStyle),
      textTheme: TextTheme(
        headlineLarge: DS.headingLarge,
        headlineMedium: DS.headingMedium,
        headlineSmall: DS.headingSmall,
        bodyLarge: DS.bodyLarge,
        bodyMedium: DS.bodyMedium,
        bodySmall: DS.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: DS.borderMedium,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DS.borderMedium,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DS.borderMedium,
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DS.spacingM,
          vertical: DS.spacingS,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Colors.grey.shade100,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primary.withOpacity(0.1),
        secondarySelectedColor: AppColors.primary.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(
          horizontal: DS.spacingS,
          vertical: DS.spacing2xs,
        ),
        labelStyle: DS.bodySmall,
        secondaryLabelStyle: DS.bodySmall.copyWith(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: DS.borderSmall),
      ),
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: DS.borderMedium,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF2C2C2E),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: DS.headingMedium.copyWith(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DS.borderLarge,
          side: const BorderSide(color: Color(0xFF3C3C3E)),
        ),
      ),
      // Dark theme elements continue following the same pattern as light theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: DS.primaryButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: DS.headingLarge.copyWith(color: Colors.white),
        headlineMedium: DS.headingMedium.copyWith(color: Colors.white),
        headlineSmall: DS.headingSmall.copyWith(color: Colors.white),
        bodyLarge: DS.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: DS.bodyMedium.copyWith(color: Colors.white),
        bodySmall: DS.bodySmall.copyWith(color: const Color(0xFFAAAAAA)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

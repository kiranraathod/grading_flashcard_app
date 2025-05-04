import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'theme_extensions.dart';

class AppThemes {
  // Material 3 Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Explicitly set Material 3
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
      surfaceContainerHighest: const Color(0xFFF3F3F3), // Replace surfaceVariant
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    // Material 3 elevation overlay
    applyElevationOverlayColor: false,
    
    // Typography with Google Fonts
    textTheme: _buildTextTheme(Brightness.light),
    
    // Component themes
    appBarTheme: _buildAppBarTheme(Brightness.light),
    cardTheme: _buildCardTheme(Brightness.light),
    elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.light),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(Brightness.light),
    bottomSheetTheme: _buildBottomSheetTheme(Brightness.light),
    inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
    chipTheme: _buildChipTheme(Brightness.light),
    
    // Add theme extensions
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension.light,
    ],
  );

  // Material 3 Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      tertiary: AppColors.accentDark,
      error: AppColors.errorDark,
      surface: AppColors.surfaceDark,
      surfaceContainerHighest: const Color(0xFF3A3A42), // Updated for better contrast
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    // Material 3 elevation overlay for dark theme
    applyElevationOverlayColor: true,
    
    textTheme: _buildTextTheme(Brightness.dark),
    
    appBarTheme: _buildAppBarTheme(Brightness.dark),
    cardTheme: _buildCardTheme(Brightness.dark),
    elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.dark),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(Brightness.dark),
    bottomSheetTheme: _buildBottomSheetTheme(Brightness.dark),
    inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
    chipTheme: _buildChipTheme(Brightness.dark),
    
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension.dark,
    ],
    scaffoldBackgroundColor: AppColors.backgroundDark,
  );

  // Text theme with Material 3 typography
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness).textTheme;
    final Color textColor = brightness == Brightness.light 
        ? AppColors.textPrimary 
        : AppColors.textPrimaryDark;
    
    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: brightness == Brightness.light ? AppColors.textSecondary : AppColors.textSecondaryDark,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: brightness == Brightness.light ? AppColors.textTertiary : AppColors.textTertiaryDark,
      ),
    );
  }

  // Component themes
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 3,
      centerTitle: false,
      backgroundColor: brightness == Brightness.light 
          ? AppColors.surfaceLight 
          : AppColors.surfaceDark,
      foregroundColor: brightness == Brightness.light 
          ? AppColors.textPrimary 
          : AppColors.textPrimaryDark,
      iconTheme: IconThemeData(
        color: brightness == Brightness.light 
            ? AppColors.textPrimary 
            : AppColors.textPrimaryDark,
      ),
    );
  }

  static CardTheme _buildCardTheme(Brightness brightness) {
    return CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      color: brightness == Brightness.light 
          ? AppColors.surfaceLight 
          : AppColors.surfaceDark,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Brightness brightness) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: brightness == Brightness.light 
            ? AppColors.primary 
            : AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(Brightness brightness) {
    return FloatingActionButtonThemeData(
      backgroundColor: brightness == Brightness.light 
          ? AppColors.primary 
          : AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(Brightness brightness) {
    return BottomSheetThemeData(
      backgroundColor: brightness == Brightness.light 
          ? AppColors.surfaceLight 
          : AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 8,
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    final borderColor = brightness == Brightness.light 
        ? Colors.grey.shade300 
        : Colors.grey.shade700;
    final fillColor = brightness == Brightness.light 
        ? Colors.grey.shade50 
        : const Color(0xFF2C2C2E);
    
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: brightness == Brightness.light 
              ? AppColors.primary 
              : AppColors.primaryDark,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: brightness == Brightness.light 
              ? AppColors.error 
              : AppColors.errorDark,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: brightness == Brightness.light 
              ? AppColors.error 
              : AppColors.errorDark,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ChipThemeData _buildChipTheme(Brightness brightness) {
    return ChipThemeData(
      backgroundColor: brightness == Brightness.light 
          ? Colors.grey.shade100 
          : Colors.grey.shade800,
      disabledColor: brightness == Brightness.light 
          ? Colors.grey.shade300 
          : Colors.grey.shade700,
      selectedColor: brightness == Brightness.light 
          ? AppColors.primary.withAlpha((0.1 * 255).round()) 
          : AppColors.primaryDark.withAlpha((0.2 * 255).round()),
      secondarySelectedColor: brightness == Brightness.light 
          ? AppColors.secondary.withAlpha((0.1 * 255).round()) 
          : AppColors.secondaryDark.withAlpha((0.2 * 255).round()),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      brightness: brightness,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

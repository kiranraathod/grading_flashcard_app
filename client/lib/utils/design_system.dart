import 'package:flutter/material.dart';
import 'colors.dart';

class DS {
  // Private constructor to prevent instantiation
  DS._();
  
  // Spacing
  static const double spacing2xs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  
  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle badgeText = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  // Borders & Radii
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXlarge = 24.0;
  
  // Common border radius shapes
  static final BorderRadius borderSmall = BorderRadius.circular(borderRadiusSmall);
  static final BorderRadius borderMedium = BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius borderLarge = BorderRadius.circular(borderRadiusLarge);
  static final BorderRadius borderXlarge = BorderRadius.circular(borderRadiusXlarge);
  
  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
  );
  
  static final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
    side: const BorderSide(color: Color(0xFFE5E7EB)), // Gray-200
  );
  
  static final ButtonStyle ghostButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
  );
}
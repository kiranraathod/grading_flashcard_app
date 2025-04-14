import 'package:flutter/material.dart';

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
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Borders & Radii
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXlarge = 36.0;
  
  // Common border radius shapes
  static final BorderRadius borderSmall = BorderRadius.circular(borderRadiusSmall);
  static final BorderRadius borderMedium = BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius borderLarge = BorderRadius.circular(borderRadiusLarge);
  static final BorderRadius borderXlarge = BorderRadius.circular(borderRadiusXlarge);
}
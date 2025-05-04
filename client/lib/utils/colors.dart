import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Core brand colors from React code
  static const Color primary = Color(0xFF10B981);  // Emerald-600
  static const Color secondary = Color(0xFF8B5CF6); // Purple-600
  static const Color accent = Color(0xFF059669);    // Emerald-700
  
  // Dark mode versions of core colors
  static const Color primaryDark = Color(0xFF4ADE80);  // Even brighter Emerald for better contrast
  static const Color primaryDarkBright = Color(0xFF6EE7B7);  // Extra bright emerald for maximum contrast
  static const Color primaryDarkHover = Color(0xFF5CE88D);  // Lighter emerald for hover
  static const Color secondaryDark = Color(0xFFA78BFA); // Purple-400
  static const Color accentDark = Color(0xFF4ADE80);    // Matches primaryDark
  
  // Background colors
  static const Color background = Color(0xFFF9FAFB); // Gray-50
  static const Color backgroundDark = Color(0xFF121216); // Lighter black for better layering
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF2A2A30); // More elevated surface for better contrast
  
  // Card colors from React code
  static const Color cardGradientStart = Color(0xFFECFDF5); // Emerald-50
  static const Color cardGradientEnd = Color(0xFFD1FAE5);   // Teal-50
  static const Color cardGradientStartDark = Color(0xFF0E362B); // Slightly greener emerald
  static const Color cardGradientEndDark = Color(0xFF0F3D31);   // Deeper teal
  
  static const Color interviewGradientStart = Color(0xFFEEF2FF); // Purple-50
  static const Color interviewGradientEnd = Color(0xFFE0E7FF); // Indigo-50
  static const Color interviewGradientStartDark = Color(0xFF1F1D35); // Richer purple
  static const Color interviewGradientEndDark = Color(0xFF292449); // Richer indigo
  
  // Feedback colors
  static const Color success = Color(0xFF10B981); // Emerald-600
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444);   // Red-500
  static const Color info = Color(0xFF3B82F6);    // Blue-500
  
  // Dark mode feedback colors
  static const Color successDark = Color(0xFF34D399); // Emerald-400
  static const Color warningDark = Color(0xFFFBBF24); // Amber-400
  static const Color errorDark = Color(0xFFF87171);   // Red-400
  static const Color infoDark = Color(0xFF60A5FA);    // Blue-400
  
  // Grade colors
  static const Color gradeA = Color(0xFF4CAF50);
  static const Color gradeB = Color(0xFF8BC34A);
  static const Color gradeC = Color(0xFFFF9800);
  static const Color gradeD = Color(0xFFFF5722);
  static const Color gradeF = Color(0xFFF44336);
  
  // Dark mode grade colors
  static const Color gradeADark = Color(0xFF66BB6A);
  static const Color gradeBDark = Color(0xFF9CCC65);
  static const Color gradeCDark = Color(0xFFFFB74D);
  static const Color gradeDDark = Color(0xFFFF8A65);
  static const Color gradeFDark = Color(0xFFE57373);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // Gray-800
  static const Color textSecondary = Color(0xFF4B5563); // Gray-600
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textOnPrimary = Colors.white;
  
  // Dark mode text colors
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFF0F0F0); // Even brighter for better readability
  static const Color textTertiaryDark = Color(0xFFBFBFBF); // Lightened Gray for better contrast
  
  // Helper method to get grade color
  static Color getGradeColor(String grade, {bool isDarkMode = false}) {
    if (isDarkMode) {
      switch (grade) {
        case 'A': return gradeADark;
        case 'B': return gradeBDark;
        case 'C': return gradeCDark;
        case 'D': return gradeDDark;
        case 'F': return gradeFDark;
        default: return Colors.grey.shade600;
      }
    } else {
      switch (grade) {
        case 'A': return gradeA;
        case 'B': return gradeB;
        case 'C': return gradeC;
        case 'D': return gradeD;
        case 'F': return gradeF;
        default: return Colors.grey;
      }
    }
  }
  
  // Helper method to get progress color
  static Color getProgressColor(int progress, {bool isDarkMode = false}) {
    if (isDarkMode) {
      if (progress >= 70) return successDark;
      if (progress >= 40) return warningDark;
      if (progress > 0) return infoDark;
      return textTertiaryDark;
    } else {
      if (progress >= 70) return success;
      if (progress >= 40) return warning;
      if (progress > 0) return info;
      return textTertiary;
    }
  }
  
  // Get correct text color for current theme mode
  static Color getTextPrimary(bool isDarkMode) {
    return isDarkMode ? textPrimaryDark : textPrimary;
  }
  
  // Get correct text secondary color for current theme mode
  static Color getTextSecondary(bool isDarkMode) {
    return isDarkMode ? textSecondaryDark : textSecondary;
  }
  
  // Get correct surface color for current theme mode
  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surfaceLight;
  }
  
  // Get correct background color for current theme mode
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : background;
  }
}
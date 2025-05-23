import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Core brand colors - Teal for decks, Purple for interview
  static const Color primary = Color(0xFF009688);  // Teal-500 (Standard Material teal)
  static const Color secondary = Color(0xFF8B5CF6); // Purple-600 (keep as is)
  static const Color accent = Color(0xFF00796B);    // Teal-700
  
  // Dark mode versions of core colors
  static const Color primaryDark = Color(0xFF4DB6AC);  // Teal-300 (lighter for dark mode)
  static const Color primaryDarkBright = Color(0xFF80CBC4);  // Teal-200 for maximum contrast
  static const Color primaryDarkHover = Color(0xFFB2DFDB);  // Teal-100 for hover states
  static const Color secondaryDark = Color(0xFFA78BFA); // Purple-400 (keep as is)
  static const Color accentDark = Color(0xFF4DB6AC);    // Matches primaryDark
  
  // Background colors
  static const Color background = Color(0xFFF9FAFB); // Gray-50
  static const Color backgroundDark = Color(0xFF121216); // Lighter black for better layering
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF2A2A30); // More elevated surface for better contrast
  
  // Card colors - Teal for decks, Purple for interview
  static const Color cardGradientStart = Color(0xFFE0F2F1); // Teal-50
  static const Color cardGradientEnd = Color(0xFFB2DFDB);   // Teal-100
  static const Color cardGradientStartDark = Color(0xFF00332C); // Darker teal for dark mode
  static const Color cardGradientEndDark = Color(0xFF004D40);   // Teal-900
  
  // Keep interview colors as purple/indigo
  static const Color interviewGradientStart = Color(0xFFEEF2FF); // Purple-50
  static const Color interviewGradientEnd = Color(0xFFE0E7FF); // Indigo-50
  static const Color interviewGradientStartDark = Color(0xFF1F1D35); // Richer purple
  static const Color interviewGradientEndDark = Color(0xFF292449); // Richer indigo
  
  // Feedback colors - Use teal for success in deck context
  static const Color success = Color(0xFF009688); // Teal-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444);   // Red-500
  static const Color info = Color(0xFF3B82F6);    // Blue-500
  
  // Dark mode feedback colors
  static const Color successDark = Color(0xFF4DB6AC); // Teal-300
  static const Color warningDark = Color(0xFFFBBF24); // Amber-400
  static const Color errorDark = Color(0xFFF87171);   // Red-400
  static const Color infoDark = Color(0xFF60A5FA);    // Blue-400
  
  // Grade colors - Keep existing color scheme
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
  
  // Interview category colors - Semantic naming for different question categories
  static const Color categoryTechnical = Color(0xFF1E3A8A);    // Blue-800 for technical questions
  static const Color categoryBehavioral = Color(0xFF064E3B);   // Emerald-800 for behavioral questions  
  static const Color categoryLeadership = Color(0xFF4C1D95);   // Violet-800 for leadership questions
  static const Color categorySituational = Color(0xFF854D0E);  // Amber-800 for situational questions
  static const Color categoryGeneral = Color(0xFF991B1B);      // Red-800 for general questions
  static const Color categoryDefault = Color(0xFF374151);      // Gray-700 for undefined categories
  
  // Dark mode interview category colors
  static const Color categoryTechnicalDark = Color(0xFF93C5FD);    // Blue-300
  static const Color categoryBehavioralDark = Color(0xFF6EE7B7);   // Emerald-300
  static const Color categoryLeadershipDark = Color(0xFFC4B5FD);   // Violet-300
  static const Color categorySituationalDark = Color(0xFFFDE68A);  // Amber-300
  static const Color categoryGeneralDark = Color(0xFFFCA5A5);      // Red-300
  static const Color categoryDefaultDark = Color(0xFFD1D5DB);      // Gray-300
  
  // Surface and container colors
  static const Color surfaceContainer = Color(0xFF2A2A30);         // Dark surface container
  static const Color surfaceContainerLight = Color(0xFFF8F9FA);    // Light surface container
  static const Color divider = Color(0xFF2C2C2E);                  // Divider color
  static const Color dividerLight = Color(0xFFE5E7EB);             // Light divider color
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // Gray-800
  static const Color textSecondary = Color(0xFF4B5563); // Gray-600
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textOnPrimary = Colors.white;
  
  // Dark mode text colors
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFF0F0F0); // Even brighter for better readability
  static const Color textTertiaryDark = Color(0xFFBFBFBF); // Lightened Gray for better contrast
  
  // Helper method to get category color based on type and theme mode
  static Color getCategoryColor(String category, {bool isDarkMode = false}) {
    if (isDarkMode) {
      switch (category.toLowerCase()) {
        case 'technical':
        case 'data science':
          return categoryTechnicalDark;
        case 'behavioral':
          return categoryBehavioralDark;
        case 'leadership':
          return categoryLeadershipDark;
        case 'situational':
          return categorySituationalDark;
        case 'general':
          return categoryGeneralDark;
        default:
          return categoryDefaultDark;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'technical':
        case 'data science':
          return categoryTechnical;
        case 'behavioral':
          return categoryBehavioral;
        case 'leadership':
          return categoryLeadership;
        case 'situational':
          return categorySituational;
        case 'general':
          return categoryGeneral;
        default:
          return categoryDefault;
      }
    }
  }

  // Helper method to get difficulty color
  static Color getDifficultyColor(String difficulty, {bool isDarkMode = false}) {
    if (isDarkMode) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          return successDark;
        case 'medium':
          return warningDark;
        case 'hard':
          return errorDark;
        default:
          return textSecondaryDark;
      }
    } else {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          return success;
        case 'medium':
          return warning;
        case 'hard':
          return error;
        default:
          return textSecondary;
      }
    }
  }

  // Get container/surface color for current theme mode
  static Color getContainerColor(bool isDarkMode) {
    return isDarkMode ? surfaceContainer : surfaceContainerLight;
  }
  
  // Get divider color for current theme mode
  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? divider : dividerLight;
  }

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
  
  // Updated helper method to use teal for deck progress
  static Color getProgressColor(int progress, {bool isDarkMode = false}) {
    if (isDarkMode) {
      if (progress >= 70) return primaryDark; // Teal-300
      if (progress >= 40) return warningDark;
      if (progress > 0) return infoDark;
      return textTertiaryDark;
    } else {
      if (progress >= 70) return primary; // Teal-500
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

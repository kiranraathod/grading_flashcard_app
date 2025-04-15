import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Core brand colors from React code
  static const Color primary = Color(0xFF10B981);  // Emerald-600
  static const Color secondary = Color(0xFF8B5CF6); // Purple-600
  static const Color accent = Color(0xFF059669);    // Emerald-700
  
  // Background colors
  static const Color background = Color(0xFFF9FAFB); // Gray-50
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1C1B1F);
  
  // Card colors from React code
  static const Color cardGradientStart = Color(0xFFECFDF5); // Emerald-50
  static const Color cardGradientEnd = Color(0xFFD1FAE5);   // Teal-50
  static const Color interviewGradientStart = Color(0xFFEEF2FF); // Purple-50
  static const Color interviewGradientEnd = Color(0xFFE0E7FF); // Indigo-50
  
  // Feedback colors
  static const Color success = Color(0xFF10B981); // Emerald-600
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444);   // Red-500
  static const Color info = Color(0xFF3B82F6);    // Blue-500
  
  // Grade colors
  static const Color gradeA = Color(0xFF4CAF50);
  static const Color gradeB = Color(0xFF8BC34A);
  static const Color gradeC = Color(0xFFFF9800);
  static const Color gradeD = Color(0xFFFF5722);
  static const Color gradeF = Color(0xFFF44336);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // Gray-800
  static const Color textSecondary = Color(0xFF4B5563); // Gray-600
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textOnPrimary = Colors.white;
  
  // Helper method to get grade color
  static Color getGradeColor(String grade) {
    switch (grade) {
      case 'A': return gradeA;
      case 'B': return gradeB;
      case 'C': return gradeC;
      case 'D': return gradeD;
      case 'F': return gradeF;
      default: return Colors.grey;
    }
  }
  
  // Helper method to get progress color
  static Color getProgressColor(int progress) {
    if (progress >= 70) return success;
    if (progress >= 40) return warning;
    if (progress > 0) return info;
    return textTertiary;
  }
}
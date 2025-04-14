import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Core brand colors
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFF1A5E34);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1C1B1F);
  
  // Feedback colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Grade colors
  static const Color gradeA = Color(0xFF4CAF50);
  static const Color gradeB = Color(0xFF8BC34A);
  static const Color gradeC = Color(0xFFFF9800);
  static const Color gradeD = Color(0xFFFF5722);
  static const Color gradeF = Color(0xFFF44336);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.black;
  
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
}
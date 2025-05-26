import 'package:flutter/material.dart';

/// Defines the visual styling for a category including colors and icons
class CategoryStyle {
  final Color color;
  final Color darkColor;
  final IconData icon;
  final Gradient? gradient;
  
  const CategoryStyle({
    required this.color,
    required this.darkColor, 
    required this.icon,
    this.gradient,
  });
}

/// Centralized theme system for category colors, icons, and styling
/// Replaces hardcoded color/icon overrides for consistent UI theming
class CategoryTheme {
  static const Map<String, CategoryStyle> _themes = {
    'technical': CategoryStyle(
      color: Color(0xFFE3F2FD), // Light Blue
      darkColor: Color(0xFF1565C0), // Dark Blue
      icon: Icons.code,
    ),
    'applied': CategoryStyle(
      color: Color(0xFFE8F5E8), // Light Green
      darkColor: Color(0xFF2E7D32), // Dark Green
      icon: Icons.build,
    ),
    'behavioral': CategoryStyle(
      color: Color(0xFFFFF3E0), // Light Orange
      darkColor: Color(0xFFEF6C00), // Dark Orange
      icon: Icons.people,
    ),
    'case': CategoryStyle(
      color: Color(0xFFF3E5F5), // Light Purple
      darkColor: Color(0xFF7B1FA2), // Dark Purple
      icon: Icons.assessment,
    ),
    'job': CategoryStyle(
      color: Color(0xFFFFEBEE), // Light Red
      darkColor: Color(0xFFC62828), // Dark Red
      icon: Icons.work,
    ),
    // UI Category mappings for the 6+ categories shown in UI
    'data_analysis': CategoryStyle(
      color: Color(0xFFE8F5E8), // Light Green
      darkColor: Color(0xFF2E7D32), // Dark Green
      icon: Icons.analytics,
    ),
    'web_development': CategoryStyle(
      color: Color(0xFFE1F5FE), // Light Cyan
      darkColor: Color(0xFF0277BD), // Dark Cyan
      icon: Icons.web,
    ),
    'machine_learning': CategoryStyle(
      color: Color(0xFFF3E5F5), // Light Purple
      darkColor: Color(0xFF7B1FA2), // Dark Purple
      icon: Icons.psychology,
    ),
    'sql': CategoryStyle(
      color: Color(0xFFE3F2FD), // Light Blue
      darkColor: Color(0xFF1565C0), // Dark Blue
      icon: Icons.storage,
    ),
    'python': CategoryStyle(
      color: Color(0xFFFFF8E1), // Light Amber
      darkColor: Color(0xFFFF8F00), // Dark Amber
      icon: Icons.code,
    ),
    'statistics': CategoryStyle(
      color: Color(0xFFE0F2F1), // Light Teal
      darkColor: Color(0xFF00695C), // Dark Teal
      icon: Icons.bar_chart,
    ),
    'data_visualization': CategoryStyle(
      color: Color(0xFFE8EAF6), // Light Indigo
      darkColor: Color(0xFF303F9F), // Dark Indigo
      icon: Icons.show_chart,
    ),
  };
  
  /// Get the complete style configuration for a category
  static CategoryStyle getTheme(String categoryId) {
    // Normalize category ID to handle different formats
    final normalizedId = _normalizeCategoryId(categoryId);
    return _themes[normalizedId] ?? CategoryStyle(
      color: Colors.grey.shade100,
      darkColor: Colors.grey.shade800,
      icon: Icons.category,
    );
  }
  
  /// Get category color with optional dark mode support
  static Color getColor(String categoryId, {bool isDarkMode = false}) {
    final theme = getTheme(categoryId);
    return isDarkMode ? theme.darkColor : theme.color;
  }
  
  /// Get category icon
  static IconData getIcon(String categoryId) {
    return getTheme(categoryId).icon;
  }
  
  /// Get theme-aware color based on current context
  static Color getContextAwareColor(BuildContext context, String categoryId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return getColor(categoryId, isDarkMode: isDark);
  }

  /// Get all available category themes for UI display
  static Map<String, CategoryStyle> getAllThemes() {
    return Map.unmodifiable(_themes);
  }

  /// Check if a category theme exists
  static bool hasTheme(String categoryId) {
    final normalizedId = _normalizeCategoryId(categoryId);
    return _themes.containsKey(normalizedId);
  }

  /// Get gradient for category if available
  static Gradient? getGradient(String categoryId) {
    return getTheme(categoryId).gradient;
  }

  /// Normalize category ID to handle various formats
  /// Maps UI category names to internal theme keys
  static String _normalizeCategoryId(String categoryId) {
    // Convert to lowercase and replace spaces/special chars with underscores
    final normalized = categoryId.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('&', 'and');
    
    // Handle specific UI category name mappings
    switch (normalized) {
      case 'data_analysis':
      case 'data_cleaning_and_preprocessing':
        return 'data_analysis';
      case 'web_development':
      case 'frontend_development':
      case 'front_end_development':
        return 'web_development';
      case 'machine_learning':
      case 'machine_learning_algorithms':
      case 'ml_algorithms':
        return 'machine_learning';
      case 'sql':
      case 'sql_and_database':
      case 'sql_database':
        return 'sql';
      case 'python':
      case 'python_fundamentals':
        return 'python';
      case 'statistics':
      case 'statistical_analysis':
        return 'statistics';
      case 'data_visualization':
      case 'visualization':
        return 'data_visualization';
      default:
        return normalized;
    }
  }

  /// Get category color with opacity
  static Color getColorWithOpacity(BuildContext context, String categoryId, double opacity) {
    return getContextAwareColor(context, categoryId).withValues(alpha: opacity);
  }

  /// Get contrasting text color for category background
  static Color getContrastingTextColor(BuildContext context, String categoryId) {
    final backgroundColor = getContextAwareColor(context, categoryId);
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/category_theme.dart';

void main() {
  group('CategoryTheme Tests', () {
    test('should return valid colors for all predefined categories', () {
      const categoryIds = [
        'technical', 'applied', 'behavioral', 'case', 'job',
        'data_analysis', 'web_development', 'machine_learning', 
        'sql', 'python', 'statistics', 'data_visualization'
      ];
      
      for (final categoryId in categoryIds) {
        final color = CategoryTheme.getColor(categoryId);
        final darkColor = CategoryTheme.getColor(categoryId, isDarkMode: true);
        final icon = CategoryTheme.getIcon(categoryId);
        
        expect(color, isA<Color>(), reason: 'Color should be valid for $categoryId');
        expect(darkColor, isA<Color>(), reason: 'Dark color should be valid for $categoryId');
        expect(icon, isA<IconData>(), reason: 'Icon should be valid for $categoryId');
        expect(color, isNot(equals(darkColor)), reason: 'Light and dark colors should be different for $categoryId');
      }
    });
    
    test('should return default theme for unknown category', () {
      final color = CategoryTheme.getColor('unknown_category');
      final icon = CategoryTheme.getIcon('unknown_category');
      
      expect(color, equals(Colors.grey.shade100));
      expect(icon, equals(Icons.category));
    });

    test('should handle category ID normalization correctly', () {
      // Test space replacement
      final color1 = CategoryTheme.getColor('Data Analysis');
      final color2 = CategoryTheme.getColor('data_analysis');
      expect(color1, equals(color2), reason: 'Should normalize spaces to underscores');
      
      // Test case insensitivity
      final color3 = CategoryTheme.getColor('MACHINE_LEARNING');
      final color4 = CategoryTheme.getColor('machine_learning');
      expect(color3, equals(color4), reason: 'Should be case insensitive');
      
      // Test special character handling
      final color5 = CategoryTheme.getColor('SQL & Database');
      final color6 = CategoryTheme.getColor('sql');
      expect(color5, equals(color6), reason: 'Should normalize SQL variations');
    });

    test('should provide proper theme coverage', () {
      final allThemes = CategoryTheme.getAllThemes();
      expect(allThemes.length, greaterThanOrEqualTo(12), reason: 'Should have comprehensive theme coverage');
      
      // Check for essential UI categories
      final essentialCategories = [
        'data_analysis', 'machine_learning', 'sql', 
        'python', 'web_development', 'statistics'
      ];
      
      for (final category in essentialCategories) {
        expect(CategoryTheme.hasTheme(category), true, 
               reason: 'Should have theme for essential category: $category');
      }
    });

    test('should provide contrasting text colors', () {
      const testCategories = ['technical', 'applied', 'behavioral'];
      
      for (final categoryId in testCategories) {
        final lightBg = CategoryTheme.getColor(categoryId);
        final darkBg = CategoryTheme.getColor(categoryId, isDarkMode: true);
        
        // Note: We can't test getContrastingTextColor without BuildContext
        // but we can test that colors have reasonable luminance differences
        expect(lightBg.computeLuminance(), greaterThan(0.3), 
               reason: 'Light background should have reasonable luminance');
        expect(darkBg.computeLuminance(), lessThan(0.7), 
               reason: 'Dark background should have reasonable luminance');
      }
    });

    test('should handle opacity modifications', () {
      const categoryId = 'technical';
      final baseColor = CategoryTheme.getColor(categoryId);
      final transparentColor = baseColor.withValues(alpha: 0.5);
      
      expect(transparentColor.a, equals(0.5), reason: 'Should apply opacity correctly');
      expect(transparentColor.r, equals(baseColor.r), reason: 'RGB values should remain the same');
    });

    test('should map UI category names correctly', () {
      // Test common UI category name mappings
      final mappings = {
        'Data Analysis': 'data_analysis',
        'Machine Learning': 'machine_learning',
        'Web Development': 'web_development',
        'SQL & Database': 'sql',
        'Python Fundamentals': 'python',
        'Data Visualization': 'data_visualization',
      };
      
      for (final entry in mappings.entries) {
        final uiName = entry.key;
        final expectedThemeKey = entry.value;
        
        final color1 = CategoryTheme.getColor(uiName);
        final color2 = CategoryTheme.getColor(expectedThemeKey);
        
        expect(color1, equals(color2), 
               reason: 'UI name "$uiName" should map to theme "$expectedThemeKey"');
      }
    });

    test('should provide consistent icon mapping', () {
      final iconMappings = {
        'technical': Icons.code,
        'sql': Icons.storage,
        'python': Icons.code,
        'machine_learning': Icons.psychology,
        'web_development': Icons.web,
        'statistics': Icons.bar_chart,
        'data_analysis': Icons.analytics,
      };
      
      for (final entry in iconMappings.entries) {
        final categoryId = entry.key;
        final expectedIcon = entry.value;
        final actualIcon = CategoryTheme.getIcon(categoryId);
        
        expect(actualIcon, equals(expectedIcon), 
               reason: 'Category "$categoryId" should have icon $expectedIcon');
      }
    });
  });

  group('CategoryStyle Tests', () {
    test('should create valid CategoryStyle objects', () {
      const style = CategoryStyle(
        color: Colors.blue,
        darkColor: Colors.blueGrey,
        icon: Icons.code,
      );
      
      expect(style.color, equals(Colors.blue));
      expect(style.darkColor, equals(Colors.blueGrey));
      expect(style.icon, equals(Icons.code));
      expect(style.gradient, isNull);
    });

    test('should support gradients', () {
      const gradient = LinearGradient(colors: [Colors.blue, Colors.green]);
      const style = CategoryStyle(
        color: Colors.blue,
        darkColor: Colors.blueGrey,
        icon: Icons.code,
        gradient: gradient,
      );
      
      expect(style.gradient, equals(gradient));
    });
  });
}
import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';

class CategoryFilter extends StatelessWidget {
  final String activeCategory;
  final Function(String) onCategorySelected;
  
  const CategoryFilter({
    super.key,
    required this.activeCategory,
    required this.onCategorySelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    
    // Define all categories with icons and colors
    final categories = [
      {
        'id': 'all', 
        'name': 'All', 
        'icon': Icons.refresh, 
        'color': isDarkMode ? const Color(0xFF1E3A8A) : Colors.blue.shade100,
        'activeColor': isDarkMode ? const Color(0xFF93C5FD) : Colors.blue.shade500,
      },
      {
        'id': 'technical', 
        'name': 'Technical Knowledge', 
        'icon': Icons.bar_chart, 
        'color': isDarkMode ? const Color(0xFF1E3A8A) : Colors.blue.shade100,
        'activeColor': isDarkMode ? const Color(0xFF93C5FD) : Colors.blue.shade500,
      },
      {
        'id': 'applied', 
        'name': 'Applied Skills', 
        'icon': Icons.build, 
        'color': isDarkMode ? const Color(0xFF064E3B) : Colors.green.shade100,
        'activeColor': isDarkMode ? const Color(0xFF6EE7B7) : Colors.green.shade500,
      },
      {
        'id': 'case', 
        'name': 'Case Studies', 
        'icon': Icons.trending_up, 
        'color': isDarkMode ? const Color(0xFF4C1D95) : Colors.purple.shade100,
        'activeColor': isDarkMode ? const Color(0xFFC4B5FD) : Colors.purple.shade500,
      },
      {
        'id': 'behavioral', 
        'name': 'Behavioral Questions', 
        'icon': Icons.psychology, 
        'color': isDarkMode ? const Color(0xFF854D0E) : Colors.yellow.shade100,
        'activeColor': isDarkMode ? const Color(0xFFFDE68A) : Colors.yellow.shade500,
      },
      {
        'id': 'job', 
        'name': 'Job-Specific', 
        'icon': Icons.work, 
        'color': isDarkMode ? const Color(0xFF991B1B) : Colors.red.shade100,
        'activeColor': isDarkMode ? const Color(0xFFFCA5A5) : Colors.red.shade500,
      },
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isActive = activeCategory == category['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: DS.spacingS),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onCategorySelected(category['id'].toString()),
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingM,
                    vertical: DS.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? (category['color'] as Color)
                        : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white),
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    border: Border.all(
                      color: isActive 
                          ? (category['activeColor'] as Color)
                          : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: isActive 
                            ? (isDarkMode ? Colors.white : Colors.blue.shade700)
                            : (isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey.shade700),
                      ),
                      const SizedBox(width: DS.spacingXs),
                      Text(
                        category['name'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                          color: isActive 
                              ? (isDarkMode ? Colors.white : Colors.blue.shade700)
                              : (isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
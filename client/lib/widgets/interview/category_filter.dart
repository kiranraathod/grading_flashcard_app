import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';
import '../../utils/colors.dart';

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
    
    // Define all categories with icons and theme-aware colors
    final categories = [
      {
        'id': 'all', 
        'name': 'All', 
        'icon': Icons.refresh, 
        'color': isDarkMode ? AppColors.categoryTechnicalDark.withValues(alpha: 0.2) : AppColors.categoryTechnical.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('technical', isDarkMode: isDarkMode),
      },
      {
        'id': 'technical', 
        'name': 'Technical Knowledge', 
        'icon': Icons.bar_chart, 
        'color': isDarkMode ? AppColors.categoryTechnicalDark.withValues(alpha: 0.2) : AppColors.categoryTechnical.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('technical', isDarkMode: isDarkMode),
      },
      {
        'id': 'applied', 
        'name': 'Applied Skills', 
        'icon': Icons.build, 
        'color': isDarkMode ? AppColors.categoryBehavioralDark.withValues(alpha: 0.2) : AppColors.categoryBehavioral.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('behavioral', isDarkMode: isDarkMode),
      },
      {
        'id': 'case', 
        'name': 'Case Studies', 
        'icon': Icons.trending_up, 
        'color': isDarkMode ? AppColors.categoryLeadershipDark.withValues(alpha: 0.2) : AppColors.categoryLeadership.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('leadership', isDarkMode: isDarkMode),
      },
      {
        'id': 'behavioral', 
        'name': 'Behavioral Questions', 
        'icon': Icons.psychology, 
        'color': isDarkMode ? AppColors.categorySituationalDark.withValues(alpha: 0.2) : AppColors.categorySituational.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('situational', isDarkMode: isDarkMode),
      },
      {
        'id': 'job', 
        'name': 'Job-Specific', 
        'icon': Icons.work, 
        'color': isDarkMode ? AppColors.categoryGeneralDark.withValues(alpha: 0.2) : AppColors.categoryGeneral.withValues(alpha: 0.1),
        'activeColor': AppColors.getCategoryColor('general', isDarkMode: isDarkMode),
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
                          : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
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
                            : (isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700),
                      ),
                      const SizedBox(width: DS.spacingXs),
                      Text(
                        category['name'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                          color: isActive 
                              ? (isDarkMode ? Colors.white : Colors.blue.shade700)
                              : (isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700),
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
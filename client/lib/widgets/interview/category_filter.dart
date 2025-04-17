import 'package:flutter/material.dart';
import '../../utils/design_system.dart';

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
    // Define all categories with icons and colors
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': Icons.refresh, 'color': Colors.blue.shade100},
      {'id': 'technical', 'name': 'Technical Knowledge', 'icon': Icons.bar_chart, 'color': Colors.blue.shade100},
      {'id': 'applied', 'name': 'Applied Skills', 'icon': Icons.build, 'color': Colors.green.shade100},
      {'id': 'case', 'name': 'Case Studies', 'icon': Icons.trending_up, 'color': Colors.purple.shade100},
      {'id': 'behavioral', 'name': 'Behavioral Questions', 'icon': Icons.psychology, 'color': Colors.yellow.shade100},
      {'id': 'job', 'name': 'Job-Specific', 'icon': Icons.work, 'color': Colors.red.shade100},
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
                        ? category['color'] as Color
                        : Colors.white,
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    border: Border.all(
                      color: isActive 
                          ? Colors.blue.shade500
                          : Colors.grey.shade200,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: isActive 
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: DS.spacingXs),
                      Text(
                        category['name'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                          color: isActive 
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
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
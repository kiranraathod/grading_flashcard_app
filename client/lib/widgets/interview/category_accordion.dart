import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';

class CategoryAccordion extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<String> subtopics;
  final bool isExpanded;
  final VoidCallback onToggle;
  
  const CategoryAccordion({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.subtopics,
    required this.isExpanded,
    required this.onToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingS),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(
          color: context.outlineColor,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(DS.spacingM),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 16,
                      color: context.onPrimaryColor,
                    ),
                  ),
                  
                  const SizedBox(width: DS.spacingS),
                  
                  // Category name
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Topic count
                  Text(
                    '${subtopics.length} topics',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                  
                  const SizedBox(width: DS.spacingS),
                  
                  // Expand/collapse icon
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.onSurfaceVariantColor,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (isExpanded)
            Container(
              padding: const EdgeInsets.only(
                left: 60,
                right: DS.spacingM,
                bottom: DS.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: subtopics.map((topic) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: context.onSurfaceVariantColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topic,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.onSurfaceVariantColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
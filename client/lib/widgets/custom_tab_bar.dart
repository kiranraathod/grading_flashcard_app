import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';

class CustomTabBar extends StatelessWidget {
  final List<String> tabs;
  final String activeTab;
  final Function(String) onTabChanged;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: DS.borderMedium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return GestureDetector(
            onTap: () => onTabChanged(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DS.spacingM,
                vertical: DS.spacingS,
              ),
              decoration: BoxDecoration(
                color: isActive ? context.surfaceColor : Colors.transparent,
                borderRadius: DS.borderMedium,
                boxShadow: isActive ? context.cardShadow : null,
              ),
              child: Text(
                tab,
                style: context.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? context.primaryColor : context.onSurfaceVariantColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
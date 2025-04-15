import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';

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
        color: Colors.grey.shade100,
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
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: DS.borderMedium,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Color.fromRGBO(128, 128, 128, 0.1), // Grey with 0.1 opacity
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
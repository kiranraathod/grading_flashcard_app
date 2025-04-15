import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class FilterDropdownButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final String selectedOption;
  final Function(String) onOptionSelected;
  final bool showChevron;

  const FilterDropdownButton({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: onOptionSelected,
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DS.spacingM,
          vertical: DS.spacingXs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: DS.borderMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
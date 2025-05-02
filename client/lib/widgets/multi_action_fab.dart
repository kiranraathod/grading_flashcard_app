import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// A custom floating action button that shows multiple options when pressed.
/// 
/// This widget creates a green "+" button that shows a pop-up menu with multiple
/// options when pressed. It's designed to replace individual create buttons
/// across the app with a unified experience.
class MultiActionFab extends StatelessWidget {
  /// List of options to display in the menu
  final List<MultiActionFabOption> options;
  
  /// The color of the FAB
  final Color backgroundColor;
  
  /// Icon to display on the FAB
  final IconData icon;
  
  /// Size of the icon
  final double iconSize;
  
  /// Optional tooltip text
  final String? tooltip;

  const MultiActionFab({
    super.key,
    required this.options,
    this.backgroundColor = AppColors.primary,
    this.icon = Icons.add,
    this.iconSize = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(
              red: backgroundColor.r.toDouble(), 
              green: backgroundColor.g.toDouble(), 
              blue: backgroundColor.b.toDouble(), 
              alpha: 76.0
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          _showOptions(context);
        },
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        tooltip: tooltip,
        child: Icon(icon, size: iconSize),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            leading: Icon(option.icon, color: backgroundColor),
            title: Text(option.label),
            onTap: () {
              Navigator.pop(context);
              option.onTap();
            },
          )).toList(),
        ),
      ),
    );
  }
}

/// Represents an option in the MultiActionFab menu
class MultiActionFabOption {
  /// The display label for this option
  final String label;
  
  /// The icon to display for this option
  final IconData icon;
  
  /// The callback to execute when this option is tapped
  final VoidCallback onTap;

  const MultiActionFabOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

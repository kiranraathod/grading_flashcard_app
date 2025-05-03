import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';

class MultiActionFabOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  MultiActionFabOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class MultiActionFab extends StatelessWidget {
  final List<MultiActionFabOption> options;
  final Color? backgroundColor;
  final IconData icon;
  final double iconSize;
  final String? tooltip;

  const MultiActionFab({
    super.key,
    required this.options,
    this.backgroundColor,
    this.icon = Icons.add,
    this.iconSize = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Use the appropriate color based on the theme
    final buttonColor = backgroundColor ?? context.primaryColor;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              buttonColor.r.toInt(),
              buttonColor.g.toInt(),
              buttonColor.b.toInt(),
              0.3,
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
        backgroundColor: buttonColor,
        foregroundColor: context.colorScheme.onPrimary,
        elevation: 0,
        tooltip: tooltip,
        child: Icon(icon, size: iconSize),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            leading: Icon(option.icon, color: context.primaryColor),
            title: Text(
              option.label,
              style: TextStyle(
                color: context.onSurfaceColor,
              ),
            ),
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

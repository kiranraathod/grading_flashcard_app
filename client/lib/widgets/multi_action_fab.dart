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

class MultiActionFab extends StatefulWidget {
  final List<MultiActionFabOption> options;
  final Color? backgroundColor;
  final Color? activeColor;
  final IconData icon;
  final double iconSize;
  final String? tooltip;

  const MultiActionFab({
    super.key,
    required this.options,
    this.backgroundColor,
    this.activeColor,
    this.icon = Icons.add,
    this.iconSize = 24.0,
    this.tooltip,
  });

  @override
  State<MultiActionFab> createState() => _MultiActionFabState();
}

class _MultiActionFabState extends State<MultiActionFab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Use the appropriate color based on the theme
    final buttonColor = widget.backgroundColor ?? context.primaryColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: _isHovered ? 0.5 : 0.3),
              blurRadius: _isHovered ? 12.0 : 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _showOptions(context);
          },
          backgroundColor: _isHovered && widget.activeColor != null 
              ? widget.activeColor 
              : buttonColor,
          foregroundColor: context.colorScheme.onPrimary,
          elevation: 0,
          tooltip: widget.tooltip,
          child: Icon(widget.icon, size: widget.iconSize),
        ),
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
          children: widget.options.map((option) => ListTile(
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

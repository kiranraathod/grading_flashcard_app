import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A class that handles common keyboard shortcuts for the application
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final FocusNode? searchFocusNode;
  final VoidCallback? onSearchShortcut;
  final VoidCallback? onEscapePressed;
  
  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.searchFocusNode,
    this.onSearchShortcut,
    this.onEscapePressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Only handle key down events to avoid duplicate triggers
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        
        // Ctrl+F or Cmd+F for search
        if ((event.logicalKey == LogicalKeyboardKey.keyF) && 
            (HardwareKeyboard.instance.isControlPressed || 
             HardwareKeyboard.instance.isMetaPressed)) {
          if (onSearchShortcut != null) {
            onSearchShortcut!();
            return KeyEventResult.handled;
          } else if (searchFocusNode != null) {
            searchFocusNode!.requestFocus();
            return KeyEventResult.handled;
          }
        }
        
        // Escape to blur focus
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (onEscapePressed != null) {
            onEscapePressed!();
            return KeyEventResult.handled;
          }
        }
        
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

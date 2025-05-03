import 'package:flutter/material.dart';

class ThemeAnimationWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ThemeAnimationWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      duration: duration,
      curve: Curves.easeInOut,
      data: Theme.of(context),
      child: child,
    );
  }
}

// Optional: Create a page transition for theme changes
class ThemeAwarePageRoute<T> extends MaterialPageRoute<T> {
  ThemeAwarePageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

// Theme transition helper for specific widgets
class ThemeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

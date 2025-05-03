import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';

class ThemedGradientContainer extends StatelessWidget {
  final Widget child;
  final bool isInterview;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const ThemedGradientContainer({
    super.key,
    required this.child,
    this.isInterview = false,
    this.borderRadius,
    this.padding,
    this.margin,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: ThemedGradient.getCardGradient(context, isInterview: isInterview),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'design_system.dart';
import 'responsive_helpers.dart';

/// Standardized spacing components for consistent layouts
class DSSpacing {
  DSSpacing._();

  // Vertical Spacing
  static const Widget verticalXS = SizedBox(height: DS.spacing2xs);
  static const Widget verticalS = SizedBox(height: DS.spacingXs);
  static const Widget verticalM = SizedBox(height: DS.spacingS);
  static const Widget verticalL = SizedBox(height: DS.spacingM);
  static const Widget verticalXL = SizedBox(height: DS.spacingL);
  static const Widget vertical2XL = SizedBox(height: DS.spacingXl);
  static const Widget vertical3XL = SizedBox(height: DS.spacing2xl);

  // Horizontal Spacing
  static const Widget horizontalXS = SizedBox(width: DS.spacing2xs);
  static const Widget horizontalS = SizedBox(width: DS.spacingXs);
  static const Widget horizontalM = SizedBox(width: DS.spacingS);
  static const Widget horizontalL = SizedBox(width: DS.spacingM);
  static const Widget horizontalXL = SizedBox(width: DS.spacingL);
  static const Widget horizontal2XL = SizedBox(width: DS.spacingXl);
  static const Widget horizontal3XL = SizedBox(width: DS.spacing2xl);

  // Context-Specific Spacing
  static const Widget formElement = SizedBox(height: DS.spacingM);
  static const Widget cardElement = SizedBox(height: DS.spacingS);
  static const Widget screenSection = SizedBox(height: DS.spacingL);

  // Custom Spacing Methods
  static Widget vertical(double height) => SizedBox(height: height);
  static Widget horizontal(double width) => SizedBox(width: width);

  // Responsive Spacing
  static Widget responsiveVertical(BuildContext context, {
    required double xs, double? sm, double? md, double? lg, double? xl,
  }) {
    final spacing = DS.responsiveValue(context, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
    return SizedBox(height: spacing);
  }

  static Widget responsiveHorizontal(BuildContext context, {
    required double xs, double? sm, double? md, double? lg, double? xl,
  }) {
    final spacing = DS.responsiveValue(context, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
    return SizedBox(width: spacing);
  }
}

/// Standardized padding components for consistent layouts
class DSPadding {
  DSPadding._();

  // Standard Padding Constants
  static const EdgeInsets allXS = EdgeInsets.all(DS.spacing2xs);
  static const EdgeInsets allS = EdgeInsets.all(DS.spacingXs);
  static const EdgeInsets allM = EdgeInsets.all(DS.spacingS);
  static const EdgeInsets allL = EdgeInsets.all(DS.spacingM);
  static const EdgeInsets allXL = EdgeInsets.all(DS.spacingL);
  static const EdgeInsets all2XL = EdgeInsets.all(DS.spacingXl);

  // Symmetric Padding
  static const EdgeInsets horizontalS = EdgeInsets.symmetric(horizontal: DS.spacingXs);
  static const EdgeInsets horizontalM = EdgeInsets.symmetric(horizontal: DS.spacingS);
  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: DS.spacingM);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: DS.spacingL);
  
  static const EdgeInsets verticalS = EdgeInsets.symmetric(vertical: DS.spacingXs);
  static const EdgeInsets verticalM = EdgeInsets.symmetric(vertical: DS.spacingS);
  static const EdgeInsets verticalL = EdgeInsets.symmetric(vertical: DS.spacingM);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: DS.spacingL);

  // Context-Specific Padding
  static const EdgeInsets page = EdgeInsets.all(DS.spacingL);
  static const EdgeInsets card = EdgeInsets.all(DS.spacingM);
  static const EdgeInsets cardCompact = EdgeInsets.all(DS.spacingS);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: DS.spacingM, vertical: DS.spacingS);
  static const EdgeInsets buttonCompact = EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs);
  static const EdgeInsets input = EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs);
  static const EdgeInsets listItem = EdgeInsets.symmetric(horizontal: DS.spacingM, vertical: DS.spacingS);

  // Responsive Padding Methods
  static EdgeInsets responsive(BuildContext context, {
    required EdgeInsets xs, EdgeInsets? sm, EdgeInsets? md, EdgeInsets? lg, EdgeInsets? xl,
  }) {
    return DS.responsiveValue(context, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
  }

  static EdgeInsets responsiveHorizontal(BuildContext context, {
    required double xs, double? sm, double? md, double? lg, double? xl,
  }) {
    final value = DS.responsiveValue(context, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
    return EdgeInsets.symmetric(horizontal: value);
  }

  static EdgeInsets responsiveVertical(BuildContext context, {
    required double xs, double? sm, double? md, double? lg, double? xl,
  }) {
    final value = DS.responsiveValue(context, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
    return EdgeInsets.symmetric(vertical: value);
  }
}
/// Standardized margin components for consistent layouts
class DSMargin {
  DSMargin._();

  // Standard Margins
  static const EdgeInsets allXS = EdgeInsets.all(DS.spacing2xs);
  static const EdgeInsets allS = EdgeInsets.all(DS.spacingXs);
  static const EdgeInsets allM = EdgeInsets.all(DS.spacingS);
  static const EdgeInsets allL = EdgeInsets.all(DS.spacingM);
  static const EdgeInsets allXL = EdgeInsets.all(DS.spacingL);

  // Directional Margins
  static const EdgeInsets bottomXS = EdgeInsets.only(bottom: DS.spacing2xs);
  static const EdgeInsets bottomS = EdgeInsets.only(bottom: DS.spacingXs);
  static const EdgeInsets bottomM = EdgeInsets.only(bottom: DS.spacingS);
  static const EdgeInsets bottomL = EdgeInsets.only(bottom: DS.spacingM);
  static const EdgeInsets bottomXL = EdgeInsets.only(bottom: DS.spacingL);
  
  static const EdgeInsets topXS = EdgeInsets.only(top: DS.spacing2xs);
  static const EdgeInsets topS = EdgeInsets.only(top: DS.spacingXs);
  static const EdgeInsets topM = EdgeInsets.only(top: DS.spacingS);
  static const EdgeInsets topL = EdgeInsets.only(top: DS.spacingM);
  static const EdgeInsets topXL = EdgeInsets.only(top: DS.spacingL);

  // Context-Specific Margins
  static const EdgeInsets card = EdgeInsets.only(bottom: DS.spacingM);
  static const EdgeInsets formElement = EdgeInsets.only(bottom: DS.spacingS);
  static const EdgeInsets section = EdgeInsets.only(bottom: DS.spacingL);
}

/// Convenience widget for applying design system spacing
class DSSpacingWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool responsive;
  
  const DSSpacingWidget({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.responsive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget result = child;
    
    if (padding != null) {
      EdgeInsets finalPadding = padding!;
      if (responsive) {
        final scale = context.isPhone ? 0.8 : 1.0;
        finalPadding = EdgeInsets.fromLTRB(
          padding!.left * scale, padding!.top * scale,
          padding!.right * scale, padding!.bottom * scale,
        );
      }
      result = Padding(padding: finalPadding, child: result);
    }
    
    if (margin != null) {
      EdgeInsets finalMargin = margin!;
      if (responsive) {
        final scale = context.isPhone ? 0.8 : 1.0;
        finalMargin = EdgeInsets.fromLTRB(
          margin!.left * scale, margin!.top * scale,
          margin!.right * scale, margin!.bottom * scale,
        );
      }
      result = Container(margin: finalMargin, child: result);
    }
    
    return result;
  }
}

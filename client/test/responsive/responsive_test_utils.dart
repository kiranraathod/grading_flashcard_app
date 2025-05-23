import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/design_system.dart';
import 'package:flutter_flashcard_app/utils/responsive_helpers.dart';

/// Utilities for testing responsive design systems
class ResponsiveTestUtils {
  ResponsiveTestUtils._();

  /// Common screen sizes for testing
  static const Size phonePortrait = Size(360, 640);
  static const Size phoneLandscape = Size(640, 360);
  static const Size tabletPortrait = Size(768, 1024);
  static const Size tabletLandscape = Size(1024, 768);
  static const Size desktopSmall = Size(1200, 800);
  static const Size desktopLarge = Size(1920, 1080);
  static const Size tvSize = Size(3840, 2160);

  /// Extreme sizes for edge case testing
  static const Size verySmall = Size(240, 320);
  static const Size veryLarge = Size(5120, 2880);

  /// Test a widget at different screen sizes
  static Future<void> testAtMultipleSizes(
    WidgetTester tester,
    Widget widget,
    List<Size> sizes, {
    Function(Size size)? onSizeChange,
  }) async {
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      
      onSizeChange?.call(size);
      
      // Verify no overflow errors
      expect(tester.takeException(), isNull, 
          reason: 'Overflow error at size $size');
    }
  }

  /// Test with different text scale factors
  static Future<void> testWithTextScaling(
    WidgetTester tester,
    Widget Function(double textScale) widgetBuilder,
    List<double> textScales,
  ) async {
    for (final scale in textScales) {
      final widget = widgetBuilder(scale);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      
      // Verify no overflow errors
      expect(tester.takeException(), isNull, 
          reason: 'Overflow error with text scale $scale');
    }
  }

  /// Create a MediaQuery wrapper with custom text scaling
  static Widget createScaledMediaQuery({
    required Widget child,
    double textScale = 1.0,
    Size screenSize = phonePortrait,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScale),
        devicePixelRatio: 2.0,
      ),
      child: child,
    );
  }

  /// Verify that a widget respects design system breakpoints
  static void verifyBreakpointBehavior(
    BuildContext context,
    Size screenSize,
  ) {
    if (screenSize.width < DS.breakpointXs) {
      expect(context.deviceType, equals(DeviceType.phone));
    } else if (screenSize.width < DS.breakpointMd) {
      expect(context.deviceType, equals(DeviceType.phone));
    } else if (screenSize.width < DS.breakpointLg) {
      expect(context.deviceType, equals(DeviceType.tablet));
    } else if (screenSize.width < 1920) {
      expect(context.deviceType, equals(DeviceType.desktop));
    } else {
      expect(context.deviceType, equals(DeviceType.tv));
    }
  }

  /// Standard text scale factors for accessibility testing
  static const List<double> accessibilityTextScales = [
    1.0,   // Normal
    1.15,  // Large
    1.3,   // Extra Large  
    1.5,   // Huge
    2.0,   // Maximum practical
  ];

  /// Standard screen sizes for comprehensive testing
  static const List<Size> standardScreenSizes = [
    verySmall,
    phonePortrait,
    phoneLandscape,
    tabletPortrait,
    tabletLandscape,
    desktopSmall,
    desktopLarge,
    veryLarge,
  ];
}

import 'package:flutter/material.dart';
import 'design_system.dart';

/// Enum representing common device types
enum DeviceType {
  /// Mobile phones (small screens)
  phone,
  
  /// Tablets (medium screens)
  tablet,
  
  /// Desktops and large tablets (large screens)
  desktop,
  
  /// TV and other very large displays
  tv
}

/// Enum representing screen size categories
enum ScreenSizeCategory {
  /// Extra small screens (<360dp)
  xs,
  
  /// Small screens (360-639dp)
  sm,
  
  /// Medium screens (640-767dp)
  md,
  
  /// Large screens (768-1023dp)
  lg,
  
  /// Extra large screens (1024-1279dp)
  xl,
  
  /// Extra extra large screens (>=1280dp)
  xxl
}

/// ResponsiveHelpers provides utilities for creating responsive layouts
/// that adapt to different screen sizes, orientations, and device types.
class ResponsiveHelpers {
  // Private constructor to prevent instantiation
  ResponsiveHelpers._();
  
  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 1920) {
      return DeviceType.tv;
    } else if (width >= DS.breakpointLg) {
      return DeviceType.desktop;
    } else if (width >= DS.breakpointMd) {
      return DeviceType.tablet;
    } else {
      return DeviceType.phone;
    }
  }
  
  /// Get current screen size category based on width
  static ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= DS.breakpoint2xl) {
      return ScreenSizeCategory.xxl;
    } else if (width >= DS.breakpointXl) {
      return ScreenSizeCategory.xl;
    } else if (width >= DS.breakpointLg) {
      return ScreenSizeCategory.lg;
    } else if (width >= DS.breakpointMd) {
      return ScreenSizeCategory.md;
    } else if (width >= DS.breakpointSm) {
      return ScreenSizeCategory.sm;
    } else {
      return ScreenSizeCategory.xs;
    }
  }
  
  /// Get standard horizontal padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return const EdgeInsets.symmetric(horizontal: DS.spacingM);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: DS.spacingL);
      case DeviceType.desktop:
      case DeviceType.tv:
        return const EdgeInsets.symmetric(horizontal: DS.spacingXl);
    }
  }
  
  /// Calculate a responsive dimension based on screen width percentage
  static double widthPercent(BuildContext context, double percent) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (percent / 100);
  }
  
  /// Calculate a responsive dimension based on screen height percentage
  static double heightPercent(BuildContext context, double percent) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (percent / 100);
  }
  
  /// Get appropriate grid column count based on screen width
  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= DS.breakpointXl) return 4;     // Extra large screens: 4 columns
    if (width >= DS.breakpointLg) return 3;     // Large screens: 3 columns
    if (width >= DS.breakpointMd) return 2;     // Medium screens: 2 columns
    return 1;                                    // Small screens: 1 column
  }
  
  /// Create a responsive SliverGridDelegateWithFixedCrossAxisCount
  static SliverGridDelegateWithFixedCrossAxisCount getResponsiveGridDelegate(
    BuildContext context, {
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    int? crossAxisCount,
  }) {
    final deviceType = getDeviceType(context);
    
    // Default values based on device type
    double defaultChildAspectRatio = 1.0;
    double defaultCrossAxisSpacing = DS.spacingM;
    double defaultMainAxisSpacing = DS.spacingM;
    int defaultCrossAxisCount = 1;
    
    switch (deviceType) {
      case DeviceType.phone:
        defaultChildAspectRatio = 1.0;
        defaultCrossAxisSpacing = DS.spacingM;
        defaultMainAxisSpacing = DS.spacingM;
        defaultCrossAxisCount = 1;
        break;
      case DeviceType.tablet:
        defaultChildAspectRatio = 1.2;
        defaultCrossAxisSpacing = DS.spacingL;
        defaultMainAxisSpacing = DS.spacingL;
        defaultCrossAxisCount = 2;
        break;
      case DeviceType.desktop:
        defaultChildAspectRatio = 1.5;
        defaultCrossAxisSpacing = DS.spacingL;
        defaultMainAxisSpacing = DS.spacingL;
        defaultCrossAxisCount = 3;
        break;
      case DeviceType.tv:
        defaultChildAspectRatio = 1.8;
        defaultCrossAxisSpacing = DS.spacingXl;
        defaultMainAxisSpacing = DS.spacingXl;
        defaultCrossAxisCount = 4;
        break;
    }
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      childAspectRatio: childAspectRatio ?? defaultChildAspectRatio,
      crossAxisSpacing: crossAxisSpacing ?? defaultCrossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing ?? defaultMainAxisSpacing,
      crossAxisCount: crossAxisCount ?? defaultCrossAxisCount,
    );
  }
}

/// Extension methods for responsive design on BuildContext
extension ResponsiveContext on BuildContext {
  /// Get the current device type
  DeviceType get deviceType => ResponsiveHelpers.getDeviceType(this);
  
  /// Get the current screen size category
  ScreenSizeCategory get screenSizeCategory => 
      ResponsiveHelpers.getScreenSizeCategory(this);
      
  /// Check if device is a phone
  bool get isPhone => deviceType == DeviceType.phone;
  
  /// Check if device is a tablet
  bool get isTablet => deviceType == DeviceType.tablet;
  
  /// Check if device is a desktop
  bool get isDesktop => deviceType == DeviceType.desktop;
  
  /// Check if device is a TV
  bool get isTV => deviceType == DeviceType.tv;
  
  /// Check if the device is in landscape orientation
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  
  /// Check if the device is in portrait orientation
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
  
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Get standard horizontal padding based on screen size
  EdgeInsets get horizontalPadding => ResponsiveHelpers.getHorizontalPadding(this);
  
  /// Calculate width percentage of screen
  double widthPercent(double percent) => 
      ResponsiveHelpers.widthPercent(this, percent);
  
  /// Calculate height percentage of screen
  double heightPercent(double percent) => 
      ResponsiveHelpers.heightPercent(this, percent);
  
  /// Get the appropriate grid column count
  int get gridColumnCount => ResponsiveHelpers.getGridColumnCount(this);
  
  /// Get the text scale factor adjusted for better readability
  double get adjustedTextScaleFactor {
    // In newer Flutter versions, use textScaler instead of textScaleFactor
    final textScale = MediaQuery.of(this).textScaler.scale(1.0);
    
    // Limit very large text scaling to prevent layout issues
    if (textScale > 1.3) {
      return 1.3;
    }
    
    return textScale;
  }
  
  /// Get responsive padding for containers
  EdgeInsets get responsiveScreenPadding {
    if (isPhone) {
      return const EdgeInsets.all(DS.spacingM);
    } else if (isTablet) {
      return const EdgeInsets.all(DS.spacingL);
    } else {
      return const EdgeInsets.all(DS.spacingXl);
    }
  }
  
  /// Get a responsive width constraint
  BoxConstraints get responsiveWidthConstraints {
    return BoxConstraints(
      maxWidth: deviceType == DeviceType.phone 
          ? double.infinity
          : deviceType == DeviceType.tablet
              ? 680
              : 1024,
    );
  }
  
  /// Get card column count for current screen
  int get cardColumnCount => DS.getCardColumnCountForContext(this);
  
  /// Get effective width accounting for padding
  double getEffectiveWidth({double horizontalPadding = 0}) {
    return screenWidth - horizontalPadding;
  }
  
  /// Get responsive value using design system breakpoints
  T responsiveValue<T>({
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
  }) {
    return DS.responsiveValue(this, xs: xs, sm: sm, md: md, lg: lg, xl: xl);
  }
  
  /// Get responsive grid delegate with optimal defaults
  SliverGridDelegateWithFixedCrossAxisCount get responsiveGridDelegate {
    return ResponsiveHelpers.getResponsiveGridDelegate(this);
  }
  
  /// Get responsive grid delegate for card layouts
  SliverGridDelegateWithFixedCrossAxisCount getCardGridDelegate({
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final columnCount = cardColumnCount;
    final spacing = orientationAwareSpacing;
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columnCount,
      childAspectRatio: childAspectRatio ?? (isPhone ? 1.0 : 1.2),
      crossAxisSpacing: crossAxisSpacing ?? spacing,
      mainAxisSpacing: mainAxisSpacing ?? spacing,
    );
  }
  
  /// Get orientation-aware spacing
  double get orientationAwareSpacing {
    if (isLandscape && isPhone) {
      return DS.spacingS; // Reduce spacing in landscape phone mode
    } else if (isLandscape && isTablet) {
      return DS.spacingL; // Increase spacing in landscape tablet mode
    }
    return isPhone ? DS.spacingM : (isTablet ? DS.spacingL : DS.spacingXl);
  }
}
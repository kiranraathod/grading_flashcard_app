import 'package:flutter/material.dart';
import 'design_system.dart';
import 'responsive_helpers.dart';

/// ResponsiveText provides utilities for text scaling and responsive typography.
class ResponsiveText {
  // Private constructor to prevent instantiation
  ResponsiveText._();
  
  /// Scale factor for different device types
  static double getDeviceScaleFactor(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
      case DeviceType.tv:
        return 1.4;
    }
  }
  
  /// Get a scaled text style for headings based on device type
  static TextStyle getHeadingStyle(BuildContext context, HeadingSize size) {
    final deviceType = ResponsiveHelpers.getDeviceType(context);
    // Use textScaler instead of textScaleFactor
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final deviceScaleFactor = getDeviceScaleFactor(deviceType);
    
    // Limit the maximum scaling to prevent layout issues
    final effectiveScaleFactor = textScale * deviceScaleFactor;
    final cappedScaleFactor = effectiveScaleFactor > 1.5 ? 1.5 : effectiveScaleFactor;
    
    TextStyle baseStyle;
    switch (size) {
      case HeadingSize.xl:
        baseStyle = const TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          height: 1.2,
        );
        break;
      case HeadingSize.large:
        baseStyle = DS.headingLarge;
        break;
      case HeadingSize.medium:
        baseStyle = DS.headingMedium;
        break;
      case HeadingSize.small:
        baseStyle = DS.headingSmall;
        break;
    }
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * cappedScaleFactor,
    );
  }
  
  /// Get a scaled text style for body text based on device type
  static TextStyle getBodyStyle(BuildContext context, BodySize size) {
    final deviceType = ResponsiveHelpers.getDeviceType(context);
    // Use textScaler instead of textScaleFactor
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final deviceScaleFactor = getDeviceScaleFactor(deviceType);
    
    // Limit the maximum scaling to prevent layout issues
    final effectiveScaleFactor = textScale * deviceScaleFactor;
    final cappedScaleFactor = effectiveScaleFactor > 1.5 ? 1.5 : effectiveScaleFactor;
    
    TextStyle baseStyle;
    switch (size) {
      case BodySize.large:
        baseStyle = DS.bodyLarge;
        break;
      case BodySize.medium:
        baseStyle = DS.bodyMedium;
        break;
      case BodySize.small:
        baseStyle = DS.bodySmall;
        break;
    }
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * cappedScaleFactor,
    );
  }
  
  /// Get responsive line height based on text size and device
  static double getLineHeight(BuildContext context, double fontSize) {
    final deviceType = ResponsiveHelpers.getDeviceType(context);
    
    // Larger screens benefit from slightly increased line height for readability
    switch (deviceType) {
      case DeviceType.phone:
        return fontSize < 16 ? 1.4 : 1.5;
      case DeviceType.tablet:
        return fontSize < 16 ? 1.4 : 1.6;
      case DeviceType.desktop:
      case DeviceType.tv:
        return fontSize < 16 ? 1.5 : 1.7;
    }
  }
}

/// Enum for heading sizes
enum HeadingSize {
  /// Extra large heading (32px base)
  xl,
  
  /// Large heading (24px base)
  large,
  
  /// Medium heading (20px base)
  medium,
  
  /// Small heading (18px base)
  small,
}

/// Enum for body text sizes
enum BodySize {
  /// Large body text (16px base)
  large,
  
  /// Medium body text (14px base)
  medium,
  
  /// Small body text (12px base)
  small,
}

/// Extension methods for responsive typography on BuildContext
extension ResponsiveTextContext on BuildContext {
  /// Get a responsive heading style
  TextStyle responsiveHeading(HeadingSize size) => 
      ResponsiveText.getHeadingStyle(this, size);
      
  /// Get a responsive body text style
  TextStyle responsiveBody(BodySize size) => 
      ResponsiveText.getBodyStyle(this, size);
      
  /// Get a responsive line height
  double responsiveLineHeight(double fontSize) => 
      ResponsiveText.getLineHeight(this, fontSize);
      
  /// Get heading XL style
  TextStyle get headingXl => responsiveHeading(HeadingSize.xl);
  
  /// Get heading large style
  TextStyle get headingLarge => responsiveHeading(HeadingSize.large);
  
  /// Get heading medium style
  TextStyle get headingMedium => responsiveHeading(HeadingSize.medium);
  
  /// Get heading small style
  TextStyle get headingSmall => responsiveHeading(HeadingSize.small);
  
  /// Get body large style
  TextStyle get bodyLarge => responsiveBody(BodySize.large);
  
  /// Get body medium style
  TextStyle get bodyMedium => responsiveBody(BodySize.medium);
  
  /// Get body small style
  TextStyle get bodySmall => responsiveBody(BodySize.small);
}
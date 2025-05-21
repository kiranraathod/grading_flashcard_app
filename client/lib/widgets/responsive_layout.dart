import 'package:flutter/material.dart';
import '../utils/responsive_helpers.dart';

/// ResponsiveLayout is a widget that allows you to specify different layouts 
/// based on screen size, device type, and orientation.
class ResponsiveLayout extends StatelessWidget {
  /// Builder function for phone layouts
  final Widget Function(BuildContext context)? phoneBuilder;
  
  /// Builder function for tablet layouts
  final Widget Function(BuildContext context)? tabletBuilder;
  
  /// Builder function for desktop layouts
  final Widget Function(BuildContext context)? desktopBuilder;
  
  /// Builder function for TV layouts
  final Widget Function(BuildContext context)? tvBuilder;
  
  /// Builder function for portrait orientation
  final Widget Function(BuildContext context)? portraitBuilder;
  
  /// Builder function for landscape orientation
  final Widget Function(BuildContext context)? landscapeBuilder;
  
  /// Fallback builder function when no specific builder matches
  final Widget Function(BuildContext context) defaultBuilder;

  /// Constructor for device-based responsive layout
  const ResponsiveLayout({
    super.key,
    this.phoneBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    this.tvBuilder,
    this.portraitBuilder,
    this.landscapeBuilder,
    required this.defaultBuilder,
  });

  /// Factory constructor for orientation-based responsive layout
  factory ResponsiveLayout.orientation({
    Key? key,
    required Widget Function(BuildContext context) portraitBuilder,
    required Widget Function(BuildContext context) landscapeBuilder,
  }) {
    return ResponsiveLayout(
      key: key,
      portraitBuilder: portraitBuilder,
      landscapeBuilder: landscapeBuilder,
      defaultBuilder: portraitBuilder, // Default to portrait if orientation can't be determined
    );
  }
  
  /// Factory constructor for device-type-based responsive layout
  factory ResponsiveLayout.deviceType({
    Key? key,
    required Widget Function(BuildContext context) phoneBuilder,
    Widget Function(BuildContext context)? tabletBuilder,
    Widget Function(BuildContext context)? desktopBuilder,
    Widget Function(BuildContext context)? tvBuilder,
  }) {
    return ResponsiveLayout(
      key: key,
      phoneBuilder: phoneBuilder,
      tabletBuilder: tabletBuilder,
      desktopBuilder: desktopBuilder,
      tvBuilder: tvBuilder,
      defaultBuilder: phoneBuilder, // Default to phone if device type can't be determined
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check orientation first if orientation builders are provided
    if (portraitBuilder != null || landscapeBuilder != null) {
      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
      
      if (isPortrait && portraitBuilder != null) {
        return portraitBuilder!(context);
      } else if (!isPortrait && landscapeBuilder != null) {
        return landscapeBuilder!(context);
      }
    }
    
    // Then check device type if device type builders are provided
    final deviceType = ResponsiveHelpers.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return phoneBuilder != null ? phoneBuilder!(context) : defaultBuilder(context);
      case DeviceType.tablet:
        return tabletBuilder != null ? tabletBuilder!(context) : (phoneBuilder != null ? phoneBuilder!(context) : defaultBuilder(context));
      case DeviceType.desktop:
        return desktopBuilder != null ? desktopBuilder!(context) : (tabletBuilder != null ? tabletBuilder!(context) : (phoneBuilder != null ? phoneBuilder!(context) : defaultBuilder(context)));
      case DeviceType.tv:
        return tvBuilder != null ? tvBuilder!(context) : (desktopBuilder != null ? desktopBuilder!(context) : (tabletBuilder != null ? tabletBuilder!(context) : (phoneBuilder != null ? phoneBuilder!(context) : defaultBuilder(context))));
    }
  }
}

/// A widget that builds different layouts based on screen size breakpoints
class BreakpointLayout extends StatelessWidget {
  /// Builder function for extra small screens
  final Widget Function(BuildContext context)? xsBuilder;
  
  /// Builder function for small screens
  final Widget Function(BuildContext context)? smBuilder;
  
  /// Builder function for medium screens
  final Widget Function(BuildContext context)? mdBuilder;
  
  /// Builder function for large screens
  final Widget Function(BuildContext context)? lgBuilder;
  
  /// Builder function for extra large screens
  final Widget Function(BuildContext context)? xlBuilder;
  
  /// Builder function for extra extra large screens
  final Widget Function(BuildContext context)? xxlBuilder;
  
  /// Fallback builder function when no specific builder matches
  final Widget Function(BuildContext context) defaultBuilder;

  /// Constructor
  const BreakpointLayout({
    super.key,
    this.xsBuilder,
    this.smBuilder,
    this.mdBuilder,
    this.lgBuilder,
    this.xlBuilder,
    this.xxlBuilder,
    required this.defaultBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final screenSizeCategory = ResponsiveHelpers.getScreenSizeCategory(context);
    
    switch (screenSizeCategory) {
      case ScreenSizeCategory.xs:
        return xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context);
      case ScreenSizeCategory.sm:
        return smBuilder != null ? smBuilder!(context) : (xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context));
      case ScreenSizeCategory.md:
        return mdBuilder != null ? mdBuilder!(context) : (smBuilder != null ? smBuilder!(context) : (xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context)));
      case ScreenSizeCategory.lg:
        return lgBuilder != null ? lgBuilder!(context) : (mdBuilder != null ? mdBuilder!(context) : (smBuilder != null ? smBuilder!(context) : (xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context))));
      case ScreenSizeCategory.xl:
        return xlBuilder != null ? xlBuilder!(context) : (lgBuilder != null ? lgBuilder!(context) : (mdBuilder != null ? mdBuilder!(context) : (smBuilder != null ? smBuilder!(context) : (xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context)))));
      case ScreenSizeCategory.xxl:
        return xxlBuilder != null ? xxlBuilder!(context) : (xlBuilder != null ? xlBuilder!(context) : (lgBuilder != null ? lgBuilder!(context) : (mdBuilder != null ? mdBuilder!(context) : (smBuilder != null ? smBuilder!(context) : (xsBuilder != null ? xsBuilder!(context) : defaultBuilder(context))))));
    }
  }
}
import 'package:flutter/material.dart';
import 'colors.dart';
import 'responsive_helpers.dart';

/// A comprehensive design system with spacing, sizing, elevation, and responsive breakpoints
///
/// This class centralizes all UI constants to maintain consistency across the application
/// and enable responsive design across different screen sizes.
class DS {
  // Private constructor to prevent instantiation
  DS._();

  // MARK: - Spacing Scale
  /// Spacing scale based on 4px increments
  /// Provides consistent spacing throughout the application
  static const double spacing2xs = 4.0; // Tiny spacing
  static const double spacingXs = 8.0; // Extra small spacing
  static const double spacingS = 12.0; // Small spacing
  static const double spacingM = 16.0; // Medium spacing (base)
  static const double spacingL = 24.0; // Large spacing
  static const double spacingXl = 32.0; // Extra large spacing
  static const double spacing2xl = 48.0; // Double extra large spacing
  static const double spacing3xl = 64.0; // Triple extra large spacing

  // MARK: - Icon Sizes
  /// Standard icon sizes
  static const double iconSizeXs = 16.0; // Extra small icons
  static const double iconSizeS = 20.0; // Small icons
  static const double iconSizeM = 24.0; // Medium icons (default)
  static const double iconSizeL = 32.0; // Large icons
  static const double iconSizeXl = 40.0; // Extra large icons
  static const double iconSize2xl = 48.0; // Double extra large icons

  // MARK: - Component Sizes
  /// Standard component dimensions
  static const double buttonHeightS = 32.0; // Small buttons
  static const double buttonHeightM = 40.0; // Medium buttons (default)
  static const double buttonHeightL = 48.0; // Large buttons
  static const double buttonHeightXl = 56.0; // Extra large buttons

  static const double inputHeightS = 32.0; // Small inputs
  static const double inputHeightM = 40.0; // Medium inputs (default)
  static const double inputHeightL = 48.0; // Large inputs

  static const double avatarSizeXs = 24.0; // Extra small avatars
  static const double avatarSizeS = 32.0; // Small avatars
  static const double avatarSizeM = 40.0; // Medium avatars
  static const double avatarSizeL = 56.0; // Large avatars
  static const double avatarSizeXl = 72.0; // Extra large avatars
  static const double avatarSize2xl = 96.0; // Double extra large avatars

  // Card component dimensions
  static const double cardHeight = 201.0; // Standard card height
  static const double cardHeightCompact = 160.0; // Compact card height

  // MARK: - Durations
  /// Animation durations for consistent motion
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // MARK: - Typography (Backward Compatible)
  /// Theme-aware text style constants that work without context
  /// For better theming, prefer context.titleLarge, context.bodyMedium, etc.

  /// Heading styles - use context.headlineLarge, headlineMedium, headlineSmall instead
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Colors.black87, // Will be overridden by theme
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Colors.black87, // Will be overridden by theme
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Colors.black87, // Will be overridden by theme
  );

  /// Body styles - use context.bodyLarge, bodyMedium, bodySmall instead
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Colors.black87, // Will be overridden by theme
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Colors.black87, // Will be overridden by theme
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Colors.black54, // Will be overridden by theme
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Colors.black54, // Will be overridden by theme
  );

  // MARK: - Theme-Aware Typography Methods
  /// Get theme-aware heading styles - PREFERRED over static const styles above
  static TextStyle themedHeadingLarge(BuildContext context) => TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle themedHeadingMedium(BuildContext context) => TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle themedHeadingSmall(BuildContext context) => TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle themedBodyLarge(BuildContext context) => TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle themedBodyMedium(BuildContext context) => TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle themedBodySmall(BuildContext context) => TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // MARK: - Borders & Radii
  /// Border radius values for consistent corner rounding
  static const double borderRadiusXs = 4.0; // Very subtle rounding
  static const double borderRadiusSmall = 8.0; // Standard small rounding
  static const double borderRadiusMedium = 12.0; // Medium rounding for cards
  static const double borderRadiusLarge = 16.0; // Large rounding for modals
  static const double borderRadiusXlarge = 24.0; // Extra large rounding
  static const double borderRadiusFull = 1000.0; // Effectively circular

  // Common border radius shapes
  static final BorderRadius borderXs = BorderRadius.circular(borderRadiusXs);
  static final BorderRadius borderSmall = BorderRadius.circular(
    borderRadiusSmall,
  );
  static final BorderRadius borderMedium = BorderRadius.circular(
    borderRadiusMedium,
  );
  static final BorderRadius borderLarge = BorderRadius.circular(
    borderRadiusLarge,
  );
  static final BorderRadius borderXlarge = BorderRadius.circular(
    borderRadiusXlarge,
  );
  static final BorderRadius borderFull = BorderRadius.circular(
    borderRadiusFull,
  );

  // Common border styles
  static const BorderSide borderThin = BorderSide(
    width: 1.0,
    color: Color(0xFFE5E7EB),
  ); // Gray-200
  static const BorderSide borderMediumWidth = BorderSide(
    width: 2.0,
    color: Color(0xFFE5E7EB),
  ); // Gray-200

  // MARK: - Elevation Values
  /// Elevation values for shadows and material elevation
  static const double elevationNone = 0.0; // No elevation
  static const double elevationXs = 1.0; // Minimal elevation (subtle)
  static const double elevationS = 2.0; // Small elevation (cards)
  static const double elevationM = 4.0; // Medium elevation (dropdowns)
  static const double elevationL = 8.0; // Large elevation (dialogs)
  static const double elevationXl = 16.0; // Extra large elevation (modals)
  static const double elevationNavigation =
      3.0; // Specific for navigation components

  /// Helper method for consistent shadows based on elevation
  static List<BoxShadow> getShadow(double elevation, {Color? color}) {
    final shadowColor = color ?? Colors.black;

    if (elevation <= elevationNone) return [];

    if (elevation <= elevationXs) {
      return [
        BoxShadow(
          color: shadowColor.withAlpha(26), // ~10% opacity
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }

    if (elevation <= elevationS) {
      return [
        BoxShadow(
          color: shadowColor.withAlpha(26), // ~10% opacity
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }

    if (elevation <= elevationM) {
      return [
        BoxShadow(
          color: shadowColor.withAlpha(20), // ~8% opacity
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColor.withAlpha(26), // ~10% opacity
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    if (elevation <= elevationL) {
      return [
        BoxShadow(
          color: shadowColor.withAlpha(20), // ~8% opacity
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: shadowColor.withAlpha(31), // ~12% opacity
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }

    // elevationXl and above
    return [
      BoxShadow(
        color: shadowColor.withAlpha(20), // ~8% opacity
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: shadowColor.withAlpha(31), // ~12% opacity
        blurRadius: 24,
        offset: const Offset(0, 16),
      ),
    ];
  }

  // MARK: - Screen Breakpoints
  /// Breakpoints for responsive design
  /// Used to adjust layouts based on screen width
  static const double breakpointXs =
      360.0; // Extra small screens (small phones)
  static const double breakpointSm = 640.0; // Small screens (phones)
  static const double breakpointMd = 768.0; // Medium screens (tablets)
  static const double breakpointLg = 1024.0; // Large screens (desktops)
  static const double breakpointXl =
      1280.0; // Extra large screens (large desktops)
  static const double breakpoint2xl = 1536.0; // Double extra large screens

  // MARK: - Card Grid Breakpoints
  /// Specialized breakpoints for card grid layouts
  /// These are optimized for card aspect ratios and optimal content display
  static const double cardBreakpoint1Col = 0.0; // Always allow 1 column
  static const double cardBreakpoint2Col = 320.0; // 2 columns for small screens
  static const double cardBreakpoint3Col =
      500.0; // 3 columns for medium screens
  static const double cardBreakpoint4Col = 700.0; // 4 columns for large screens
  static const double cardBreakpoint5Col =
      900.0; // 5 columns for extra large screens

  // MARK: - Content Width Breakpoints
  /// Breakpoints for optimal content width at different screen sizes
  static const double contentMaxWidthSm = 540.0; // Small content container
  static const double contentMaxWidthMd = 720.0; // Medium content container
  static const double contentMaxWidthLg = 960.0; // Large content container
  static const double contentMaxWidthXl =
      1140.0; // Extra large content container
  static const double contentMaxWidth2xl =
      1320.0; // Double extra large content container

  /// Helper methods for responsive design
  static bool isExtraSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointXs;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointSm;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMd;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointLg;
  }

  static bool isExtraLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointXl;
  }

  /// Returns a value based on the screen size
  static T responsiveValue<T>(
    BuildContext context, {
    required T xs, // Extra small screens (default)
    T? sm, // Small screens
    T? md, // Medium screens
    T? lg, // Large screens
    T? xl, // Extra large screens
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= breakpointXl && xl != null) return xl;
    if (width >= breakpointLg && lg != null) return lg;
    if (width >= breakpointMd && md != null) return md;
    if (width >= breakpointSm && sm != null) return sm;
    return xs;
  }

  /// Get optimal card grid column count based on available width
  static int getCardColumnCount(double availableWidth) {
    if (availableWidth >= cardBreakpoint5Col) return 5;
    if (availableWidth >= cardBreakpoint4Col) return 4;
    if (availableWidth >= cardBreakpoint3Col) return 3;
    if (availableWidth >= cardBreakpoint2Col) return 2;
    return 1;
  }

  /// Get optimal card grid column count based on context
  static int getCardColumnCountForContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getCardColumnCount(width);
  }

  /// Get optimal content container width based on screen size
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= breakpointXl) return contentMaxWidth2xl;
    if (width >= breakpointLg) return contentMaxWidthXl;
    if (width >= breakpointMd) return contentMaxWidthLg;
    if (width >= breakpointSm) return contentMaxWidthMd;
    return contentMaxWidthSm;
  }

  // MARK: - Button styles
  /// Pre-configured button styles to ensure consistency
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingS,
    ),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
    elevation: elevationXs,
  );

  static final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingS,
    ),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
    side: borderThin,
  );

  static final ButtonStyle ghostButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingS,
    ),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
  );

  // MARK: - Responsive Typography Scaling
  /// Get responsive text scale factor based on screen size and device type
  static double getTextScaleFactor(BuildContext context) {
    final deviceType = ResponsiveHelpers.getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Base scale factors by device type
    switch (deviceType) {
      case DeviceType.phone:
        if (screenWidth < DS.breakpointXs) return 0.9; // Very small phones
        return 1.0; // Normal phones
      case DeviceType.tablet:
        return 1.1; // Slightly larger for tablets
      case DeviceType.desktop:
        return 1.0; // Standard for desktop
      case DeviceType.tv:
        return 1.2; // Larger for TV viewing distance
    }
  }

  /// Apply responsive text scaling to a TextStyle
  static TextStyle scaleTextStyle(BuildContext context, TextStyle style) {
    final scaleFactor = getTextScaleFactor(context);
    return style.copyWith(fontSize: (style.fontSize ?? 14.0) * scaleFactor);
  }

  /// Get responsive typography styles that scale with device type
  /// Prefer using context.titleLarge, context.bodyMedium, etc. instead
  static TextStyle responsiveHeadingLarge(BuildContext context) =>
      scaleTextStyle(context, themedHeadingLarge(context));

  static TextStyle responsiveHeadingMedium(BuildContext context) =>
      scaleTextStyle(context, themedHeadingMedium(context));

  static TextStyle responsiveHeadingSmall(BuildContext context) =>
      scaleTextStyle(context, themedHeadingSmall(context));

  static TextStyle responsiveBodyLarge(BuildContext context) =>
      scaleTextStyle(context, themedBodyLarge(context));

  static TextStyle responsiveBodyMedium(BuildContext context) =>
      scaleTextStyle(context, themedBodyMedium(context));

  static TextStyle responsiveBodySmall(BuildContext context) =>
      scaleTextStyle(context, themedBodySmall(context));

  // MARK: - Typography Accessibility
  /// WCAG 2.1 AA minimum font sizes for accessibility compliance
  static const double minFontSizeAA = 12.0; // Minimum for AA compliance
  static const double minFontSizeAAA = 14.0; // Recommended for AAA compliance
  static const double minTouchTargetSize = 44.0; // Minimum touch target size

  /// Verify if a text size meets WCAG accessibility standards
  static bool isAccessibleFontSize(double fontSize, {bool strictAAA = false}) {
    return strictAAA ? fontSize >= minFontSizeAAA : fontSize >= minFontSizeAA;
  }

  /// Get accessibility-compliant text style that ensures minimum font sizes
  static TextStyle ensureAccessibleFontSize(
    TextStyle style, {
    bool strictAAA = false,
  }) {
    final minSize = strictAAA ? minFontSizeAAA : minFontSizeAA;
    final currentSize = style.fontSize ?? 14.0;

    if (currentSize < minSize) {
      return style.copyWith(fontSize: minSize);
    }
    return style;
  }

  /// Get accessible typography with proper contrast and sizing
  static TextStyle accessibleHeadingLarge(BuildContext context) =>
      ensureAccessibleFontSize(themedHeadingLarge(context));

  static TextStyle accessibleBodyMedium(BuildContext context) =>
      ensureAccessibleFontSize(themedBodyMedium(context));

  static TextStyle accessibleBodySmall(BuildContext context) =>
      ensureAccessibleFontSize(themedBodySmall(context));
}

/// Extension methods for convenient access to design system values
extension DesignSystemContext on BuildContext {
  /// Access screen dimensions
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Check device type (delegated to ResponsiveContext to avoid conflicts)
  // Note: Use context.isPhone, context.isTablet, context.isDesktop from ResponsiveContext

  /// Get device orientation (delegated to ResponsiveContext to avoid conflicts)
  // Note: Use context.isLandscape, context.isPortrait from ResponsiveContext

  /// Scale a value based on screen width
  double scaleWidth(double value) {
    double scaleFactor = screenWidth / DS.breakpointMd;
    // Limiting scale factor to reasonable range
    scaleFactor = scaleFactor.clamp(0.7, 1.3);
    return value * scaleFactor;
  }

  /// Scale a value based on screen height
  double scaleHeight(double value) {
    double scaleFactor = screenHeight / 800.0; // Base height
    // Limiting scale factor to reasonable range
    scaleFactor = scaleFactor.clamp(0.7, 1.3);
    return value * scaleFactor;
  }

  /// Get spacing value scaled to screen size (using responsive context for device type)
  double get spacing2xs =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacing2xs * 0.8
          : DS.spacing2xs;
  double get spacingXs =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacingXs * 0.8
          : DS.spacingXs;
  double get spacingS =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacingS * 0.9
          : DS.spacingS;
  double get spacingM =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacingM * 0.9
          : DS.spacingM;
  double get spacingL =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacingL * 0.9
          : DS.spacingL;
  double get spacingXl =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacingXl * 0.9
          : DS.spacingXl;
  double get spacing2xl =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacing2xl * 0.9
          : DS.spacing2xl;
  double get spacing3xl =>
      ResponsiveHelpers.getDeviceType(this) == DeviceType.phone
          ? DS.spacing3xl * 0.9
          : DS.spacing3xl;

  /// Helper for responsive padding (useful for container padding)
  EdgeInsets get responsivePadding {
    final deviceType = ResponsiveHelpers.getDeviceType(this);
    return EdgeInsets.all(
      deviceType == DeviceType.phone
          ? DS.spacingS
          : (deviceType == DeviceType.tablet ? DS.spacingM : DS.spacingL),
    );
  }

  /// Helper for grid spacing (useful for GridView spacing)
  double get gridSpacing {
    final deviceType = ResponsiveHelpers.getDeviceType(this);
    return deviceType == DeviceType.phone
        ? DS.spacingM
        : (deviceType == DeviceType.tablet ? DS.spacingL : DS.spacingXl);
  }
}

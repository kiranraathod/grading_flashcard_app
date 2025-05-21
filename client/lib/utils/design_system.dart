import 'package:flutter/material.dart';
import 'colors.dart';

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
  static const double spacing2xs = 4.0;  // Tiny spacing
  static const double spacingXs = 8.0;   // Extra small spacing
  static const double spacingS = 12.0;   // Small spacing
  static const double spacingM = 16.0;   // Medium spacing (base)
  static const double spacingL = 24.0;   // Large spacing
  static const double spacingXl = 32.0;  // Extra large spacing
  static const double spacing2xl = 48.0; // Double extra large spacing
  static const double spacing3xl = 64.0; // Triple extra large spacing
  
  // MARK: - Icon Sizes
  /// Standard icon sizes
  static const double iconSizeXs = 16.0;  // Extra small icons
  static const double iconSizeS = 20.0;   // Small icons
  static const double iconSizeM = 24.0;   // Medium icons (default)
  static const double iconSizeL = 32.0;   // Large icons
  static const double iconSizeXl = 40.0;  // Extra large icons
  static const double iconSize2xl = 48.0; // Double extra large icons
  
  // MARK: - Component Sizes
  /// Standard component dimensions
  static const double buttonHeightS = 32.0;  // Small buttons
  static const double buttonHeightM = 40.0;  // Medium buttons (default)
  static const double buttonHeightL = 48.0;  // Large buttons
  static const double buttonHeightXl = 56.0; // Extra large buttons
  
  static const double inputHeightS = 32.0;  // Small inputs
  static const double inputHeightM = 40.0;  // Medium inputs (default)
  static const double inputHeightL = 48.0;  // Large inputs
  
  static const double avatarSizeXs = 24.0;  // Extra small avatars
  static const double avatarSizeS = 32.0;   // Small avatars
  static const double avatarSizeM = 40.0;   // Medium avatars
  static const double avatarSizeL = 56.0;   // Large avatars
  static const double avatarSizeXl = 72.0;  // Extra large avatars
  static const double avatarSize2xl = 96.0; // Double extra large avatars
  
  // MARK: - Durations
  /// Animation durations for consistent motion
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  // MARK: - Typography
  /// Text styles with consistent sizing and spacing
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle badgeText = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  // MARK: - Borders & Radii
  /// Border radius values for consistent corner rounding
  static const double borderRadiusXs = 4.0;      // Very subtle rounding
  static const double borderRadiusSmall = 8.0;   // Standard small rounding
  static const double borderRadiusMedium = 12.0; // Medium rounding for cards
  static const double borderRadiusLarge = 16.0;  // Large rounding for modals
  static const double borderRadiusXlarge = 24.0; // Extra large rounding
  static const double borderRadiusFull = 1000.0; // Effectively circular
  
  // Common border radius shapes
  static final BorderRadius borderXs = BorderRadius.circular(borderRadiusXs);
  static final BorderRadius borderSmall = BorderRadius.circular(borderRadiusSmall);
  static final BorderRadius borderMedium = BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius borderLarge = BorderRadius.circular(borderRadiusLarge);
  static final BorderRadius borderXlarge = BorderRadius.circular(borderRadiusXlarge);
  static final BorderRadius borderFull = BorderRadius.circular(borderRadiusFull);
  
  // Common border styles
  static const BorderSide borderThin = BorderSide(width: 1.0, color: Color(0xFFE5E7EB)); // Gray-200
  static const BorderSide borderMediumWidth = BorderSide(width: 2.0, color: Color(0xFFE5E7EB)); // Gray-200
  
  // MARK: - Elevation Values
  /// Elevation values for shadows and material elevation
  static const double elevationNone = 0.0;   // No elevation
  static const double elevationXs = 1.0;     // Minimal elevation (subtle)
  static const double elevationS = 2.0;      // Small elevation (cards)
  static const double elevationM = 4.0;      // Medium elevation (dropdowns)
  static const double elevationL = 8.0;      // Large elevation (dialogs)
  static const double elevationXl = 16.0;    // Extra large elevation (modals)
  static const double elevationNavigation = 3.0;  // Specific for navigation components
  
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
  static const double breakpointXs = 360.0;  // Extra small screens (small phones)
  static const double breakpointSm = 640.0;  // Small screens (phones)
  static const double breakpointMd = 768.0;  // Medium screens (tablets)
  static const double breakpointLg = 1024.0; // Large screens (desktops)
  static const double breakpointXl = 1280.0; // Extra large screens (large desktops)
  static const double breakpoint2xl = 1536.0; // Double extra large screens
  
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
    required T xs,  // Extra small screens (default)
    T? sm,          // Small screens
    T? md,          // Medium screens
    T? lg,          // Large screens
    T? xl,          // Extra large screens
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointXl && xl != null) return xl;
    if (width >= breakpointLg && lg != null) return lg;
    if (width >= breakpointMd && md != null) return md;
    if (width >= breakpointSm && sm != null) return sm;
    return xs;
  }
  
  // MARK: - Button styles
  /// Pre-configured button styles to ensure consistency
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
    elevation: elevationXs,
  );
  
  static final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
    side: borderThin,
  );
  
  static final ButtonStyle ghostButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    shape: RoundedRectangleBorder(borderRadius: borderMedium),
  );
}

/// Extension methods for convenient access to design system values
extension DesignSystemContext on BuildContext {
  /// Access screen dimensions
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  
  /// Check device type
  bool get isPhone => screenWidth < DS.breakpointMd;
  bool get isTablet => screenWidth >= DS.breakpointMd && screenWidth < DS.breakpointLg;
  bool get isDesktop => screenWidth >= DS.breakpointLg;
  
  /// Get device orientation
  bool get isLandscape => screenWidth > screenHeight;
  bool get isPortrait => screenWidth <= screenHeight;
  
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
  
  /// Get spacing value scaled to screen size
  double get spacing2xs => isPhone ? DS.spacing2xs * 0.8 : DS.spacing2xs;
  double get spacingXs => isPhone ? DS.spacingXs * 0.8 : DS.spacingXs;
  double get spacingS => isPhone ? DS.spacingS * 0.9 : DS.spacingS;
  double get spacingM => isPhone ? DS.spacingM * 0.9 : DS.spacingM;
  double get spacingL => isPhone ? DS.spacingL * 0.9 : DS.spacingL;
  double get spacingXl => isPhone ? DS.spacingXl * 0.9 : DS.spacingXl;
  double get spacing2xl => isPhone ? DS.spacing2xl * 0.9 : DS.spacing2xl;
  double get spacing3xl => isPhone ? DS.spacing3xl * 0.9 : DS.spacing3xl;
  
  /// Helper for responsive padding (useful for container padding)
  EdgeInsets get responsivePadding => EdgeInsets.all(
    isPhone ? DS.spacingS : (isTablet ? DS.spacingM : DS.spacingL)
  );
  
  /// Helper for grid spacing (useful for GridView spacing)
  double get gridSpacing => isPhone ? DS.spacingM : (isTablet ? DS.spacingL : DS.spacingXl);
}
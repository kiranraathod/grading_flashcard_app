import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_flashcard_app/utils/theme_provider.dart';
import 'package:flutter_flashcard_app/utils/app_themes.dart';
import 'package:flutter_flashcard_app/utils/colors.dart';
import 'package:flutter_flashcard_app/utils/theme_utils.dart';

/// Utilities for testing theme functionality across the FlashMaster app
class ThemeTestUtils {
  ThemeTestUtils._();

  /// Creates a test widget with proper theme provider setup
  /// This is the standard pattern for all theme-related widget tests
  static Widget createThemeTestWidget({
    required Widget child,
    ThemeMode initialThemeMode = ThemeMode.light,
    bool includeLocalizations = true,
  }) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..setThemeMode(initialThemeMode),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          Widget app = MaterialApp(
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Scaffold(body: child),
            debugShowCheckedModeBanner: false,
          );

          if (includeLocalizations) {
            app = MaterialApp(
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeProvider.themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: child),
              debugShowCheckedModeBanner: false,
            );
          }

          return app;
        },
      ),
    );
  }

  /// Creates a minimal test widget for performance testing
  static Widget createMinimalThemeTestWidget({
    required Widget child,
    ThemeMode initialThemeMode = ThemeMode.light,
  }) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..setThemeMode(initialThemeMode),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: child,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  /// Switches to light theme and waits for completion
  static Future<void> switchToLightTheme(WidgetTester tester) async {
    final themeProvider = tester
        .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
        .read<ThemeProvider>();
    
    themeProvider.setThemeMode(ThemeMode.light);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Switches to dark theme and waits for completion
  static Future<void> switchToDarkTheme(WidgetTester tester) async {
    final themeProvider = tester
        .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
        .read<ThemeProvider>();
    
    themeProvider.setThemeMode(ThemeMode.dark);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Toggles theme and waits for completion
  static Future<void> toggleTheme(WidgetTester tester) async {
    final themeProvider = tester
        .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
        .read<ThemeProvider>();
    
    themeProvider.toggleTheme();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Switches to system theme and waits for completion
  static Future<void> switchToSystemTheme(WidgetTester tester) async {
    final themeProvider = tester
        .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
        .read<ThemeProvider>();
    
    themeProvider.setThemeMode(ThemeMode.system);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Gets the current theme provider from the widget tree
  static ThemeProvider getThemeProvider(WidgetTester tester) {
    return tester
        .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
        .read<ThemeProvider>();
  }

  /// Verifies theme colors and properties match expected theme mode
  static void expectThemeColors(
    BuildContext context,
    bool shouldBeDarkMode, {
    String? debugMessage,
  }) {
    final message = debugMessage ?? 'Theme color verification';
    
    // Verify isDarkMode property
    expect(
      context.isDarkMode,
      shouldBeDarkMode,
      reason: '$message: isDarkMode property mismatch',
    );

    // Verify primary colors
    final expectedPrimary = shouldBeDarkMode 
        ? AppColors.primaryDark 
        : AppColors.primary;
    expect(
      context.primaryColor,
      expectedPrimary,
      reason: '$message: Primary color mismatch',
    );

    // Verify background colors
    final expectedBackground = shouldBeDarkMode 
        ? AppColors.backgroundDark 
        : AppColors.background;
    expect(
      context.theme.scaffoldBackgroundColor,
      expectedBackground,
      reason: '$message: Background color mismatch',
    );

    // Verify surface colors
    final expectedSurface = shouldBeDarkMode 
        ? AppColors.surfaceDark 
        : AppColors.surfaceLight;
    expect(
      context.surfaceColor,
      expectedSurface,
      reason: '$message: Surface color mismatch',
    );
  }

  /// Measures theme switch performance
  static Future<Duration> measureThemeSwitchTime(
    WidgetTester tester,
  ) async {
    final stopwatch = Stopwatch()..start();
    await toggleTheme(tester);
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Performance test for theme switching
  static Future<void> expectPerformantThemeSwitch(
    WidgetTester tester, {
    Duration maxDuration = const Duration(milliseconds: 200),
    String? debugMessage,
  }) async {
    final message = debugMessage ?? 'Theme switch performance test';
    final duration = await measureThemeSwitchTime(tester);
    expect(
      duration,
      lessThan(maxDuration),
      reason: '$message: Theme switch took ${duration.inMilliseconds}ms, expected less than ${maxDuration.inMilliseconds}ms',
    );
  }

  /// Common test sizes for responsive theme testing
  static const List<Size> testSizes = [
    Size(360, 640),   // Phone portrait
    Size(640, 360),   // Phone landscape
    Size(768, 1024),  // Tablet portrait
    Size(1024, 768),  // Tablet landscape
    Size(1200, 800),  // Desktop small
    Size(1920, 1080), // Desktop large
  ];

  /// Standard accessibility text scales for testing
  static const List<double> accessibilityTextScales = [
    1.0, 1.15, 1.3, 1.5, 2.0
  ];

  /// Verifies no visual overflow in theme
  static void expectNoOverflow(WidgetTester tester, {String? debugMessage}) {
    final message = debugMessage ?? 'No overflow verification';
    expect(
      tester.takeException(),
      isNull,
      reason: '$message: Visual overflow detected',
    );
  }

  /// Helper to find theme provider in widget tree
  static ThemeProvider? findThemeProvider(WidgetTester tester) {
    try {
      return tester
          .element(find.byType(ChangeNotifierProvider<ThemeProvider>))
          .read<ThemeProvider>();
    } catch (e) {
      return null;
    }
  }
}

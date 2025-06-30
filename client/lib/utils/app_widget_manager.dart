import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Screen imports
import '../screens/home_screen.dart';
import '../screens/job_description_question_generator_screen.dart';
import '../screens/data_validation_screen.dart';

// Theme imports
import '../utils/app_themes.dart';

/// Centralized widget configuration for clean main.dart architecture
/// 
/// This class handles all complex widget tree setup that was previously
/// embedded in main.dart, reducing complexity by ~80 lines
class AppWidgetManager {

  /// Create the main MaterialApp with theme and localization configuration
  static Widget createMainApp({
    required Widget child,
  }) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        debugPrint('🎨 Setting up app themes...');
        
        // Configure theme data with dynamic colors if available
        final themeData = _createThemeData(lightDynamic, darkDynamic);
        
        return MaterialApp(
          title: 'FlashMaster',
          theme: themeData.light,
          darkTheme: themeData.dark,
          themeMode: ThemeMode.system, // Will be overridden by ThemeProvider
          themeAnimationDuration: Duration.zero, // Disable theme animation to prevent lag
          
          // App structure
          home: const HomeScreen(),
          routes: _createRoutes(),
          
          // Configuration
          debugShowCheckedModeBanner: false,
          
          // Localization configuration
          locale: const Locale('en'),
          localizationsDelegates: _createLocalizationDelegates(),
          supportedLocales: const [Locale('en')],
        );
      },
    );
  }

  /// Create optimized route configuration
  static Map<String, WidgetBuilder> _createRoutes() {
    return {
      '/job-description-generator': (context) => 
          const JobDescriptionQuestionGeneratorScreen(),
      '/data-validation': (context) => 
          const DataValidationScreen(),
    };
  }

  /// Create localization delegates list
  static List<LocalizationsDelegate> _createLocalizationDelegates() {
    return const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
  }

  /// Create theme data with dynamic color support
  static ({ThemeData light, ThemeData dark}) _createThemeData(
    ColorScheme? lightDynamic, 
    ColorScheme? darkDynamic,
  ) {
    ThemeData lightTheme;
    ThemeData darkTheme;

    if (lightDynamic != null && darkDynamic != null) {
      // Apply dynamic color scheme to theme
      lightTheme = AppThemes.lightTheme.copyWith(
        colorScheme: lightDynamic.harmonized(),
      );
      darkTheme = AppThemes.darkTheme.copyWith(
        colorScheme: darkDynamic.harmonized(),
      );
      debugPrint('✅ Using dynamic color themes');
    } else {
      // Use default themes if dynamic color is not available
      lightTheme = AppThemes.lightTheme;
      darkTheme = AppThemes.darkTheme;
      debugPrint('✅ Using default color themes');
    }

    return (light: lightTheme, dark: darkTheme);
  }
}

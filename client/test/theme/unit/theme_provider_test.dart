import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_flashcard_app/utils/theme_provider.dart';

void main() {
  group('ThemeProvider Unit Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    group('Initialization', () {
      testWidgets('initializes with light theme by default', (tester) async {
        expect(themeProvider.themeMode, ThemeMode.light);
        expect(themeProvider.isDarkMode, false);
      });

      testWidgets('loads saved theme preference', (tester) async {
        // Pre-populate shared preferences
        SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
        
        final provider = ThemeProvider();
        await tester.pumpAndSettle();
        
        expect(provider.themeMode, ThemeMode.dark);
        expect(provider.isDarkMode, true);
        
        provider.dispose();
      });

      testWidgets('handles invalid saved preference gracefully', (tester) async {
        SharedPreferences.setMockInitialValues({'themeMode': 'invalid'});
        
        final provider = ThemeProvider();
        await tester.pumpAndSettle();
        
        expect(provider.themeMode, ThemeMode.light);
        
        provider.dispose();
      });
    });

    group('Theme Mode Management', () {
      testWidgets('toggles from light to dark', (tester) async {
        expect(themeProvider.themeMode, ThemeMode.light);
        
        themeProvider.toggleTheme();
        await tester.pump();
        
        expect(themeProvider.themeMode, ThemeMode.dark);
        expect(themeProvider.isDarkMode, true);
      });

      testWidgets('toggles from dark to light', (tester) async {
        themeProvider.setThemeMode(ThemeMode.dark);
        await tester.pump();
        
        themeProvider.toggleTheme();
        await tester.pump();
        
        expect(themeProvider.themeMode, ThemeMode.light);
        expect(themeProvider.isDarkMode, false);
      });

      testWidgets('sets specific theme mode', (tester) async {
        themeProvider.setThemeMode(ThemeMode.system);
        await tester.pump();
        
        expect(themeProvider.themeMode, ThemeMode.system);
      });

      testWidgets('handles system theme correctly', (tester) async {
        themeProvider.setThemeMode(ThemeMode.system);
        await tester.pump();
        
        // System theme detection depends on platform, 
        // just verify it doesn't crash
        expect(themeProvider.themeMode, ThemeMode.system);
        expect(() => themeProvider.isDarkMode, returnsNormally);
      });
    });

    group('Callbacks', () {
      testWidgets('calls theme change callbacks', (tester) async {
        ThemeMode? oldMode;
        ThemeMode? newMode;
        
        themeProvider.addThemeChangeCallback((old, current) {
          oldMode = old;
          newMode = current;
        });
        
        themeProvider.toggleTheme();
        await tester.pump();
        
        expect(oldMode, ThemeMode.light);
        expect(newMode, ThemeMode.dark);
      });

      testWidgets('removes callbacks correctly', (tester) async {
        var callCount = 0;
        
        void callback(ThemeMode old, ThemeMode current) {
          callCount++;
        }
        
        themeProvider.addThemeChangeCallback(callback);
        themeProvider.toggleTheme();
        await tester.pump();
        expect(callCount, 1);
        
        themeProvider.removeThemeChangeCallback(callback);
        themeProvider.toggleTheme();
        await tester.pump();
        expect(callCount, 1); // Should not increment
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/theme_toggle.dart';
import 'package:flutter_flashcard_app/utils/theme_utils.dart';
import '../theme_test_utils.dart';

void main() {
  group('Theme Integration Tests', () {
    testWidgets('theme switching works end-to-end', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: const ThemeToggle(),
        ),
      );

      // Initially light theme
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      
      // Toggle to dark theme
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Verify theme changed
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      
      // Verify no overflow errors
      ThemeTestUtils.expectNoOverflow(tester);
    });

    testWidgets('theme colors are consistent', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: Builder(
            builder: (context) {
              // Test theme colors
              ThemeTestUtils.expectThemeColors(context, false);
              
              return Container(
                color: context.primaryColor,
                child: Text(
                  'Test',
                  style: TextStyle(color: context.onPrimaryColor),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      ThemeTestUtils.expectNoOverflow(tester);
    });

    testWidgets('theme persistence works', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: const ThemeToggle(),
        ),
      );

      // Toggle to dark theme
      await ThemeTestUtils.switchToDarkTheme(tester);
      
      final provider = ThemeTestUtils.getThemeProvider(tester);
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}

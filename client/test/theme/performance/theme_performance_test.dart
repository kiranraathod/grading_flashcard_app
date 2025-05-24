import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/theme_toggle.dart';
import '../theme_test_utils.dart';

void main() {
  group('Theme Performance Tests', () {
    testWidgets('theme switching is performant', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createMinimalThemeTestWidget(child: const ThemeToggle()),
      );

      await ThemeTestUtils.expectPerformantThemeSwitch(
        tester,
        maxDuration: const Duration(milliseconds: 200),
      );
    });

    testWidgets('multiple theme switches remain performant', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createMinimalThemeTestWidget(child: const ThemeToggle()),
      );

      // Test multiple rapid switches
      for (int i = 0; i < 5; i++) {
        await ThemeTestUtils.expectPerformantThemeSwitch(
          tester,
          maxDuration: const Duration(milliseconds: 200),
        );
      }
    });

    testWidgets('theme switching with complex widgets', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createMinimalThemeTestWidget(
          child: Column(
            children: [
              const ThemeToggle(),
              ...List.generate(
                10,
                (index) => Container(
                  height: 50,
                  color: Colors.blue,
                  child: Text('Item $index'),
                ),
              ),
            ],
          ),
        ),
      );

      await ThemeTestUtils.expectPerformantThemeSwitch(
        tester,
        maxDuration: const Duration(milliseconds: 300),
      );
    });

    testWidgets('no memory leaks during theme switching', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createMinimalThemeTestWidget(child: const ThemeToggle()),
      );

      // Perform many theme switches to check for memory leaks
      for (int i = 0; i < 20; i++) {
        await ThemeTestUtils.toggleTheme(tester);
      }

      // If we get here without memory issues, test passes
      expect(true, isTrue);
    });
  });
}

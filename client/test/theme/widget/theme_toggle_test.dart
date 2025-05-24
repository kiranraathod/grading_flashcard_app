import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/theme_toggle.dart';
import '../theme_test_utils.dart';

void main() {
  group('ThemeToggle Widget Tests', () {
    testWidgets('renders with light theme initially', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(child: const ThemeToggle()),
      );

      expect(find.byType(ThemeToggle), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('shows dark mode icon in dark theme', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: const ThemeToggle(),
          initialThemeMode: ThemeMode.dark,
        ),
      );

      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });

    testWidgets('toggles theme when tapped', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(child: const ThemeToggle()),
      );

      // Initially light theme
      expect(find.byIcon(Icons.light_mode), findsOneWidget);

      // Tap to switch to dark
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should now show dark mode icon
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });
  });
}

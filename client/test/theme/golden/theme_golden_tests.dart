import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/theme_toggle.dart';
import 'package:flutter_flashcard_app/widgets/flashcard_deck_card.dart';
import '../theme_test_utils.dart';

void main() {
  group('Theme Golden Tests', () {
    testWidgets('theme toggle light mode golden', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: const Center(child: ThemeToggle()),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('theme_toggle_light.png'),
      );
    });

    testWidgets('theme toggle dark mode golden', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: const Center(child: ThemeToggle()),
          initialThemeMode: ThemeMode.dark,
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('theme_toggle_dark.png'),
      );
    });

    testWidgets('flashcard component light mode golden', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: Center(
            child: SizedBox(
              width: 300,
              child: FlashcardDeckCard(
                title: 'Sample Deck',
                cardCount: 25,
                progressPercent: 75,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('flashcard_component_light.png'),
      );
    });

    testWidgets('flashcard component dark mode golden', (tester) async {
      await tester.pumpWidget(
        ThemeTestUtils.createThemeTestWidget(
          child: Center(
            child: SizedBox(
              width: 300,
              child: FlashcardDeckCard(
                title: 'Sample Deck',
                cardCount: 25,
                progressPercent: 75,
                onTap: () {},
              ),
            ),
          ),
          initialThemeMode: ThemeMode.dark,
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('flashcard_component_dark.png'),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/flashcard_deck_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'responsive_test_utils.dart';

void main() {
  group('Comprehensive Responsive Integration Tests', () {
    group('Multi-Size Widget Testing', () {
      testWidgets('FlashcardDeckCard works across all standard screen sizes', (tester) async {
        final testWidget = MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FlashcardDeckCard(
                title: 'Multi-Size Test Card',
                cardCount: 50,
                progressPercent: 60,
                onTap: () {},
              ),
            ),
          ),
        );

        await ResponsiveTestUtils.testAtMultipleSizes(
          tester,
          testWidget,
          ResponsiveTestUtils.standardScreenSizes,
          onSizeChange: (size) {
            debugPrint('Testing card at size: $size');
          },
        );
      });

      testWidgets('FlashcardDeckCard handles all accessibility text scales', (tester) async {
        await ResponsiveTestUtils.testWithTextScaling(
          tester,
          (textScale) => ResponsiveTestUtils.createScaledMediaQuery(
            textScale: textScale,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SizedBox(
                  width: 320,
                  child: FlashcardDeckCard(
                    title: 'Accessibility Test',
                    cardCount: 25,
                    progressPercent: 80,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
          ResponsiveTestUtils.accessibilityTextScales,
        );
      });

      testWidgets('combined size and text scale stress test', (tester) async {
        // Test extreme combinations
        const extremeCombinations = [
          (ResponsiveTestUtils.verySmall, 2.0),
          (ResponsiveTestUtils.phonePortrait, 1.5),
          (ResponsiveTestUtils.tabletLandscape, 1.3),
          (ResponsiveTestUtils.desktopLarge, 1.0),
        ];

        for (final (size, textScale) in extremeCombinations) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            ResponsiveTestUtils.createScaledMediaQuery(
              textScale: textScale,
              screenSize: size,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: SizedBox(
                    width: size.width * 0.8, // Use 80% of screen width
                    child: FlashcardDeckCard(
                      title: 'Extreme Test Case',
                      cardCount: 999,
                      progressPercent: 100,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, 
              reason: 'Failed at size $size with text scale $textScale');
        }
      });
    });
  });
}

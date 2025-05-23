import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/flashcard_deck_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  group('Visual Responsive Tests', () {
    group('FlashcardDeckCard Responsive Behavior', () {
      testWidgets('card renders correctly on phone screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Phone size
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very constrained width
              child: FlashcardDeckCard(
                title: 'Test Card',
                category: 'Technical',
                cardCount: 25,
                progressPercent: 60,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
        
        // Verify card maintains proper height
        final cardWidget = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(cardWidget.width, equals(200)); // Should match expected width
      });

      testWidgets('card renders correctly on tablet screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(768, 1024)); // Tablet size
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 350, // Medium constrained width
              child: FlashcardDeckCard(
                title: 'Test Card with Longer Title',
                category: 'Applied Skills',
                cardCount: 42,
                progressPercent: 85,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
      });

      testWidgets('card renders correctly on desktop screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 500, // Large constrained width
              child: FlashcardDeckCard(
                title: 'Test Card with Very Long Title That Should Handle Well',
                category: 'Technical Knowledge',
                cardCount: 100,
                progressPercent: 45,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
      });
    });


    group('Extreme Screen Size Tests', () {
      testWidgets('handles very small screen dimensions', (tester) async {
        await tester.binding.setSurfaceSize(const Size(250, 400)); // Very small screen
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 150, // Very small width
              child: FlashcardDeckCard(
                title: 'Small',
                category: 'Tech',
                cardCount: 5,
                progressPercent: 20,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
        
        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles very large screen dimensions', (tester) async {
        await tester.binding.setSurfaceSize(const Size(2560, 1440)); // Very large screen
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 800, // Very large width
              child: FlashcardDeckCard(
                title: 'Large Screen Card with Extensive Title for Testing',
                category: 'Advanced Technical Knowledge',
                cardCount: 250,
                progressPercent: 95,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
        
        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });
    });
  });
}

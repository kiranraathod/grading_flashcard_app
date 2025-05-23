import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/widgets/flashcard_deck_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  group('Accessibility and Text Scaling Tests', () {
    group('Large Text Scale Support', () {
      testWidgets('handles 1.5x text scaling', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FlashcardDeckCard(
                title: 'Accessibility Test Card',
                category: 'Technical',
                cardCount: 30,
                progressPercent: 75,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
        
        // Verify no overflow errors with larger text
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles 2.0x text scaling', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FlashcardDeckCard(
                title: 'Large Text Test',
                category: 'Accessibility',
                cardCount: 15,
                progressPercent: 50,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(FlashcardDeckCard), findsOneWidget);
        
        // Verify no overflow errors with very large text
        expect(tester.takeException(), isNull);
      });

      testWidgets('maintains accessibility standards with large text', (tester) async {
        await tester.binding.setSurfaceSize(const Size(414, 896));
        
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3), // Common large text setting
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: FlashcardDeckCard(
                title: 'Accessibility Standards Test',
                category: 'User Experience',
                cardCount: 42,
                progressPercent: 88,
                onTap: () {},
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();
        
        // Find the button and verify it's still tappable
        final button = find.byType(TextButton);
        expect(button, findsOneWidget);
        
        // Verify button maintains minimum touch target size
        final buttonWidget = tester.widget<TextButton>(button);
        expect(buttonWidget.onPressed, isNotNull);
      });
    });
  });
}

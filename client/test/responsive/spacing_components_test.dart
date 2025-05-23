import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/spacing_components.dart';
import 'package:flutter_flashcard_app/utils/design_system.dart';

void main() {
  group('Spacing Components Tests', () {
    group('DSSpacing Widgets', () {
      test('vertical spacing widgets have correct heights', () {
        expect((DSSpacing.verticalXS as SizedBox).height, equals(DS.spacing2xs));
        expect((DSSpacing.verticalS as SizedBox).height, equals(DS.spacingXs));
        expect((DSSpacing.verticalM as SizedBox).height, equals(DS.spacingS));
        expect((DSSpacing.verticalL as SizedBox).height, equals(DS.spacingM));
        expect((DSSpacing.verticalXL as SizedBox).height, equals(DS.spacingL));
        expect((DSSpacing.vertical2XL as SizedBox).height, equals(DS.spacingXl));
        expect((DSSpacing.vertical3XL as SizedBox).height, equals(DS.spacing2xl));
      });

      test('horizontal spacing widgets have correct widths', () {
        expect((DSSpacing.horizontalXS as SizedBox).width, equals(DS.spacing2xs));
        expect((DSSpacing.horizontalS as SizedBox).width, equals(DS.spacingXs));
        expect((DSSpacing.horizontalM as SizedBox).width, equals(DS.spacingS));
        expect((DSSpacing.horizontalL as SizedBox).width, equals(DS.spacingM));
        expect((DSSpacing.horizontalXL as SizedBox).width, equals(DS.spacingL));
        expect((DSSpacing.horizontal2XL as SizedBox).width, equals(DS.spacingXl));
        expect((DSSpacing.horizontal3XL as SizedBox).width, equals(DS.spacing2xl));
      });

      test('context-specific spacing has appropriate values', () {
        expect((DSSpacing.formElement as SizedBox).height, equals(DS.spacingM));
        expect((DSSpacing.cardElement as SizedBox).height, equals(DS.spacingS));
        expect((DSSpacing.screenSection as SizedBox).height, equals(DS.spacingL));
      });

      test('custom spacing methods work correctly', () {
        final customVertical = DSSpacing.vertical(20.0);
        final customHorizontal = DSSpacing.horizontal(30.0);
        
        expect(customVertical, isA<SizedBox>());
        expect((customVertical as SizedBox).height, equals(20.0));
        expect(customHorizontal, isA<SizedBox>());
        expect((customHorizontal as SizedBox).width, equals(30.0));
      });
    });

    group('DSPadding Values', () {
      test('all padding values are correct', () {
        expect(DSPadding.allXS, equals(const EdgeInsets.all(DS.spacing2xs)));
        expect(DSPadding.allS, equals(const EdgeInsets.all(DS.spacingXs)));
        expect(DSPadding.allM, equals(const EdgeInsets.all(DS.spacingS)));
        expect(DSPadding.allL, equals(const EdgeInsets.all(DS.spacingM)));
        expect(DSPadding.allXL, equals(const EdgeInsets.all(DS.spacingL)));
        expect(DSPadding.all2XL, equals(const EdgeInsets.all(DS.spacingXl)));
      });

      test('symmetric horizontal padding values are correct', () {
        expect(DSPadding.horizontalS, equals(const EdgeInsets.symmetric(horizontal: DS.spacingXs)));
        expect(DSPadding.horizontalM, equals(const EdgeInsets.symmetric(horizontal: DS.spacingS)));
        expect(DSPadding.horizontalL, equals(const EdgeInsets.symmetric(horizontal: DS.spacingM)));
        expect(DSPadding.horizontalXL, equals(const EdgeInsets.symmetric(horizontal: DS.spacingL)));
      });

      test('symmetric vertical padding values are correct', () {
        expect(DSPadding.verticalS, equals(const EdgeInsets.symmetric(vertical: DS.spacingXs)));
        expect(DSPadding.verticalM, equals(const EdgeInsets.symmetric(vertical: DS.spacingS)));
        expect(DSPadding.verticalL, equals(const EdgeInsets.symmetric(vertical: DS.spacingM)));
        expect(DSPadding.verticalXL, equals(const EdgeInsets.symmetric(vertical: DS.spacingL)));
      });

      test('context-specific padding values are correct', () {
        expect(DSPadding.page, equals(const EdgeInsets.all(DS.spacingL)));
        expect(DSPadding.card, equals(const EdgeInsets.all(DS.spacingM)));
        expect(DSPadding.cardCompact, equals(const EdgeInsets.all(DS.spacingS)));
        expect(DSPadding.button, equals(const EdgeInsets.symmetric(horizontal: DS.spacingM, vertical: DS.spacingS)));
        expect(DSPadding.buttonCompact, equals(const EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs)));
        expect(DSPadding.input, equals(const EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacingXs)));
        expect(DSPadding.listItem, equals(const EdgeInsets.symmetric(horizontal: DS.spacingM, vertical: DS.spacingS)));
      });
    });

    group('DSMargin Values', () {
      test('all margin values are correct', () {
        expect(DSMargin.allXS, equals(const EdgeInsets.all(DS.spacing2xs)));
        expect(DSMargin.allS, equals(const EdgeInsets.all(DS.spacingXs)));
        expect(DSMargin.allM, equals(const EdgeInsets.all(DS.spacingS)));
        expect(DSMargin.allL, equals(const EdgeInsets.all(DS.spacingM)));
        expect(DSMargin.allXL, equals(const EdgeInsets.all(DS.spacingL)));
      });

      test('directional bottom margin values are correct', () {
        expect(DSMargin.bottomXS, equals(const EdgeInsets.only(bottom: DS.spacing2xs)));
        expect(DSMargin.bottomS, equals(const EdgeInsets.only(bottom: DS.spacingXs)));
        expect(DSMargin.bottomM, equals(const EdgeInsets.only(bottom: DS.spacingS)));
        expect(DSMargin.bottomL, equals(const EdgeInsets.only(bottom: DS.spacingM)));
        expect(DSMargin.bottomXL, equals(const EdgeInsets.only(bottom: DS.spacingL)));
      });

      test('directional top margin values are correct', () {
        expect(DSMargin.topXS, equals(const EdgeInsets.only(top: DS.spacing2xs)));
        expect(DSMargin.topS, equals(const EdgeInsets.only(top: DS.spacingXs)));
        expect(DSMargin.topM, equals(const EdgeInsets.only(top: DS.spacingS)));
        expect(DSMargin.topL, equals(const EdgeInsets.only(top: DS.spacingM)));
        expect(DSMargin.topXL, equals(const EdgeInsets.only(top: DS.spacingL)));
      });

      test('context-specific margin values are correct', () {
        expect(DSMargin.card, equals(const EdgeInsets.only(bottom: DS.spacingM)));
        expect(DSMargin.formElement, equals(const EdgeInsets.only(bottom: DS.spacingS)));
        expect(DSMargin.section, equals(const EdgeInsets.only(bottom: DS.spacingL)));
      });
    });
  });
}

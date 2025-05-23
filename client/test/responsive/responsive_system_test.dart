import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/design_system.dart';

void main() {
  group('Responsive System Tests', () {
    group('Design System Breakpoints', () {
      test('breakpoint constants are correctly defined', () {
        expect(DS.breakpointXs, equals(360.0));
        expect(DS.breakpointSm, equals(640.0));
        expect(DS.breakpointMd, equals(768.0));
        expect(DS.breakpointLg, equals(1024.0));
        expect(DS.breakpointXl, equals(1280.0));
        expect(DS.breakpoint2xl, equals(1536.0));
      });

      test('breakpoints are in ascending order', () {
        expect(DS.breakpointXs < DS.breakpointSm, isTrue);
        expect(DS.breakpointSm < DS.breakpointMd, isTrue);
        expect(DS.breakpointMd < DS.breakpointLg, isTrue);
        expect(DS.breakpointLg < DS.breakpointXl, isTrue);
        expect(DS.breakpointXl < DS.breakpoint2xl, isTrue);
      });

      test('card grid breakpoints are correctly defined', () {
        expect(DS.cardBreakpoint1Col, equals(0.0));
        expect(DS.cardBreakpoint2Col, equals(320.0));
        expect(DS.cardBreakpoint3Col, equals(500.0));
        expect(DS.cardBreakpoint4Col, equals(700.0));
        expect(DS.cardBreakpoint5Col, equals(900.0));
      });

      test('content width breakpoints are correctly defined', () {
        expect(DS.contentMaxWidthSm, equals(540.0));
        expect(DS.contentMaxWidthMd, equals(720.0));
        expect(DS.contentMaxWidthLg, equals(960.0));
        expect(DS.contentMaxWidthXl, equals(1140.0));
        expect(DS.contentMaxWidth2xl, equals(1320.0));
      });
    });

    group('Card Column Count Logic', () {
      test('getCardColumnCount returns correct values for different widths', () {
        expect(DS.getCardColumnCount(300), equals(1)); // Below cardBreakpoint2Col
        expect(DS.getCardColumnCount(400), equals(2)); // Above cardBreakpoint2Col
        expect(DS.getCardColumnCount(600), equals(3)); // cardBreakpoint3Col
        expect(DS.getCardColumnCount(800), equals(4)); // cardBreakpoint4Col
        expect(DS.getCardColumnCount(1000), equals(5)); // cardBreakpoint5Col
      });

      test('getCardColumnCount handles edge cases', () {
        expect(DS.getCardColumnCount(0), equals(1));
        expect(DS.getCardColumnCount(DS.cardBreakpoint2Col), equals(2));
        expect(DS.getCardColumnCount(DS.cardBreakpoint3Col), equals(3));
        expect(DS.getCardColumnCount(DS.cardBreakpoint4Col), equals(4));
        expect(DS.getCardColumnCount(DS.cardBreakpoint5Col), equals(5));
      });
    });

    group('Spacing Constants', () {
      test('spacing values follow 4px increment pattern', () {
        expect(DS.spacing2xs, equals(4.0));
        expect(DS.spacingXs, equals(8.0));
        expect(DS.spacingS, equals(12.0));
        expect(DS.spacingM, equals(16.0));
        expect(DS.spacingL, equals(24.0));
        expect(DS.spacingXl, equals(32.0));
        expect(DS.spacing2xl, equals(48.0));
        expect(DS.spacing3xl, equals(64.0));
      });

      test('spacing values are in ascending order', () {
        expect(DS.spacing2xs < DS.spacingXs, isTrue);
        expect(DS.spacingXs < DS.spacingS, isTrue);
        expect(DS.spacingS < DS.spacingM, isTrue);
        expect(DS.spacingM < DS.spacingL, isTrue);
        expect(DS.spacingL < DS.spacingXl, isTrue);
        expect(DS.spacingXl < DS.spacing2xl, isTrue);
        expect(DS.spacing2xl < DS.spacing3xl, isTrue);
      });
    });

    group('Component Sizes', () {
      test('button heights are consistent', () {
        expect(DS.buttonHeightS, equals(32.0));
        expect(DS.buttonHeightM, equals(40.0));
        expect(DS.buttonHeightL, equals(48.0));
        expect(DS.buttonHeightXl, equals(56.0));
      });

      test('icon sizes are consistent', () {
        expect(DS.iconSizeXs, equals(16.0));
        expect(DS.iconSizeS, equals(20.0));
        expect(DS.iconSizeM, equals(24.0));
        expect(DS.iconSizeL, equals(32.0));
        expect(DS.iconSizeXl, equals(40.0));
        expect(DS.iconSize2xl, equals(48.0));
      });

      test('avatar sizes are appropriate', () {
        expect(DS.avatarSizeXs, equals(24.0));
        expect(DS.avatarSizeS, equals(32.0));
        expect(DS.avatarSizeM, equals(40.0));
        expect(DS.avatarSizeL, equals(56.0));
        expect(DS.avatarSizeXl, equals(72.0));
        expect(DS.avatarSize2xl, equals(96.0));
      });

      test('card heights are defined', () {
        expect(DS.cardHeight, equals(201.0));
        expect(DS.cardHeightCompact, equals(160.0));
        expect(DS.cardHeightCompact < DS.cardHeight, isTrue);
      });
    });

    group('Border Radius Values', () {
      test('border radius values are consistent', () {
        expect(DS.borderRadiusXs, equals(4.0));
        expect(DS.borderRadiusSmall, equals(8.0));
        expect(DS.borderRadiusMedium, equals(12.0));
        expect(DS.borderRadiusLarge, equals(16.0));
        expect(DS.borderRadiusXlarge, equals(24.0));
        expect(DS.borderRadiusFull, equals(1000.0));
      });

      test('border radius values are in ascending order (except full)', () {
        expect(DS.borderRadiusXs < DS.borderRadiusSmall, isTrue);
        expect(DS.borderRadiusSmall < DS.borderRadiusMedium, isTrue);
        expect(DS.borderRadiusMedium < DS.borderRadiusLarge, isTrue);
        expect(DS.borderRadiusLarge < DS.borderRadiusXlarge, isTrue);
        expect(DS.borderRadiusXlarge < DS.borderRadiusFull, isTrue);
      });
    });

    group('Elevation Values', () {
      test('elevation values are correctly defined', () {
        expect(DS.elevationNone, equals(0.0));
        expect(DS.elevationXs, equals(1.0));
        expect(DS.elevationS, equals(2.0));
        expect(DS.elevationM, equals(4.0));
        expect(DS.elevationL, equals(8.0));
        expect(DS.elevationXl, equals(16.0));
        expect(DS.elevationNavigation, equals(3.0));
      });

      test('elevation values are in ascending order', () {
        expect(DS.elevationNone < DS.elevationXs, isTrue);
        expect(DS.elevationXs < DS.elevationS, isTrue);
        expect(DS.elevationS < DS.elevationM, isTrue);
        expect(DS.elevationM < DS.elevationL, isTrue);
        expect(DS.elevationL < DS.elevationXl, isTrue);
      });

      test('getShadow returns appropriate shadow lists', () {
        expect(DS.getShadow(DS.elevationNone), isEmpty);
        expect(DS.getShadow(DS.elevationXs), hasLength(1));
        expect(DS.getShadow(DS.elevationS), hasLength(1));
        expect(DS.getShadow(DS.elevationM), hasLength(2));
        expect(DS.getShadow(DS.elevationL), hasLength(2));
        expect(DS.getShadow(DS.elevationXl), hasLength(2));
      });
    });

    group('Typography Styles', () {
      test('typography styles are defined with correct properties', () {
        expect(DS.headingLarge.fontSize, equals(24.0));
        expect(DS.headingMedium.fontSize, equals(20.0));
        expect(DS.headingSmall.fontSize, equals(18.0));
        expect(DS.bodyLarge.fontSize, equals(16.0));
        expect(DS.bodyMedium.fontSize, equals(14.0));
        expect(DS.bodySmall.fontSize, equals(12.0));
        expect(DS.badgeText.fontSize, equals(12.0));
      });

      test('typography sizes are in logical order', () {
        expect(DS.headingLarge.fontSize! > DS.headingMedium.fontSize!, isTrue);
        expect(DS.headingMedium.fontSize! > DS.headingSmall.fontSize!, isTrue);
        expect(DS.bodyLarge.fontSize! > DS.bodyMedium.fontSize!, isTrue);
        expect(DS.bodyMedium.fontSize! > DS.bodySmall.fontSize!, isTrue);
      });
    });
  });
}

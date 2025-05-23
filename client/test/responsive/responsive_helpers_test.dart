import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/responsive_helpers.dart';

void main() {
  group('Responsive Helpers Tests', () {
    group('DeviceType Detection', () {
      testWidgets('getDeviceType correctly identifies phones', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Phone size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelpers.getDeviceType(context);
              expect(deviceType, equals(DeviceType.phone));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getDeviceType correctly identifies tablets', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1024)); // Tablet size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelpers.getDeviceType(context);
              expect(deviceType, equals(DeviceType.tablet));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getDeviceType correctly identifies desktops', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelpers.getDeviceType(context);
              expect(deviceType, equals(DeviceType.desktop));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getDeviceType correctly identifies TV', (tester) async {
        await tester.binding.setSurfaceSize(const Size(2000, 1200)); // TV size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelpers.getDeviceType(context);
              expect(deviceType, equals(DeviceType.tv));
              return const Scaffold();
            },
          ),
        ));
      });
    });

    group('ScreenSizeCategory Detection', () {
      testWidgets('getScreenSizeCategory correctly identifies xs screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568)); // XS size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.xs));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getScreenSizeCategory correctly identifies sm screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(500, 800)); // SM size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.sm));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getScreenSizeCategory correctly identifies md screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(750, 1024)); // MD size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.md));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getScreenSizeCategory correctly identifies lg screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1100, 800)); // LG size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.lg));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getScreenSizeCategory correctly identifies xl screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900)); // XL size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.xl));
              return const Scaffold();
            },
          ),
        ));
      });

      testWidgets('getScreenSizeCategory correctly identifies xxl screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1200)); // XXL size
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              final category = ResponsiveHelpers.getScreenSizeCategory(context);
              expect(category, equals(ScreenSizeCategory.xxl));
              return const Scaffold();
            },
          ),
        ));
      });
    });

    group('Grid Column Count Logic', () {
      testWidgets('getGridColumnCount returns appropriate column counts', (tester) async {
        // Test phone layout
        await tester.binding.setSurfaceSize(const Size(360, 640));
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelpers.getGridColumnCount(context), equals(1));
              return const Scaffold();
            },
          ),
        ));

        // Test tablet layout
        await tester.binding.setSurfaceSize(const Size(800, 1024));
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelpers.getGridColumnCount(context), equals(2));
              return const Scaffold();
            },
          ),
        ));

        // Test desktop layout
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelpers.getGridColumnCount(context), equals(3));
              return const Scaffold();
            },
          ),
        ));

        // Test extra large layout
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelpers.getGridColumnCount(context), equals(4));
              return const Scaffold();
            },
          ),
        ));
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_button.dart';

void main() {
  group('CustomIconButton Widget Tests', () {
    testWidgets('CustomIconButton renders with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.delete,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomIconButton), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('CustomIconButton executes onPressed callback',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.edit,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('CustomIconButton is disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.close,
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('CustomIconButton applies custom size',
        (WidgetTester tester) async {
      const customSize = 32.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.favorite,
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.size, equals(customSize));
    });

    testWidgets('CustomIconButton applies default size when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.play_arrow,
              onPressed: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.play_arrow));
      expect(icon.size, equals(24.0));
    });

    testWidgets('CustomIconButton applies custom color',
        (WidgetTester tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.check_circle,
              onPressed: () {},
              color: customColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CustomIconButton), findsOneWidget);
    });

    testWidgets('CustomIconButton renders with tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.save,
              onPressed: () {},
              tooltip: 'Save changes',
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byTooltip('Save changes'), findsOneWidget);
    });

    testWidgets(
        'CustomIconButton without tooltip does not wrap in Tooltip widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.delete,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('CustomIconButton shows tooltip on hover',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.info,
              onPressed: () {},
              tooltip: 'Information',
            ),
          ),
        ),
      );

      final tooltipFinder = find.byTooltip('Information');
      expect(tooltipFinder, findsOneWidget);
    });

    testWidgets('CustomIconButton with all properties configured',
        (WidgetTester tester) async {
      bool wasPressed = false;
      const customSize = 28.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.settings,
              onPressed: () {
                wasPressed = true;
              },
              tooltip: 'Settings',
              color: Colors.blue,
              size: customSize,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.settings));
      expect(icon.size, equals(customSize));

      await tester.tap(find.byType(IconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('CustomIconButton handles rapid taps',
        (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.add,
              onPressed: () {
                tapCount++;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));

      expect(tapCount, equals(3));
    });

    testWidgets('CustomIconButton with different icon types',
        (WidgetTester tester) async {
      const icons = [
        Icons.home,
        Icons.search,
        Icons.person,
        Icons.more_vert,
      ];

      for (final icon in icons) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconButton(
                icon: icon,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(icon), findsOneWidget);
      }
    });
  });
}

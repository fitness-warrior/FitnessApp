import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_button.dart';

void main() {
  group('TertiaryButton Widget Tests', () {
    testWidgets('TertiaryButton renders with text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Skip',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TertiaryButton), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('TertiaryButton executes onPressed callback',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Press',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('TertiaryButton is disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('TertiaryButton renders with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Help',
              onPressed: () {},
              icon: Icons.help,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
    });

    testWidgets('TertiaryButton without icon renders as simple TextButton',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Simple',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Simple'), findsOneWidget);
    });

    testWidgets('TertiaryButton with icon renders as TextButton.icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'With Icon',
              onPressed: () {},
              icon: Icons.info,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('TertiaryButton with all properties',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              text: 'Complete',
              onPressed: () {
                wasPressed = true;
              },
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      await tester.tap(find.text('Complete'));
      expect(wasPressed, isTrue);
    });
  });
}

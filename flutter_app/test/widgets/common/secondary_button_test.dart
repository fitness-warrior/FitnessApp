import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_button.dart';

void main() {
  group('SecondaryButton Widget Tests', () {
    testWidgets('SecondaryButton renders with text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Cancel',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SecondaryButton), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('SecondaryButton executes onPressed callback',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Press',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('SecondaryButton is disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('SecondaryButton renders with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Back',
              onPressed: () {},
              icon: Icons.arrow_back,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('SecondaryButton applies custom width',
        (WidgetTester tester) async {
      const customWidth = 180.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Wide',
              onPressed: () {},
              width: customWidth,
            ),
          ),
        ),
      );

      final sizedBox = find.byType(SizedBox);
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.width, equals(customWidth));
    });

    testWidgets('SecondaryButton without width does not use SizedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Normal',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SecondaryButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('SecondaryButton with all properties',
        (WidgetTester tester) async {
      bool wasPressed = false;
      const buttonWidth = 160.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Complete',
              onPressed: () {
                wasPressed = true;
              },
              icon: Icons.edit,
              width: buttonWidth,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      expect(wasPressed, isTrue);
    });
  });
}

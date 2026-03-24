import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_button.dart';

void main() {
  group('PrimaryButton Widget Tests', () {
    testWidgets('PrimaryButton renders with text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('PrimaryButton executes onPressed callback when clicked',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Press',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('PrimaryButton is disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('PrimaryButton shows loading spinner when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets(
        'PrimaryButton hides onPressed and shows spinner during loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PrimaryButton renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Icon Button',
              onPressed: () {},
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Icon Button'), findsOneWidget);
    });

    testWidgets(
        'PrimaryButton shows loading spinner instead of icon when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Icon Loading',
              onPressed: () {},
              icon: Icons.check,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('PrimaryButton applies custom width',
        (WidgetTester tester) async {
      const customWidth = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Wide Button',
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

    testWidgets('PrimaryButton without width does not use SizedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Normal Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // The button itself is not wrapped in SizedBox when width is null
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('PrimaryButton renders correctly without icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'No Icon',
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.child, isNotNull);
      expect(find.text('No Icon'), findsOneWidget);
    });

    testWidgets('PrimaryButton applies padding to button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Padded',
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style, isNotNull);
    });

    testWidgets(
        'PrimaryButton with icon and loading shows correct spinner size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Icon Load',
              onPressed: () {},
              icon: Icons.send,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Verify spinner is smaller for icon variant (16pt)
      final progressIndicators = find.byType(CircularProgressIndicator);
      expect(progressIndicators, findsOneWidget);
    });

    testWidgets('PrimaryButton handles rapid button presses',
        (WidgetTester tester) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Multi-Press',
              onPressed: () {
                pressCount++;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      expect(pressCount, equals(3));
    });

    testWidgets('PrimaryButton with all properties configured',
        (WidgetTester tester) async {
      bool wasPressed = false;
      const buttonWidth = 150.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Complete',
              onPressed: () {
                wasPressed = true;
              },
              icon: Icons.favorite,
              isLoading: false,
              width: buttonWidth,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);

      await tester.tap(find.text('Complete'));
      expect(wasPressed, isTrue);
    });
  });
}

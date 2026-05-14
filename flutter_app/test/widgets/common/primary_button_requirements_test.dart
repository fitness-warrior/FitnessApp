import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_button.dart';

void main() {
  group('PrimaryButton Requirement Tests', () {
    
    testWidgets('Requirement 1: Button renders with label text', (WidgetTester tester) async {
      // PrimaryButton rendered with text 'Save Workout'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Save Workout',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Button Displays text Save Workout
      expect(find.text('Save Workout'), findsOneWidget);
    });

    testWidgets('Requirement 2: Button shows loading spinner when loading', (WidgetTester tester) async {
      // PrimaryButton rendered with isLoading: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Save Workout',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Loading spinner is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button text isn't visible
      expect(find.text('Save Workout'), findsNothing);
    });

    testWidgets('Requirement 3: onPressed callback fires on tap', (WidgetTester tester) async {
      int pressCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Tap Me',
              onPressed: () {
                pressCount++;
              },
            ),
          ),
        ),
      );

      // Tapping the button should invoke the onPressed callback
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(pressCount, equals(1));
    });

    testWidgets('Requirement 4: Button disabled when loading', (WidgetTester tester) async {
      int pressCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Loading Tap',
              onPressed: () {
                pressCount++;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      // Loading button shouldn't be interactive
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(pressCount, equals(0));
    });
  });
}

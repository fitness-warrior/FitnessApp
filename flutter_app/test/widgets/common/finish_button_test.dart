import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/finish_button.dart';

void main() {
  group('FinishButton Tests', () {

    testWidgets('Test 1: Button renders with icon and label', (WidgetTester tester) async {
      // FinishButton rendered
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishButton(onPressed: () {}),
          ),
        ),
      );

      // Button shows 'Finish Workout' label
      expect(find.text('Finish Workout'), findsOneWidget);

      // Finish icon (check_circle_outline) is visible
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // Widget is present
      expect(find.byType(FinishButton), findsOneWidget);
    });

    testWidgets('Test 2: onPressed callback fires on tap', (WidgetTester tester) async {
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishButton(
              onPressed: () {
                callbackFired = true;
              },
            ),
          ),
        ),
      );

      // User taps the finish button via its label text
      await tester.tap(find.text('Finish Workout'));
      await tester.pump();

      // Callback invoked
      expect(callbackFired, isTrue);
    });

  });
}

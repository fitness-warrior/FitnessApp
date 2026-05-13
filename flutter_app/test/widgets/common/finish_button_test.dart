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

      // Button shows finish icon and 'Finish Workout' label
      expect(find.text('Finish Workout'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // Blue background — verify ElevatedButton exists
      expect(find.byType(ElevatedButton), findsOneWidget);
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

      // User taps the finish button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Callback invoked
      expect(callbackFired, isTrue);
    });

  });
}

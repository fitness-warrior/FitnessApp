// Covers:
//   WTC-021 - Button renders with check circle icon and Finish Workout label
//   WTC-022 - onPressed callback fires when button tapped

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/finish_button.dart';

void main() {
  group('FinishButton', () {
    // WTC-021
    testWidgets('renders with check circle icon and Finish Workout label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishButton(onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Finish Workout'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    // WTC-022
    testWidgets('fires onPressed callback when tapped',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.text('Finish Workout'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders with blue background colour',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishButton(onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!;
      final bgColor = style.backgroundColor?.resolve({});

      expect(bgColor, equals(Colors.blue));
    });
  });
}

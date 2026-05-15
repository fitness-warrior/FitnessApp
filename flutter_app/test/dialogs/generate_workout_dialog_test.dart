import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/dialogs/generate_workout_dialog.dart';

Widget buildDialog({
  required void Function(int, List<Map<String, dynamic>>, String, String)
      onGenerate,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: GenerateWorkoutDialog(onGenerate: onGenerate),
      ),
    ),
  );
}

void main() {
  group('GenerateWorkoutDialog Tests', () {
    testWidgets('renders muscle group and equipment options',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      expect(find.text('Target Muscle'), findsOneWidget);
      expect(find.text('Workout Type'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);

      // Muscle group chips
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Arms'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);

      // Equipment buttons
      expect(find.text('At Home'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
    });

    testWidgets('shows error when Generate pressed without muscle group',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
        called = true;
      }));

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.text('Select a muscle group'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('shows equipment error after selecting muscle group only',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
        called = true;
      }));

      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.text('Select equipment type'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('selected muscle and equipment stay visible after tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      await tester.tap(find.text('Back'));
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();

      final selectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Back').first);

      expect(selectedChip.selected, isTrue);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
    });
  });
}

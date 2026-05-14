import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/dialogs/finish_workout_dialog.dart';

// Helper to build a FinishWorkoutDialog with minimal valid data
Widget buildDialog({
  required List<Map<String, dynamic>> exercises,
  required Map<int, List<Map<String, TextEditingController>>> setControllers,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FinishWorkoutDialog(
          exercises: exercises,
          setControllers: setControllers,
          onSuccess: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('FinishWorkoutDialog Tests', () {

    testWidgets('Test 1: Dialog renders with exercise count', (WidgetTester tester) async {
      // FinishWorkoutDialog opened with 3 exercises
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Push-up',    'exer_type': 'strength'},
        {'exer_id': 2, 'exer_name': 'Squat',      'exer_type': 'strength'},
        {'exer_id': 3, 'exer_name': 'Pull-up',    'exer_type': 'strength'},
      ];

      final controllers = <int, List<Map<String, TextEditingController>>>{};

      await tester.pumpWidget(buildDialog(
        exercises: exercises,
        setControllers: controllers,
      ));

      // '3 exercises completed' shown
      expect(find.textContaining('3 exercises completed'), findsOneWidget);
    });

    testWidgets('Test 2: Exercise summary list renders correctly', (WidgetTester tester) async {
      // FinishWorkoutDialog with 2 exercises, each with 3 sets
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Bench Press', 'exer_type': 'strength'},
        {'exer_id': 2, 'exer_name': 'Deadlift',    'exer_type': 'strength'},
      ];

      // Build controllers for 3 sets per exercise with valid values
      Map<String, TextEditingController> makeSet(String kg, String reps) => {
        'kg':   TextEditingController(text: kg),
        'reps': TextEditingController(text: reps),
      };

      final controllers = <int, List<Map<String, TextEditingController>>>{
        0: [makeSet('60', '10'), makeSet('65', '8'), makeSet('70', '6')],
        1: [makeSet('100', '5'), makeSet('105', '4'), makeSet('110', '3')],
      };

      await tester.pumpWidget(buildDialog(
        exercises: exercises,
        setControllers: controllers,
      ));

      // Both exercise names visible in summary list
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Deadlift'),    findsOneWidget);
    });

    testWidgets('Test 3: Invalid data shows error message', (WidgetTester tester) async {
      // Exercise with an empty reps field
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Squat', 'exer_type': 'strength'},
      ];

      final controllers = <int, List<Map<String, TextEditingController>>>{
        0: [
          {
            'kg':   TextEditingController(text: '80'),
            'reps': TextEditingController(text: ''), // empty — invalid
          }
        ],
      };

      await tester.pumpWidget(buildDialog(
        exercises: exercises,
        setControllers: controllers,
      ));

      // Tap 'Finish & Save'
      await tester.tap(find.text('Finish & Save'));
      await tester.pump();

      // Error message shown
      expect(
        find.textContaining('Invalid values'),
        findsOneWidget,
      );
    });

    testWidgets('Test 4: Valid data opens save as routine confirmation dialog', (WidgetTester tester) async {
      // All fields valid
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Pull-up', 'exer_type': 'strength'},
      ];

      final controllers = <int, List<Map<String, TextEditingController>>>{
        0: [
          {
            'kg':   TextEditingController(text: '10'),
            'reps': TextEditingController(text: '8'),
          }
        ],
      };

      await tester.pumpWidget(buildDialog(
        exercises: exercises,
        setControllers: controllers,
      ));

      // Tap 'Finish & Save' with valid data
      await tester.tap(find.text('Finish & Save'));
      await tester.pumpAndSettle();

      // Dialog stating 'Save as Routine?' appears
      expect(find.text('Save as Routine?'), findsOneWidget);
      expect(find.text('No, just complete'), findsOneWidget);
      expect(find.text('Yes, save it'),      findsOneWidget);
    });

    testWidgets('Test 9: Cancel button closes the dialog', (WidgetTester tester) async {
      // FinishWorkoutDialog opens
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Squat', 'exer_type': 'strength'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FinishWorkoutDialog(
                      exercises: exercises,
                      setControllers: {},
                      onSuccess: (_) {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog is now visible
      expect(find.text('Finish Workout'), findsOneWidget);

      // User taps Cancel (the close X icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog closes without submission
      expect(find.text('Finish Workout'), findsNothing);
    });

  });
}

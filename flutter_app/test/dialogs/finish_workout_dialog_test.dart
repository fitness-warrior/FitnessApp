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

  });
}

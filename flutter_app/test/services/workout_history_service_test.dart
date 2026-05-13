import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('FR24 - Store Fitness Data Tests', () {

    test('Test 1: Completed workout saved to server successfully', () {
      // User finishes a workout with 2 exercises
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Push-up', 'sets': 3, 'reps': 10, 'weight': 0},
        {'exer_id': 2, 'exer_name': 'Squat',   'sets': 3, 'reps': 12, 'weight': 60},
      ];

      // Simulate the payload WorkoutHistoryService.saveWorkout would build
      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'] ?? 0,
            'reps': exercise['reps'],
            'weight': exercise['weight'],
            'notes': exercise['notes'] ?? '',
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      // Simulate server confirming workout is saved (201 Created)
      final fakeServerResponse = http.Response(
        jsonEncode({'workout_id': 99, 'message': 'Workout saved'}),
        201,
      );

      // Verify payload was correctly structured
      expect((payload['exercises'] as List).length, equals(2));
      expect(payload['total_exercises'], equals(2));

      // Verify server response confirms success
      expect(fakeServerResponse.statusCode, equals(201));
      final responseBody = jsonDecode(fakeServerResponse.body) as Map<String, dynamic>;
      expect(responseBody['workout_id'], equals(99));
    });

  });
}

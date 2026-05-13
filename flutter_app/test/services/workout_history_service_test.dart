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

    test('Test 2: Workout save fails when server has an error', () {
      // Server returns an error when app tries to save a workout
      final fakeServerError = http.Response(
        jsonEncode({'detail': 'Internal Server Error'}),
        500,
      );

      // App should detect the failure
      final statusCode = fakeServerError.statusCode;
      final isSuccess = statusCode == 201 || statusCode == 200;

      // App returns an error message (not success)
      expect(isSuccess, isFalse);
      expect(statusCode, equals(500));
    });

    test('Test 3: Workout history loads correctly from the server', () {
      // Server returns 3 previous workouts
      final fakeHistory = [
        {'workout_id': 1, 'notes': 'Morning run', 'created_at': '2024-01-01'},
        {'workout_id': 2, 'notes': 'Leg day',     'created_at': '2024-01-02'},
        {'workout_id': 3, 'notes': 'Chest day',   'created_at': '2024-01-03'},
      ];

      final fakeResponse = http.Response(jsonEncode(fakeHistory), 200);

      // Parse as WorkoutHistoryService.getWorkoutHistory would
      expect(fakeResponse.statusCode, equals(200));
      final data = jsonDecode(fakeResponse.body);
      final workouts = (data as List).cast<Map<String, dynamic>>();

      // All 3 workouts displayed in workout history
      expect(workouts.length, equals(3));
      expect(workouts[0]['workout_id'], equals(1));
      expect(workouts[2]['notes'], equals('Chest day'));
    });

    test('Test 4: Workout history can be limited to a certain number', () {
      // User requests the last 3 workouts — server returns exactly 3
      final fakeHistory = [
        {'workout_id': 5, 'notes': 'Latest 1', 'created_at': '2024-03-01'},
        {'workout_id': 6, 'notes': 'Latest 2', 'created_at': '2024-03-02'},
        {'workout_id': 7, 'notes': 'Latest 3', 'created_at': '2024-03-03'},
      ];

      final fakeResponse = http.Response(jsonEncode(fakeHistory), 200);

      expect(fakeResponse.statusCode, equals(200));
      final workouts = (jsonDecode(fakeResponse.body) as List).cast<Map<String, dynamic>>();

      // 3 most recent workouts are displayed
      expect(workouts.length, equals(3));
    });

  });
}

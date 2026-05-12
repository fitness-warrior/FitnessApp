// Covers:
//   UTC-014 - saveWorkout stores workout with correct name and date
//   UTC-015 - getWorkouts returns workouts newest first
//   UTC-016 - getWorkouts returns empty list when nothing saved
//   UTC-017 - deleteWorkout removes the correct workout
//   UTC-018 - saving a second workout appends to existing history
//   UTC-019 - clearAllCurrentWorkoutSessions removes session data

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/services/workout_storage.dart';

void main() {
  // Initialize Flutter bindings
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the flutter_secure_storage platform channel
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  // ignore: deprecated_member_use
  secureStorageChannel.setMockMethodCallHandler((call) async {
    return null; // Return null for all calls - simulates no stored user
  });

  setUp(() {
    // Mock SharedPreferences - start with empty data
    SharedPreferences.setMockInitialValues({});
  });

  final sampleExercises = [
    {
      'exer_id': 1,
      'exer_name': 'Bench Press',
      'exer_type': 'strength',
      'sets': [
        {'kg': '80', 'reps': '10'},
        {'kg': '80', 'reps': '10'},
      ],
    },
    {
      'exer_id': 2,
      'exer_name': 'Squat',
      'exer_type': 'strength',
      'sets': [
        {'kg': '100', 'reps': '8'},
      ],
    },
  ];

  group('WorkoutStorage - saveWorkout', () {
    // UTC-014
    test('saves workout with correct name and date', () async {
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Push Day',
      );

      final workouts = await WorkoutStorage.getWorkouts();

      expect(workouts.length, equals(1));
      expect(workouts.first['name'], equals('Push Day'));
      expect(workouts.first['date'], isNotNull);
      expect(workouts.first['exercises'], isNotNull);
    });

    // UTC-018
    test('saving a second workout appends to existing history', () async {
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Push Day',
      );
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Pull Day',
      );

      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, equals(2));
    });
  });

  group('WorkoutStorage - getWorkouts', () {
    // UTC-016
    test('returns empty list when no workouts saved', () async {
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts, isEmpty);
    });

    // UTC-015
    test('returns workouts newest first', () async {
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'First Workout',
      );
      await Future.delayed(const Duration(milliseconds: 100));
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Second Workout',
      );

      final workouts = await WorkoutStorage.getWorkouts();

      expect(workouts.length, equals(2));
      // Most recent should be first (reversed list)
      expect(workouts.first['name'], equals('Second Workout'));
      expect(workouts.last['name'], equals('First Workout'));
    });
  });

  group('WorkoutStorage - deleteWorkout', () {
    // UTC-017
    test('deletes the correct workout by index', () async {
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Workout A',
      );
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Workout B',
      );
      await WorkoutStorage.saveWorkout(
        sampleExercises,
        workoutName: 'Workout C',
      );

      var workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, equals(3));
      // Newest first: [C, B, A], so index 0 = C
      expect(workouts.first['name'], equals('Workout C'));

      // Delete index 0 (Workout C)
      await WorkoutStorage.deleteWorkout(0);

      workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, equals(2));
      expect(workouts.any((w) => w['name'] == 'Workout C'), isFalse);
      expect(workouts.any((w) => w['name'] == 'Workout B'), isTrue);
      expect(workouts.any((w) => w['name'] == 'Workout A'), isTrue);
    });
  });

  group('WorkoutStorage - clearAllCurrentWorkoutSessions', () {
    // UTC-019
    test('removes all in-progress session data', () async {
      // Save a session first
      final mockSets = <int, List<Map<String, dynamic>>>{
        0: [
          {'kg': '80', 'reps': '10'}
        ]
      };

      await WorkoutStorage.saveCurrentWorkoutSessions(
        [sampleExercises],
        [mockSets],
      );

      var sessions = await WorkoutStorage.loadCurrentWorkoutSessions();
      expect(sessions.isNotEmpty, isTrue);

      // Clear all sessions
      await WorkoutStorage.clearAllCurrentWorkoutSessions();

      sessions = await WorkoutStorage.loadCurrentWorkoutSessions();
      expect(sessions, isEmpty);
    });
  });
}

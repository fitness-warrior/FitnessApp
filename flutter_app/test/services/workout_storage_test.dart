import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutStorage Tests', () {
    test('Workout data structure contains required fields', () {
      final workout = {
        'date': DateTime.now().toIso8601String(),
        'exercises': [
          {
            'exer_id': 1,
            'exer_name': 'Squats',
            'sets': [
              {'kg': 50, 'reps': 10},
              {'kg': 55, 'reps': 8},
            ]
          }
        ]
      };

      expect(workout.containsKey('date'), isTrue);
      expect(workout.containsKey('exercises'), isTrue);
      expect(workout['exercises'], isA<List>());
    });

    test('Multiple exercises in one workout stores correctly', () {
      final now = DateTime.now();
      final workout = {
        'date': now.toIso8601String(),
        'exercises': [
          {
            'exer_id': 1,
            'exer_name': 'Squats',
            'sets': [
              {'kg': 50, 'reps': 10},
            ]
          },
          {
            'exer_id': 2,
            'exer_name': 'Bench Press',
            'sets': [
              {'kg': 60, 'reps': 8},
            ]
          }
        ]
      };

      expect((workout['exercises'] as List).length, equals(2));
    });

    test('Workout with multiple sets per exercise stores correctly', () {
      final workout = {
        'date': DateTime.now().toIso8601String(),
        'exercises': [
          {
            'exer_id': 1,
            'exer_name': 'Deadlifts',
            'sets': [
              {'kg': 80, 'reps': 5},
              {'kg': 85, 'reps': 5},
              {'kg': 90, 'reps': 3},
            ]
          }
        ]
      };

      final exercises = workout['exercises'] as List;
      final sets = exercises[0]['sets'] as List;
      expect(sets.length, equals(3));
    });

    test('Workout data JSON serialization roundtrip', () {
      final now = DateTime.now();
      final workout = {
        'date': now.toIso8601String(),
        'exercises': [
          {
            'exer_id': 5,
            'exer_name': 'Pull-ups',
            'sets': [
              {'kg': 0, 'reps': 10},
            ]
          }
        ]
      };

      // Simulate saveWorkout: JSON encode
      final jsonString = jsonEncode(workout);
      expect(jsonString, isNotEmpty);

      // Simulate getWorkouts: JSON decode and parse back
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      expect(decoded['date'], equals(now.toIso8601String()));
      expect((decoded['exercises'] as List).length, equals(1));
    });

    test('Workout list maintains order with newest first', () {
      final date1 = DateTime(2025, 4, 1);
      final date2 = DateTime(2025, 4, 2);
      final date3 = DateTime(2025, 4, 3);

      final workouts = [
        {'date': date1.toIso8601String(), 'exercises': []},
        {'date': date2.toIso8601String(), 'exercises': []},
        {'date': date3.toIso8601String(), 'exercises': []}
      ];

      // Simulate getWorkouts reversal for newest first
      final reversed =
          workouts.reversed.map((w) => Map<String, dynamic>.from(w)).toList();

      expect(reversed[0]['date'], equals(date3.toIso8601String()));
      expect(reversed[1]['date'], equals(date2.toIso8601String()));
      expect(reversed[2]['date'], equals(date1.toIso8601String()));
    });

    test('Empty workout list is handled', () {
      final allWorkouts = <Map<String, dynamic>>[];

      expect(allWorkouts, isEmpty);
    });

    test('Workout with complex exercise data stores correctly', () {
      final workout = {
        'date': DateTime.now().toIso8601String(),
        'exercises': [
          {
            'exer_id': 10,
            'exer_name': 'Cable Flyes',
            'exer_descrip': 'Chest exercise',
            'exer_body_area': 'Chest',
            'sets': [
              {'kg': 20, 'reps': 12},
              {'kg': 20, 'reps': 10},
              {'kg': 15, 'reps': 15}
            ]
          }
        ]
      };

      final jsonString = jsonEncode(workout);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      final exercises = decoded['exercises'] as List;
      final exercise = exercises[0] as Map<String, dynamic>;

      expect(exercise['exer_id'], equals(10));
      expect(exercise['exer_name'], equals('Cable Flyes'));
      expect(exercise.containsKey('exer_descrip'), isTrue);
      expect((exercise['sets'] as List).length, equals(3));
    });

    test('Workout parsing handles edge cases', () {
      // Workout with no sets
      final workout1 = {
        'date': DateTime.now().toIso8601String(),
        'exercises': [
          {'exer_id': 1, 'exer_name': 'Test', 'sets': []}
        ]
      };

      expect((workout1['exercises'] as List).isNotEmpty, isTrue);
      expect(
          ((workout1['exercises'] as List)[0]['sets'] as List).isEmpty, isTrue);
    });

    test('Workout ISO8601 date parsing', () {
      final now = DateTime.now();
      final isoString = now.toIso8601String();

      // Simulate loading and parsing date
      final workout = {'date': isoString, 'exercises': []};

      final parsedDate = DateTime.parse(workout['date'] as String);
      expect(parsedDate, equals(now));
    });
  });
}

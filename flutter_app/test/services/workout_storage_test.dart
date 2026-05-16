import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/services/workout_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutStorage Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });
    });

    test('saveWorkout stores workout with the date and exercises', () async {
      final exercises = [
        {'exer_name': 'Pushups', 'sets': [{'kg': '0', 'reps': '10'}]},
        {'exer_name': 'Squats', 'sets': [{'kg': '0', 'reps': '15'}]}
      ];
      
      await WorkoutStorage.saveWorkout(exercises, workoutName: 'Pull day');
      
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, 1);
      expect(workouts[0]['name'], 'Pull day');
      expect(workouts[0]['exercises'].length, 2);
      expect(workouts[0]['date'], isNotNull);
    });

    test('getWorkouts returns all saved workouts and appends correctly', () async {
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout 1');
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout 2');
      
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, 2);
      // getWorkouts returns reversed (newest first)
      expect(workouts[0]['name'], 'Workout 2');
      expect(workouts[1]['name'], 'Workout 1');
    });

    test('getWorkouts returns empty list if no workouts saved', () async {
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts, []);
    });

    test('deleteWorkout removes correct workout according to index', () async {
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout 1');
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout 2');
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout 3');
      
      // Reversed list is [Workout 3, Workout 2, Workout 1]
      // deleteWorkout(0) should remove Workout 3 (the newest)
      await WorkoutStorage.deleteWorkout(0);
      
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, 2);
      expect(workouts[0]['name'], 'Workout 2');
      expect(workouts[1]['name'], 'Workout 1');
    });

    test('clearAllCurrentWorkoutSessions removes session data', () async {
      const sessionKey = 'current_workout_sessions_list_anonymous';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionKey, 'some session data');
      
      await WorkoutStorage.clearAllCurrentWorkoutSessions();
      
      expect(prefs.getString(sessionKey), isNull);
    });

    test('saveCurrentWorkoutSessions and loadCurrentWorkoutSessions roundtrip', () async {
      final exercisesList = [
        [
          {'exer_name': 'Pushups', 'exer_id': 1}
        ]
      ];

      final setsList = [
        {
          0: [
            {'kg': 0, 'reps': 10},
            {'kg': '5', 'reps': '8'},
          ]
        }
      ];

      await WorkoutStorage.saveCurrentWorkoutSessions(exercisesList, setsList);

      final loaded = await WorkoutStorage.loadCurrentWorkoutSessions();
      expect(loaded.length, 1);
      expect(loaded[0]['exercises'][0]['exer_name'], 'Pushups');
      expect(loaded[0]['setControllers'], isA<Map>());
      final setControllers = Map<String, dynamic>.from(loaded[0]['setControllers']);
      expect(setControllers.containsKey('0'), isTrue);
      final savedSets = List<dynamic>.from(setControllers['0']);
      expect(savedSets[0]['kg'].toString(), '0');
      expect(savedSets[0]['reps'].toString(), '10');
      expect(savedSets[1]['kg'].toString(), '5');
    });

    test('loadCurrentWorkoutSessions migrates legacy single session key', () async {
      const legacyKey = 'current_workout_session';
      final prefs = await SharedPreferences.getInstance();
      final legacySession = {
        'exercises': [
          {'exer_name': 'Legacy', 'exer_id': 9}
        ],
        'setControllers': {}
      };
      await prefs.setString(legacyKey, jsonEncode(legacySession));

      final loaded = await WorkoutStorage.loadCurrentWorkoutSessions();
      expect(loaded.length, 1);
      expect(loaded[0]['exercises'][0]['exer_name'], 'Legacy');
      expect(prefs.getString(legacyKey), isNull);
    });

    test('saveWorkout trims workoutName', () async {
      await WorkoutStorage.saveWorkout([], workoutName: '  My Workout  ');
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts[0]['name'], 'My Workout');
    });

    test('deleteWorkout with invalid index does nothing', () async {
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout A');
      await WorkoutStorage.saveWorkout([], workoutName: 'Workout B');
      await WorkoutStorage.deleteWorkout(999);
      final workouts = await WorkoutStorage.getWorkouts();
      expect(workouts.length, 2);
    });

    test('loadCurrentWorkoutSessions returns empty list on corrupted JSON', () async {
      const sessionKey = 'current_workout_sessions_list_anonymous';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionKey, 'not-a-json');

      final loaded = await WorkoutStorage.loadCurrentWorkoutSessions();
      expect(loaded, []);
    });
  });
}

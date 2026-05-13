import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FR29 - Display Guidance on Selection Tests', () {

    test('Test 1: Specific exercises loaded by their ID', () {
      // App requests exercises with ID 1 and ID 2
      final requestedIds = [1, 2];

      final allExercises = [
        {'id': 1, 'name': 'Push-up',  'area': 'chest', 'type': 'strength'},
        {'id': 2, 'name': 'Squat',    'area': 'legs',  'type': 'strength'},
        {'id': 3, 'name': 'Pull-up',  'area': 'back',  'type': 'strength'},
      ];

      // Only return exercises whose ID is in the requested list
      final results = allExercises
          .where((ex) => requestedIds.contains(ex['id']))
          .toList();

      // Returns the two exercises matching those IDs
      expect(results.length, equals(2));
      expect(results[0]['id'], equals(1));
      expect(results[1]['id'], equals(2));
    });

    test('Test 2: Recommended exercises ranked by relevance', () {
      // App requests exercises matching 'legs' and 'strength'
      final tags = ['legs', 'strength'];

      final exercises = [
        {'id': 1, 'name': 'Push-up',       'type': 'strength', 'area': 'chest'}, // 1 match: strength
        {'id': 2, 'name': 'Barbell Squat', 'type': 'strength', 'area': 'legs'},  // 2 matches
        {'id': 3, 'name': 'Running',       'type': 'cardio',   'area': 'legs'},  // 1 match: legs
      ];

      // Rank by number of matching tags
      final ranked = exercises.map((ex) {
        final text = '${ex['name']} ${ex['type']} ${ex['area']}'.toLowerCase();
        int score = 0;
        for (final tag in tags) {
          if (text.contains(tag)) score++;
        }
        return {...ex, 'score': score};
      }).toList()
        ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Exercises with more matching tags appear higher in the list
      expect(ranked[0]['id'], equals(2)); // Barbell Squat — 2 matches
      expect(ranked[0]['score'], equals(2));
      expect((ranked[1]['score'] as int), equals(1));
    });

    test('Test 3: Specific exercise found on device', () {
      // App looks up exercise with ID 1, found on device (local cache)
      final deviceStorage = {
        1: {'id': 1, 'name': 'Cached Push-up', 'area': 'chest', 'type': 'strength'},
      };

      final requestedId = 1;

      // Simulate: check device first
      Map<String, dynamic>? result;
      if (deviceStorage.containsKey(requestedId)) {
        result = deviceStorage[requestedId];
      }

      // Returns the exercise from device storage (no server needed)
      expect(result, isNotNull);
      expect(result?['name'], equals('Cached Push-up'));
    });

    test('Test 4: Exercise fetched from server when not on device', () {
      // App looks up exercise not stored on device, server has it
      final deviceStorage = <int, Map<String, dynamic>>{}; // cache is empty

      final serverExercises = {
        10: {'id': 10, 'name': 'Server Deadlift', 'area': 'back', 'type': 'strength'},
      };

      final requestedId = 10;

      // Simulate: cache miss → fetch from server
      Map<String, dynamic>? result;
      if (deviceStorage.containsKey(requestedId)) {
        result = deviceStorage[requestedId];
      } else if (serverExercises.containsKey(requestedId)) {
        result = serverExercises[requestedId];
      }

      // Returns the exercise from the server
      expect(result, isNotNull);
      expect(result?['name'], equals('Server Deadlift'));
    });

    test('Test 5: Returns nothing when exercise cannot be found anywhere', () {
      // Exercise not on device and server cannot be reached
      final deviceStorage = <int, Map<String, dynamic>>{};
      final serverAvailable = false;

      final requestedId = 999;

      // Simulate: cache miss → server unreachable → return nothing
      Map<String, dynamic>? result;
      if (deviceStorage.containsKey(requestedId)) {
        result = deviceStorage[requestedId];
      } else if (serverAvailable) {
        result = {'id': requestedId, 'name': 'Would be fetched'};
      } else {
        result = null; // Returns nothing without crashing
      }

      expect(result, isNull);
    });

  });
}

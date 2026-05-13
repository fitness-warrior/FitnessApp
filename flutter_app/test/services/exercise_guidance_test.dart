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

  });
}

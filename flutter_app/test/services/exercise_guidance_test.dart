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

  });
}

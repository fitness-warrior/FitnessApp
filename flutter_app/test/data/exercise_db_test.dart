import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitness_app_flutter/data/exercise_db.dart';

void main() {
  group('ExerciseDb Tests', () {
    late ExerciseDb db;

    setUp(() {
      db = ExerciseDb.instance;
    });

    test('listExercises returns normalized list on success', () async {
      db.client = MockClient((request) async {
        expect(request.url.path, '/api/exercises');
        expect(request.url.queryParameters['area'], 'chest');
        
        final data = [
          {'id': 1, 'name': 'Bench Press', 'area': 'chest', 'equipment': ['barbell']}
        ];
        return http.Response(jsonEncode(data), 200);
      });

      final result = await db.listExercises(area: 'chest');
      
      expect(result.length, 1);
      expect(result[0]['exer_id'], 1);
      expect(result[0]['exer_name'], 'Bench Press');
      expect(result[0]['exer_equip'], 'barbell');
    });

    test('getExercise returns normalized exercise on success', () async {
      db.client = MockClient((request) async {
        expect(request.url.path, '/api/exercises/1');
        final data = {'id': 1, 'name': 'Squat', 'area': 'legs'};
        return http.Response(jsonEncode(data), 200);
      });

      final result = await db.getExercise(1);
      
      expect(result, isNotNull);
      expect(result!['exer_id'], 1);
      expect(result['exer_name'], 'Squat');
    });

    test('getExercise returns null on failure', () async {
      db.client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final result = await db.getExercise(999);
      expect(result, isNull);
    });

    test('searchExercises returns list on success', () async {
      db.client = MockClient((request) async {
        expect(request.url.path, '/api/exercises/search');
        expect(request.url.queryParameters['q'], 'push');
        return http.Response(jsonEncode([]), 200);
      });

      final result = await db.searchExercises('push');
      expect(result, []);
    });

    test('UTC-055: Exercise data mapped to correct field names from alternative sources', () async {
      db.client = MockClient((request) async {
        final data = [
          {
            'id': 10,
            'title': 'Dips',
            'body_area': 'triceps',
            'type': 'strength',
            'description': 'Description here',
            'video_url': 'http://vid.com',
            'equipment': 'Parallel Bars'
          },
          {
            'exer_id': 11,
            'exer_name': 'Pull-up',
            'exer_body_area': 'Back',
            'exer_type': 'strength',
            'exer_descrip': 'Back exercise',
            'exer_vid': 'http://pullup.com',
            'exer_equip': 'Bar'
          }
        ];
        return http.Response(jsonEncode(data), 200);
      });

      final result = await db.listExercises();
      
      // Verify first item mapping
      expect(result[0]['exer_id'], 10);
      expect(result[0]['exer_name'], 'Dips');
      expect(result[0]['exer_body_area'], 'triceps');
      expect(result[0]['exer_type'], 'strength');
      expect(result[0]['exer_descrip'], 'Description here');
      expect(result[0]['exer_vid'], 'http://vid.com');
      expect(result[0]['exer_equip'], 'Parallel Bars');
      
      // Verify second item mapping
      expect(result[1]['exer_id'], 11);
      expect(result[1]['exer_name'], 'Pull-up');
      expect(result[1]['exer_body_area'], 'Back');
    });

    test('UTC-056: Equipment list is formatted correctly from list to readable string', () async {
      db.client = MockClient((request) async {
        final data = [
          {
            'id': 1,
            'name': 'Bench Press',
            'equipment': ['Barbell', 'Dumbbell']
          }
        ];
        return http.Response(jsonEncode(data), 200);
      });

      final result = await db.listExercises();
      
      // Verify equipment list joined into readable string
      expect(result[0]['exer_equip'], 'Barbell, Dumbbell');
    });

    test('listExercises with all params and equipment', () async {
      db.client = MockClient((request) async {
        expect(request.url.queryParameters['name'], 'Bench');
        expect(request.url.queryParameters['type'], 'strength');
        expect(request.url.queryParameters['equipment'], 'dumbbells,bench');
        return http.Response(jsonEncode([]), 200);
      });

      await db.listExercises(
        name: 'Bench',
        type: 'strength',
        equipment: ['dumbbells', 'bench']
      );
    });

    test('listExercises returns empty list on non-200 status', () async {
      db.client = MockClient((request) async {
        return http.Response('Error', 500);
      });
      final result = await db.listExercises();
      expect(result, []);
    });

    test('searchExercises returns empty list on non-200 status', () async {
      db.client = MockClient((request) async {
        return http.Response('Error', 500);
      });
      final result = await db.searchExercises('q');
      expect(result, []);
    });

    test('Handles exceptions and returns empty list/null', () async {
      db.client = MockClient((request) async {
        throw Exception('Network Error');
      });

      expect(await db.listExercises(), []);
      expect(await db.getExercise(1), isNull);
      expect(await db.searchExercises('q'), []);
    });
  });
}

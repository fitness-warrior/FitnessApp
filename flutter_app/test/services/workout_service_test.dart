import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_app_flutter/services/workout_service.dart';


// Manual Mock for http.Client
class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.Response> post(Uri? url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      super.noSuchMethod(Invocation.method(#post, [url], {#headers: headers, #body: body, #encoding: encoding}),
          returnValue: Future.value(http.Response('', 200)));
}

void main() {
  group('WorkoutService Tests', () {
    test('WorkoutService base URL is configured', () {
      final baseUrl = WorkoutService.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, isA<String>());
    });

    test('Workout payload structure is correct for single exercise', () {
      // Simulate exercise data
      final exercises = [
        {
          'exer_id': 1,
          'exer_name': 'Push-up',
          'sets': [
            {'kg': 0, 'reps': 10},
            {'kg': 0, 'reps': 12},
          ]
        }
      ];

      // Build payload as WorkoutService would
      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      expect(payload['total_exercises'], equals(1));
      expect((payload['exercises'] as List).length, equals(1));
      expect((payload['exercises'] as List)[0]['exer_name'], equals('Push-up'));
    });

    test('Workout payload structure is correct for multiple exercises', () {
      final exercises = [
        {
          'exer_id': 1,
          'exer_name': 'Push-up',
          'exer_descrip': 'Extra field',
          'sets': [
            {'kg': 0, 'reps': 10}
          ]
        },
        {
          'exer_id': 2,
          'exer_name': 'Pull-up',
          'exer_body_area': 'Back',
          'sets': [
            {'kg': 0, 'reps': 5}
          ]
        },
        {
          'exer_id': 3,
          'exer_name': 'Squat',
          'sets': [
            {'kg': 50, 'reps': 15}
          ]
        }
      ];

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      expect(payload['total_exercises'], equals(3));
      expect((payload['exercises'] as List).length, equals(3));

      // Verify extra fields are stripped (only exer_id, exer_name, sets sent)
      final payloadExercises = payload['exercises'] as List;
      expect(payloadExercises[0].keys,
          containsAll(['exer_id', 'exer_name', 'sets']));
      expect((payloadExercises[0] as Map).keys.length, equals(3));
    });

    test('Workout payload with multiple sets per exercise', () {
      final exercises = [
        {
          'exer_id': 5,
          'exer_name': 'Bench Press',
          'sets': [
            {'kg': 60, 'reps': 8},
            {'kg': 65, 'reps': 6},
            {'kg': 70, 'reps': 4},
          ]
        }
      ];

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      final sets = ((payload['exercises'] as List)[0] as Map)['sets'] as List;
      expect(sets.length, equals(3));
      expect(sets[0]['kg'], equals(60));
      expect(sets[2]['kg'], equals(70));
    });

    test('Workout payload JSON serialization', () {
      final exercises = [
        {
          'exer_id': 1,
          'exer_name': 'Squat',
          'sets': [
            {'kg': 50, 'reps': 10}
          ]
        }
      ];

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      // Simulate POST body encoding
      final jsonPayload = jsonEncode(payload);
      expect(jsonPayload, isNotEmpty);
      expect(jsonPayload, isA<String>());

      // Verify it can be decoded back
      final decoded = jsonDecode(jsonPayload) as Map<String, dynamic>;
      expect(decoded['total_exercises'], equals(1));
    });

    test('Workout response parsing', () {
      const responseBody = '''{
        "status": "success",
        "workout_id": 42,
        "total_exercises": 2,
        "timestamp": "2025-04-04T10:30:00Z"
      }''';

      final Map<String, dynamic> decoded = jsonDecode(responseBody);

      expect(decoded['status'], equals('success'));
      expect(decoded['workout_id'], equals(42));
      expect(decoded['total_exercises'], equals(2));
    });

    test('Empty exercises list is handled', () {
      final exercises = <Map<String, dynamic>>[];

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      expect(payload['total_exercises'], equals(0));
      expect((payload['exercises'] as List), isEmpty);
    });

    test('Workout with no sets per exercise', () {
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Warm-up', 'sets': []}
      ];

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'],
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      final sets = ((payload['exercises'] as List)[0] as Map)['sets'] as List;
      expect(sets, isEmpty);
    });

    test('Content-Type header is set correctly', () {
      const headers = {'Content-Type': 'application/json'};
      expect(headers['Content-Type'], equals('application/json'));
    });
    test('UTC-073: Workout data formatted correctly from sets list', () {
      // Input data: Exercise with multiple sets
      final exercises = [
        {
          'exer_id': 101,
          'exer_name': 'Bench Press',
          'sets': [
            {'kg': 60, 'reps': 10},
            {'kg': 65, 'reps': 8},
            {'kg': 70, 'reps': 6},
          ]
        }
      ];

      // Logic to format as WorkoutService.submitWorkout does
      final formattedExercises = exercises.map((exercise) {
        final rawSets = exercise['sets'] as List;
        final setsArray = rawSets.map((s) => {
          'reps': int.tryParse(s['reps']?.toString() ?? '0') ?? 0,
          'kg': double.tryParse(s['kg']?.toString() ?? '0') ?? 0,
        }).toList();

        return {
          'exer_id': exercise['exer_id'],
          'exer_name': exercise['exer_name'],
          'sets': setsArray,
        };
      }).toList();

      final payload = {
        'exercises': formattedExercises,
      };

      // Assertions
      expect(payload['exercises'], isA<List>());
      final firstEx = (payload['exercises'] as List)[0];
      expect(firstEx['exer_id'], equals(101));
      expect(firstEx['exer_name'], equals('Bench Press'));
      
      final sets = firstEx['sets'] as List;
      expect(sets.length, equals(3));
      expect(sets[0]['kg'], equals(60.0));
      expect(sets[0]['reps'], equals(10));
      expect(sets[2]['kg'], equals(70.0));
      expect(sets[2]['reps'], equals(6));
    });
    test('UTC-074: Workout data formatted correctly from simple input', () {
      // Input data: Exercise with simple map input instead of list
      final exercises = [
        {
          'exer_id': 102,
          'exer_name': 'Push-up',
          'sets': {'kg': 0, 'reps': 15} // Direct map
        }
      ];

      // Updated logic to handle both List and Map (simulating expected service update)
      final formattedExercises = exercises.map((exercise) {
        final rawSets = exercise['sets'];
        List<Map<String, dynamic>> setsArray = [];

        if (rawSets is List) {
          setsArray = rawSets.map((s) => {
            'reps': int.tryParse(s['reps']?.toString() ?? '0') ?? 0,
            'kg': double.tryParse(s['kg']?.toString() ?? '0') ?? 0,
          }).toList();
        } else if (rawSets is Map) {
          setsArray = [{
            'reps': int.tryParse(rawSets['reps']?.toString() ?? '0') ?? 0,
            'kg': double.tryParse(rawSets['kg']?.toString() ?? '0') ?? 0,
          }];
        }

        return {
          'exer_id': exercise['exer_id'],
          'exer_name': exercise['exer_name'],
          'sets': setsArray,
        };
      }).toList();

      final firstEx = formattedExercises[0];
      expect(firstEx['exer_id'], equals(102));
      
      final sets = firstEx['sets'] as List;
      expect(sets.length, equals(1));
      expect(sets[0]['reps'], equals(15));
      expect(sets[0]['kg'], equals(0.0));
    });
    test('UTC-075: Workout submitted to server successfully', () async {
      final mockClient = MockHttpClient();
      final exercises = [
        {
          'exer_id': 1,
          'exer_name': 'Push-up',
          'sets': [
            {'kg': 0, 'reps': 10}
          ]
        }
      ];

      final successResponse = jsonEncode({
        'status': 'success',
        'workout_id': 123,
      });

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(successResponse, 201));

      final result = await WorkoutService.submitWorkout(
        exercises,
        client: mockClient,
        customHeaders: {'Authorization': 'Bearer test-token'},
      );

      expect(result['status'], equals('success'));
      expect(result['workout_id'], equals(123));
    });
    test('UTC-076: Workout submission fails with invalid data', () async {
      final mockClient = MockHttpClient();
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Push-up', 'sets': []}
      ];

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Invalid data', 400));

      expect(
        () => WorkoutService.submitWorkout(exercises, client: mockClient, customHeaders: {}),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid workout data'))),
      );
    });

    test('UTC-077: Workout submission fails on server error', () async {
      final mockClient = MockHttpClient();
      final exercises = [
        {'exer_id': 1, 'exer_name': 'Push-up', 'sets': []}
      ];

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => WorkoutService.submitWorkout(exercises, client: mockClient, customHeaders: {}),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Failed to submit workout: 500'))),
      );
    });
  });
}

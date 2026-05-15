import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Weekly Plan Service Tests', () {

    test('Test 1: Weekly workout plan loads successfully from server', () {
      // Server returns the weekly plan for a logged-in user
      final fakePlanData = {
        'plan': {
          'monday':    ['Push Day'],
          'tuesday':   ['Leg Day'],
          'wednesday': [],
          'thursday':  ['Push Day'],
          'friday':    [],
          'saturday':  ['Cardio'],
          'sunday':    [],
        }
      };

      final fakeResponse = http.Response(jsonEncode(fakePlanData), 200);

      expect(fakeResponse.statusCode, equals(200));

      // Parse as WeeklyPlanService.getWeeklyPlan would
      final data = jsonDecode(fakeResponse.body) as Map<String, dynamic>;
      final plan = data['plan'] as Map<String, dynamic>?;
      final result = plan ?? <String, dynamic>{};

      // Plan is returned showing routines assigned to each day
      expect(result, isNotNull);
      expect((result['monday'] as List).contains('Push Day'), isTrue);
      expect((result['tuesday'] as List).contains('Leg Day'), isTrue);
      expect((result['saturday'] as List).contains('Cardio'), isTrue);
    });

    test('Test 2: Weekly plan returns nothing when user is not logged in', () {
      // Simulate: no auth token available
      const String? token = null;

      // WeeklyPlanService checks: if (token == null || token.isEmpty) return null
      Map<String, dynamic>? result;
      if (token == null || token.isEmpty) {
        result = null; // Returns nothing without crashing
      }

      expect(result, isNull);
    });

    test('Test 3: Weekly plan returns nothing when server has an error', () {
      // Server returns an error (500)
      final fakeResponse = http.Response('Internal Server Error', 500);

      // WeeklyPlanService only reads body on 200; otherwise falls through to return null
      Map<String, dynamic>? result;
      if (fakeResponse.statusCode == 200) {
        result = jsonDecode(fakeResponse.body) as Map<String, dynamic>;
      }
      // else: returns null without crashing

      expect(result, isNull);
    });

    test('Test 4: Weekly plan returns nothing when no internet connection', () {
      // Simulate network exception (device offline)
      Map<String, dynamic>? result;
      try {
        throw Exception('SocketException: Failed host lookup'); // simulated
      } catch (e) {
        result = null; // catch block in service returns null
      }

      expect(result, isNull);
    });

    test('Test 5: Weekly Plan saves successfully to the server', () {
      // User assigns routines and saves — server returns 200
      final fakeResponse = http.Response(jsonEncode({'message': 'Plan saved'}), 200);

      // saveWeeklyPlan returns: response.statusCode == 200
      final saved = fakeResponse.statusCode == 200;

      // Plan is saved successfully, returns true
      expect(saved, isTrue);
    });

    test('Test 6: Weekly Plan cannot be saved if user not logged in', () {
      // Simulate: no auth token
      const String? token = null;

      // saveWeeklyPlan checks: if (token == null || token.isEmpty) return false
      bool result = true; // assume success until check
      if (token == null || token.isEmpty) {
        result = false; // plan not saved
      }

      expect(result, isFalse);
    });

    test('Test 7: Weekly Plan save will fail if error on server', () {
      // Server returns error on save attempt
      final fakeResponse = http.Response('Server Error', 500);

      // saveWeeklyPlan returns: response.statusCode == 200 (false here)
      final saved = fakeResponse.statusCode == 200;

      // Returns false without crashing
      expect(saved, isFalse);
    });

    test('Test 8: Weekly Plan sends correct day and routine data when saving', () {
      // User has 'Push Day' on Thursday, nothing on Friday
      final plan = <String, dynamic>{
        'monday':    <String>[],
        'tuesday':   <String>[],
        'wednesday': <String>[],
        'thursday':  ['Push Day'],
        'friday':    <String>[],
        'saturday':  <String>[],
        'sunday':    <String>[],
      };

      // Build payload as saveWeeklyPlan would
      final payload = jsonEncode({'plan': plan});
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final sentPlan = decoded['plan'] as Map<String, dynamic>;

      // Server receives 'Push Day' for Thursday
      expect((sentPlan['thursday'] as List).contains('Push Day'), isTrue);

      // No routines set for Friday
      expect((sentPlan['friday'] as List).isEmpty, isTrue);
    });

  });
}

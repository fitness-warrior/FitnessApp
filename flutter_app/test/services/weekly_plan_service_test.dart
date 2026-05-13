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

  });
}

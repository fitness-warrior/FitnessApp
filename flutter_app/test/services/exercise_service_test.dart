import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fitness_app_flutter/services/exercise_service.dart';

// Mock HTTP client for testing
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('ExerciseService Tests', () {
    test('ExerciseService base URL is configured', () {
      final baseUrl = ExerciseService.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, isA<String>());
    });

    test('Exercise list response parsing handles correct structure', () {
      // Raw API response
      final rawResponse = [
        {
          'exer_id': 1,
          'exer_name': 'Push-up',
          'exer_body_area': 'Chest',
          'exer_type': 'strength',
          'exer_descrip': 'Upper body pushing exercise',
          'exer_vid': 'https://example.com/pushup',
          'equipment': ['mat']
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      // Simulate response parsing
      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        m['exer_id'] = m['exer_id'] ?? m['id'];
        m['exer_name'] = m['exer_name'] ?? m['name'];
        m['exer_body_area'] = m['exer_body_area'] ?? m['area'];
        m['exer_type'] = m['exer_type'] ?? m['type'];
        m['exer_descrip'] = m['exer_descrip'] ?? m['description'];
        m['exer_vid'] = m['exer_vid'] ?? m['video_url'];
        return m;
      }).toList();

      expect(mapped.length, equals(1));
      expect(mapped[0]['exer_id'], equals(1));
      expect(mapped[0]['exer_name'], equals('Push-up'));
    });

    test('Exercise response normalization handles missing legacy keys', () {
      // API returns new field names
      final rawResponse = [
        {
          'id': 5,
          'name': 'Pull-up',
          'area': 'Back',
          'type': 'strength',
          'description': 'Upper body pulling exercise',
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        m['exer_id'] = m['exer_id'] ?? m['id'];
        m['exer_name'] = m['exer_name'] ?? m['name'];
        m['exer_body_area'] = m['exer_body_area'] ?? m['area'];
        m['exer_type'] = m['exer_type'] ?? m['type'];
        m['exer_descrip'] = m['exer_descrip'] ?? m['description'];
        return m;
      }).toList();

      // Should fallback to new field names
      expect(mapped[0]['exer_id'], equals(5));
      expect(mapped[0]['exer_name'], equals('Pull-up'));
      expect(mapped[0]['exer_body_area'], equals('Back'));
    });

    test('Exercise response handles equipment as list', () {
      final rawResponse = [
        {
          'exer_id': 1,
          'exer_name': 'Dumbbell Curl',
          'equipment': ['Dumbbell'],
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        if (m['exer_equip'] == null) {
          if (m['equipment'] is List) {
            m['exer_equip'] = (m['equipment'] as List).join(', ');
          } else if (m['equipment'] != null) {
            m['exer_equip'] = m['equipment'].toString();
          } else {
            m['exer_equip'] = '';
          }
        }
        return m;
      }).toList();

      expect(mapped[0]['exer_equip'], equals('Dumbbell'));
    });

    test('Exercise response handles equipment as string', () {
      final rawResponse = [
        {
          'exer_id': 2,
          'exer_name': 'Barbell Squat',
          'equipment': 'Barbell',
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        if (m['exer_equip'] == null) {
          if (m['equipment'] is List) {
            m['exer_equip'] = (m['equipment'] as List).join(', ');
          } else if (m['equipment'] != null) {
            m['exer_equip'] = m['equipment'].toString();
          } else {
            m['exer_equip'] = '';
          }
        }
        return m;
      }).toList();

      expect(mapped[0]['exer_equip'], equals('Barbell'));
    });

    test('Exercise response handles multiple equipment items', () {
      final rawResponse = [
        {
          'exer_id': 3,
          'exer_name': 'Circuit Training',
          'equipment': ['Dumbbell', 'Barbell', 'Rope'],
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        if (m['exer_equip'] == null && m['equipment'] is List) {
          m['exer_equip'] = (m['equipment'] as List).join(', ');
        }
        return m;
      }).toList();

      expect(mapped[0]['exer_equip'], equals('Dumbbell, Barbell, Rope'));
    });

    test('Exercise response handling empty equipment list', () {
      final rawResponse = [
        {
          'exer_id': 4,
          'exer_name': 'Bodyweight Squat',
          'equipment': [],
        },
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        if (m['exer_equip'] == null) {
          if (m['equipment'] is List) {
            m['exer_equip'] = (m['equipment'] as List).join(', ');
          } else if (m['equipment'] != null) {
            m['exer_equip'] = m['equipment'].toString();
          } else {
            m['exer_equip'] = '';
          }
        }
        return m;
      }).toList();

      expect(mapped[0]['exer_equip'], isEmpty);
    });

    test('Multiple exercises in response are all normalized', () {
      final rawResponse = [
        {'id': 1, 'name': 'Push-up', 'area': 'Chest'},
        {'id': 2, 'name': 'Pull-up', 'area': 'Back'},
        {'id': 3, 'name': 'Squat', 'area': 'Legs'},
      ];

      final jsonString = jsonEncode(rawResponse);
      final List<dynamic> data = jsonDecode(jsonString);

      List<Map<String, dynamic>> mapped =
          data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        m['exer_id'] = m['exer_id'] ?? m['id'];
        m['exer_name'] = m['exer_name'] ?? m['name'];
        m['exer_body_area'] = m['exer_body_area'] ?? m['area'];
        return m;
      }).toList();

      expect(mapped.length, equals(3));
      expect(mapped[0]['exer_name'], equals('Push-up'));
      expect(mapped[1]['exer_name'], equals('Pull-up'));
      expect(mapped[2]['exer_name'], equals('Squat'));
    });
  });
}

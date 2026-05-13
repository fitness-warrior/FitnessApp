import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class WorkoutService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Submit a completed workout (saves to user account)
  static Future<Map<String, dynamic>> submitWorkout(
    List<Map<String, dynamic>> exercises, {
    int? durationMinutes,
    String? notes,
    http.Client? client,
    Map<String, String>? customHeaders,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final headers = customHeaders ?? await AuthService.getAuthHeaders();

      final payload = {
        'exercises': exercises.map((exercise) {
          final rawSets = exercise['sets'];
          final exerType = exercise['exer_type']?.toString().toLowerCase() ?? 'strength';

          List<Map<String, dynamic>> setsArray = [];

          if (rawSets is List && rawSets.isNotEmpty) {
            for (var set in rawSets) {
              if (set is Map) {
                if (exerType == 'cardio') {
                  setsArray.add({
                    'time': int.tryParse(set['time']?.toString() ?? '0') ?? 0,
                    'distance':
                        double.tryParse(set['distance']?.toString() ?? '0') ?? 0,
                  });
                } else {
                  setsArray.add({
                    'reps': int.tryParse(set['reps']?.toString() ?? '0') ?? 0,
                    'kg': double.tryParse(set['kg']?.toString() ?? '0') ?? 0,
                  });
                }
              }
            }
          }

          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': setsArray,  // Send full array, not just count
            'notes': exercise['notes'] ?? '',
          };
        }).toList(),
        'duration_minutes': durationMinutes ?? 0,
        'notes': notes ?? '',
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/workouts'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw Exception('Invalid workout data');
      } else {
        throw Exception('Failed to submit workout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting workout: $e');
    }
  }
}

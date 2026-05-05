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
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'] ?? 0,
            'reps': exercise['reps'] ?? 0,
            'weight': exercise['weight'] ?? 0,
            'notes': exercise['notes'] ?? '',
          };
        }).toList(),
        'duration_minutes': durationMinutes ?? 0,
        'notes': notes ?? '',
      };

      final response = await http.post(
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

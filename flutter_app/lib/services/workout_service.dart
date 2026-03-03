import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutService {
  static const String baseUrl = 'http://10.0.2.2:5001/api';

  static Future<Map<String, dynamic>> submitWorkout(
    List<Map<String, dynamic>> exercises,
  ) async {
    try {
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

      final response = await http.post(
        Uri.parse('$baseUrl/workouts'),
        headers: {'Content-Type': 'application/json'},
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

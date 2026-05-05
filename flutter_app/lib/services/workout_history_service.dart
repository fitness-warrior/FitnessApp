import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class WorkoutHistoryService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Save a completed workout to user's account
  static Future<Map<String, dynamic>> saveWorkout(
    List<Map<String, dynamic>> exercises,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final payload = {
        'exercises': exercises.map((exercise) {
          return {
            'exer_id': exercise['exer_id'],
            'exer_name': exercise['exer_name'],
            'sets': exercise['sets'] ?? 0,
            'reps': exercise['reps'],
            'weight': exercise['weight'],
            'notes': exercise['notes'] ?? '',
          };
        }).toList(),
        'total_exercises': exercises.length,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/workouts'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to save workout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving workout: $e');
    }
  }

  /// Get user's workout history
  static Future<List<Map<String, dynamic>>> getWorkoutHistory({
    int? limit,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final queryParams = <String, String>{};
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('$baseUrl/workouts').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception('Failed to fetch workouts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching workouts: $e');
    }
  }

  /// Get a specific workout by ID
  static Future<Map<String, dynamic>?> getWorkout(int workoutId) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/workouts/$workoutId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch workout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching workout: $e');
    }
  }

  /// Delete a saved workout
  static Future<bool> deleteWorkout(int workoutId) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/workouts/$workoutId'),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting workout: $e');
    }
  }
}

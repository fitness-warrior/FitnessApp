import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseDb {
  static final ExerciseDb instance = ExerciseDb._();
  ExerciseDb._();

  // Update this URL to match your backend API
  static const String baseUrl = 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> listExercises() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Failed to load exercises: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }
}

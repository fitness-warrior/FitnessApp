import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ExerciseDb {
  static final ExerciseDb instance = ExerciseDb._();
  ExerciseDb._();

  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(row);
    m['exer_id'] = m['exer_id'] ?? m['id'];
    m['exer_name'] = m['exer_name'] ?? m['name'] ?? m['title'];
    m['exer_body_area'] = m['exer_body_area'] ?? m['body_area'] ?? m['area'];
    m['exer_type'] = m['exer_type'] ?? m['type'];
    m['exer_descrip'] = m['exer_descrip'] ?? m['description'] ?? m['desc'];
    m['exer_vid'] = m['exer_vid'] ?? m['video_url'] ?? m['vid'];
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
  }

  Future<List<Map<String, dynamic>>> listExercises({
    String? name,
    String? area,
    String? type,
    List<String>? equipment,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (name != null) queryParams['name'] = name;
      if (area != null) queryParams['area'] = area;
      if (type != null) queryParams['type'] = type;
      if (equipment != null && equipment.isNotEmpty) {
        queryParams['equipment'] = equipment.join(',');
      }

      final uri = Uri.parse('$baseUrl/exercises').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => _normalizeRow(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        print('Failed to load exercises: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExercise(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _normalizeRow(Map<String, dynamic>.from(data));
      } else {
        print('Failed to load exercise $id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching exercise $id: $e');
      return null;
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
        return data
            .map((e) => _normalizeRow(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }
}

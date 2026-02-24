import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseService {
  // Update baseUrl if your API runs elsewhere
  static const String baseUrl = 'http://10.0.2.2:5001/api';

  static Future<List<Map<String, dynamic>>> listExercises({
    String? name,
    String? area,
    String? type,
    List<String>? equipment,
  }) async {
    final uri = Uri.parse('$baseUrl/exercises').replace(queryParameters: {
      if (name != null) 'name': name,
      if (area != null) 'area': area,
      if (type != null) 'type': type,
      // equipment[] is handled by multiple query params below
    });

    // If equipment list provided, add them manually
    Uri finalUri = uri;
    if (equipment != null && equipment.isNotEmpty) {
      final query = Map<String, String>.from(uri.queryParameters);
      for (var i = 0; i < equipment.length; i++) {
        query['equipment'] =
            equipment[i]; // repeated key supported by http package
      }
      finalUri = uri.replace(queryParameters: query);
    }

    final res = await http.get(finalUri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load exercises: ${res.statusCode}');
    }
    final List<dynamic> data = json.decode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getExercise(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/exercises/$id'));
    if (res.statusCode == 404) throw Exception('Exercise not found');
    if (res.statusCode != 200) throw Exception('Failed to load exercise');
    return json.decode(res.body) as Map<String, dynamic>;
  }
}

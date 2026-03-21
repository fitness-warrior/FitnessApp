import 'dart:convert';
import 'package:flutter/foundation.dart'; // add this for debugPrint
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ExerciseService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> listExercises({
    String? name,
    String? area,
    String? type,
    List<String>? equipment,
  }) async {
    final uri = Uri.parse('$baseUrl/exercises').replace(
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (area != null && area.isNotEmpty) 'area': area,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    
    final queryParts = <String>[];
    void addParam(String key, String value) {
      if (value.trim().isEmpty) return;
      queryParts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }

    if (name != null) addParam('name', name);
    if (area != null) addParam('area', area);
    if (type != null) addParam('type', type);
    if (equipment != null) {
      for (final e in equipment) {
        addParam('equipment', e); // repeated key supported by FastAPI
      }
    }

    final finalUri = uri.replace(query: queryParts.join('&'));

    debugPrint('GET => $finalUri'); // paste here
    final res = await http.get(finalUri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load exercises: ${res.statusCode}');
    }
    final List<dynamic> data = json.decode(res.body);

    // Normalize returned objects to ensure frontend-friendly keys (exer_*) exist
    List<Map<String, dynamic>> mapped = data.map<Map<String, dynamic>>((item) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
      // map common names to legacy exer_* keys expected by widgets
      m['exer_id'] = m['exer_id'] ?? m['id'];
      m['exer_name'] = m['exer_name'] ?? m['name'] ?? m['title'];
      m['exer_body_area'] = m['exer_body_area'] ?? m['body_area'] ?? m['area'];
      m['exer_type'] = m['exer_type'] ?? m['type'];
      m['exer_descrip'] = m['exer_descrip'] ?? m['description'] ?? m['desc'];
      m['exer_vid'] = m['exer_vid'] ?? m['video_url'] ?? m['vid'];
      // equipment: allow list or string; widget expects a string
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

    return mapped;
  }

  static Future<Map<String, dynamic>> getExercise(int id) async {
    final uri = Uri.parse('$baseUrl/exercises/$id'); // fixed: remove extra /api
    debugPrint('GET => $uri'); // paste here
    final res = await http.get(uri);

    if (res.statusCode == 404) throw Exception('Exercise not found');
    if (res.statusCode != 200) throw Exception('Failed to load exercise');
    final Map<String, dynamic> m =
        Map<String, dynamic>.from(json.decode(res.body) as Map);
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
}

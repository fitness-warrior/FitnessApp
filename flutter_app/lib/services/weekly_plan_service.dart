import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class WeeklyPlanService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Fetches the weekly plan from the server.
  /// Returns null if the user is not authenticated or the call fails.
  /// Returns a map (possibly with empty lists) on success.
  static Future<Map<String, dynamic>?> getWeeklyPlan() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return null;

      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/weekly-plan'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final plan = data['plan'] as Map<String, dynamic>?;
        return plan ?? <String, dynamic>{};
      }
      debugPrint('[WeeklyPlan] GET ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[WeeklyPlan] GET error: $e');
    }
    return null;
  }

  /// Saves the weekly plan to the server.
  static Future<bool> saveWeeklyPlan(Map<String, dynamic> plan) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return false;

      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/weekly-plan'),
            headers: headers,
            body: jsonEncode({'plan': plan}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('[WeeklyPlan] POST ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[WeeklyPlan] POST error: $e');
      return false;
    }
  }
}

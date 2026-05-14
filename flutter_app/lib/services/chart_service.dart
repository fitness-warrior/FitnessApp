import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ChartService {
  static final _updateController = StreamController<void>.broadcast();
  static Stream<void> get onChartsChanged => _updateController.stream;

  static void notifyChartsChanged() {
    _updateController.add(null);
  }

  static String get baseUrl => ApiConfig.baseUrl;
  
  static String get pythonBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://localhost:8000';
    }
  }
  static Future<void> saveChart(String userEmail, int bodyId, String chartName, String measure) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'dashboard_charts_$userEmail';
    final List<String> current = prefs.getStringList(key) ?? [];
    
    // Format: "name|measure"
    final newEntry = '$chartName|$measure';
    if (!current.contains(newEntry)) {
      current.add(newEntry);
      await prefs.setStringList(key, current);
      notifyChartsChanged();
    }
  }

  static Future<List<Map<String, String>>> getSavedCharts(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'dashboard_charts_$userEmail';
    final List<String> saved = prefs.getStringList(key) ?? [];
    
    return saved.map((s) {
      final parts = s.split('|');
      return {
        'name': parts[0],
        'measure': parts.length > 1 ? parts[1] : '',
      };
    }).toList();
  }

  static Future<void> deleteChart(String userEmail, String chartName, String measure) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'dashboard_charts_$userEmail';
    final List<String> current = prefs.getStringList(key) ?? [];
    
    final entry = '$chartName|$measure';
    current.remove(entry);
    await prefs.setStringList(key, current);
    notifyChartsChanged();
  }

  static Future<int> getBodyId() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await AuthService.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['body_id'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Convert chart data list to double values for graphing
  static List<double> extractValues(List<dynamic> data) {
    return data.map((item) => (item[1] as num).toDouble()).toList();
  }

  static Future<List<dynamic>> getCardioSpeed(String exercise, int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/cardio-speed/$exercise'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getCardioEndurance(String exercise, int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/cardio-endurance/$exercise'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getWeight(int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/weight'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getBodyType(int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/body-type'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<Chart>> getChartOptions(int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/api/charts/options'),
      headers: await AuthService.getAuthHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Chart(
        name: item['name'] as String,
        measure: List<String>.from(item['measure'] as List),
      )).toList();
    }
    return [];
  }

  static Future<List<dynamic>> getTodayExercises() async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/api/workouts/today/exercises'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getStrengthTotal(String exercise, int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/strength-total/$exercise'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getTotalVolume(int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/total-volume'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getDailyCardioCalories(int bodyId) async {
    final response = await http.get(
      Uri.parse('$pythonBaseUrl/chart/daily-cardio-calories'),
      headers: await AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
}

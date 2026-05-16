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
    
    final newEntry = '$chartName|$measure';
    if (!current.contains(newEntry)) {
      current.add(newEntry);
      await prefs.setStringList(key, current);
      debugPrint('CHART_STORAGE: Saved to $key => $current');
      notifyChartsChanged();
    }
  }

  static Future<List<Map<String, String>>> getSavedCharts(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'dashboard_charts_$userEmail';
    final List<String> saved = prefs.getStringList(key) ?? [];
    debugPrint('CHART_STORAGE: Loaded from $key => $saved');
    
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
    if (current.contains(entry)) {
      current.remove(entry);
      await prefs.setStringList(key, current);
      debugPrint('CHART_STORAGE: Deleted from $key => $current');
      notifyChartsChanged();
    }
  }

  static Future<void> hideChart(String userEmail, String chartName, String option) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/api/user/hidden-charts'),
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode({
          'chart_name': chartName.trim(),
          'option': option.trim(),
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('CHART_STORAGE: Successfully hid $chartName|$option on server');
      } else {
        debugPrint('CHART_STORAGE: Failed to hide $chartName|$option. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('CHART_STORAGE: Error hiding chart: $e');
    }
  }

  static Future<void> unhideChart(String userEmail, String chartName, String option) async {
    try {
      final response = await http.delete(
        Uri.parse('$pythonBaseUrl/api/user/hidden-charts?chart_name=${Uri.encodeComponent(chartName.trim())}&option=${Uri.encodeComponent(option.trim())}'),
        headers: await AuthService.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        debugPrint('CHART_STORAGE: Successfully unhid $chartName|$option on server');
      } else {
        debugPrint('CHART_STORAGE: Failed to unhide $chartName|$option. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('CHART_STORAGE: Error unhiding chart: $e');
    }
  }

  static Future<Set<String>> getHiddenCharts() async {
    try {
      final response = await http.get(
        Uri.parse('$pythonBaseUrl/api/user/hidden-charts'),
        headers: await AuthService.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final set = data.map((item) => '${item['chart_name'].toString().trim()}|${item['option'].toString().trim()}').toSet();
        debugPrint('CHART_STORAGE: Fetched hidden charts from server: $set');
        return set;
      }
    } catch (e) {
      debugPrint('CHART_STORAGE: Error fetching hidden charts: $e');
    }
    return {};
  }

  static Future<bool> isChartHidden(String userEmail, String chartName, String option) async {
    // This is now less efficient if called in a loop, 
    // views should call getHiddenCharts() instead and check locally.
    final hidden = await getHiddenCharts();
    return hidden.contains('${chartName.trim()}|${option.trim()}');
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

  static Future<Map<String, List<List<dynamic>>>> getAllExercisesProgress() async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/api/user/exercises-progress');
      final res = await http.get(uri, headers: await AuthService.getAuthHeaders());
      if (res.statusCode != 200) throw Exception('Failed to load exercise progress');
      final Map<String, dynamic> data = json.decode(res.body);
      
      return data.map((key, value) {
        final List<dynamic> history = value;
        return MapEntry(key, history.map((h) => [h[0].toString(), double.tryParse(h[1]?.toString() ?? '0') ?? 0.0]).toList());
      });
    } catch (e) {
      debugPrint('Error fetching all exercises progress: $e');
      return {};
    }
  }

  static Future<List<List<dynamic>>> getWorkoutVolume() async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/api/user/workout-volume');
      final res = await http.get(uri, headers: await AuthService.getAuthHeaders());
      if (res.statusCode != 200) throw Exception('Failed to load volume');
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is Map) {
          final date = item['date']?.toString() ?? '';
          final volume = double.tryParse(item['total_kg']?.toString() ?? '0') ?? 0.0;
          return [date, volume, item['id']];
        }
        return [item.toString(), 0.0, 0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching workout volume: $e');
      return [];
    }
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

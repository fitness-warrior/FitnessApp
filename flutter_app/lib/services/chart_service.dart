import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chart_model.dart';
import '../config/api_config.dart';

class ChartService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static String get pythonBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  /// Fetch cardio speed data for an exercise
  /// Returns list of [date, speed] pairs
  static Future<List<List<dynamic>>> getCardioSpeed(String exerciseName, int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/cardio-speed/$bodyId/$exerciseName');
      debugPrint('GET => $uri');
      
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load cardio speed: ${res.statusCode}');
      }
      
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0], (item[1] as num).toDouble()];
        }
        return [item, 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching cardio speed: $e');
      rethrow;
    }
  }

  /// Fetch cardio endurance data for an exercise
  /// Returns list of [date, distance] pairs
  static Future<List<List<dynamic>>> getCardioEndurance(String exerciseName, int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/cardio-endurance/$bodyId/$exerciseName');
      debugPrint('GET => $uri');
      
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load cardio endurance: ${res.statusCode}');
      }
      
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0], (item[1] as num).toDouble()];
        }
        return [item, 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching cardio endurance: $e');
      rethrow;
    }
  }

  /// Fetch strength total data for an exercise
  /// Returns list of [date, total] pairs
  static Future<List<List<dynamic>>> getStrengthTotal(String exerciseName, int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/strength-total/$bodyId/$exerciseName');
      debugPrint('GET => $uri');
      
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load strength total: ${res.statusCode}');
      }
      
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0], (item[1] as num).toDouble()];
        }
        return [item, 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching strength total: $e');
      rethrow;
    }
  }

  /// Fetch daily cardio calories
  /// Returns list of [date, calories] pairs
  static Future<List<List<dynamic>>> getDailyCardioCalories(int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/daily-cardio-calories/$bodyId');
      debugPrint('GET => $uri');
      
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load daily cardio calories: ${res.statusCode}');
      }
      
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0], (item[1] as num).toDouble()];
        }
        return [item, 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching daily cardio calories: $e');
      rethrow;
    }
  }

  /// Fetch weight (current and past) for body
  static Future<List<List<dynamic>>> getWeight(int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/weight/$bodyId');
      debugPrint('GET => $uri');

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load weight: ${res.statusCode}');
      }

      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0], (item[1] as num).toDouble()];
        }
        return [item, 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching weight: $e');
      rethrow;
    }
  }

  /// Fetch body type distribution for pie chart
  static Future<List<List<dynamic>>> getBodyType(int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/chart/body-type/$bodyId');
      debugPrint('GET => $uri');

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load body type: ${res.statusCode}');
      }

      final List<dynamic> data = json.decode(res.body);
      return data.map((item) {
        if (item is List && item.length == 2) {
          return [item[0].toString(), (item[1] as num).toDouble()];
        }
        return [item.toString(), 0.0];
      }).toList();
    } catch (e) {
      debugPrint('Error fetching body type: $e');
      rethrow;
    }
  }

  /// Fetch chart picker options grouped by cardio and strength exercises.
  static Future<List<Chart>> getChartOptions(int bodyId) async {
    try {
      final uri = Uri.parse('$pythonBaseUrl/api/charts/options?body_id=$bodyId');
      debugPrint('GET => $uri');

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load chart options: ${res.statusCode}');
      }

      final List<dynamic> data = json.decode(res.body) as List<dynamic>;
      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Chart(
          name: map['name'] as String,
          measure: List<String>.from(map['measure'] as List),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching chart options: $e');
      rethrow;
    }
  }

  /// Convert chart data list to double values for graphing
  static List<double> extractValues(List<List<dynamic>> chartData) {
    return chartData.map((item) {
      if (item.length >= 2 && item[1] is num) {
        return (item[1] as num).toDouble();
      }
      return 0.0;
    }).toList();
  }
}

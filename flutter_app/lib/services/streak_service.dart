import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class StreakService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get user's current streak information
  static Future<Map<String, dynamic>> getStreak() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/streak'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Streak not initialized
        return {
          'current_streak': 0,
          'longest_streak': 0,
          'workouts_this_week': 0,
          'weekly_goal': 3,
        };
      } else {
        throw Exception('Failed to fetch streak: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching streak: $e');
    }
  }

  /// Update streak after a workout is completed
  static Future<Map<String, dynamic>> updateStreak() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/streak/update'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update streak: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating streak: $e');
    }
  }

  /// Parse streak response and return organized data
  static StreakData parseStreakData(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      workoutsThisWeek: json['workouts_this_week'] ?? 0,
      weeklyGoal: json['weekly_goal'] ?? 3,
      lastWorkoutDate: json['last_workout_date'],
      streakStartDate: json['streak_start_date'],
      weekStartDate: json['week_start_date'],
    );
  }
}

/// Model class for streak data
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int workoutsThisWeek;
  final int weeklyGoal;
  final String? lastWorkoutDate;
  final String? streakStartDate;
  final String? weekStartDate;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutsThisWeek,
    required this.weeklyGoal,
    this.lastWorkoutDate,
    this.streakStartDate,
    this.weekStartDate,
  });

  /// Check if weekly goal is met
  bool get goalMet => workoutsThisWeek >= weeklyGoal;

  /// Get remaining workouts needed for the week
  int get workoutsRemaining =>
      (weeklyGoal - workoutsThisWeek).clamp(0, weeklyGoal);

  /// Get progress percentage for the week (0-100)
  int get weeklyProgressPercent {
    final percent = ((workoutsThisWeek / weeklyGoal) * 100).toInt();
    return percent.clamp(0, 100);
  }
}

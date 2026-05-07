import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class StreakService {
  static String get baseUrl => ApiConfig.baseUrl;
  static final ValueNotifier<int> streakVersion = ValueNotifier<int>(0);

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kCurrentStreak = 'local_current_streak';
  static const _kLongestStreak = 'local_longest_streak';
  static const _kWorkoutsThisWeek = 'local_workouts_this_week';
  static const _kWeeklyGoal = 'local_weekly_goal';
  static const _kLastWorkoutDate = 'local_last_workout_date';
  static const _kWeekStartDate = 'local_week_start_date';

  static void notifyStreakChanged() {
    streakVersion.value++;
  }

  // ── Local helpers ──────────────────────────────────────────────────────────

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns Monday of the current week as a date string.
  static String _weekStartKey() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  /// Returns true if [dateKey] is exactly one day before today.
  static bool _isYesterday(String dateKey) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final y =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return dateKey == y;
  }

  // ── Local read/write ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'current_streak': prefs.getInt(_kCurrentStreak) ?? 0,
      'longest_streak': prefs.getInt(_kLongestStreak) ?? 0,
      'workouts_this_week': prefs.getInt(_kWorkoutsThisWeek) ?? 0,
      'weekly_goal': prefs.getInt(_kWeeklyGoal) ?? 3,
      'last_workout_date': prefs.getString(_kLastWorkoutDate),
      'week_start_date': prefs.getString(_kWeekStartDate),
    };
  }

  /// Increments streak locally. Called every time a workout finishes.
  /// Only counts once per calendar day.
  static Future<Map<String, dynamic>> _updateLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final weekStart = _weekStartKey();

    final lastDate = prefs.getString(_kLastWorkoutDate);
    final savedWeekStart = prefs.getString(_kWeekStartDate);

    // Already recorded a workout today — don't double-count
    if (lastDate == today) {
      return _readLocal();
    }

    // Reset weekly counter when a new week starts
    int workoutsThisWeek = prefs.getInt(_kWorkoutsThisWeek) ?? 0;
    if (savedWeekStart != weekStart) {
      workoutsThisWeek = 0;
      await prefs.setString(_kWeekStartDate, weekStart);
    }
    workoutsThisWeek++;
    await prefs.setInt(_kWorkoutsThisWeek, workoutsThisWeek);

    // Calculate streak: extends if last workout was yesterday or today
    int currentStreak = prefs.getInt(_kCurrentStreak) ?? 0;
    if (lastDate == null || _isYesterday(lastDate)) {
      currentStreak++;
    } else {
      // Gap of more than one day — streak resets
      currentStreak = 1;
    }
    await prefs.setInt(_kCurrentStreak, currentStreak);

    // Update longest streak
    int longest = prefs.getInt(_kLongestStreak) ?? 0;
    if (currentStreak > longest) {
      longest = currentStreak;
      await prefs.setInt(_kLongestStreak, longest);
    }

    // Record today
    await prefs.setString(_kLastWorkoutDate, today);

    return {
      'current_streak': currentStreak,
      'longest_streak': longest,
      'workouts_this_week': workoutsThisWeek,
      'weekly_goal': prefs.getInt(_kWeeklyGoal) ?? 3,
      'last_workout_date': today,
      'week_start_date': weekStart,
    };
  }

  /// Reads just the saved weekly goal (defaults to 3 if never set).
  static Future<int> readWeeklyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWeeklyGoal) ?? 3;
  }

  /// Saves the user's chosen weekly workout goal.
  static Future<void> setWeeklyGoal(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklyGoal, days.clamp(1, 7));
    notifyStreakChanged(); // refresh any listening widgets
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Update streak after a workout is completed.
  /// Always updates locally first so the counter works offline.
  /// Then syncs to the backend in the background (best-effort).
  static Future<Map<String, dynamic>> updateStreak() async {
    // Local update first — this always works
    final localResult = await _updateLocal();

    // Background sync to API — fire and forget
    _syncStreakToApi().catchError((_) {});

    return localResult;
  }

  static Future<void> _syncStreakToApi() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      await http
          .post(Uri.parse('$baseUrl/streak/update'), headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silently ignore — local data is the source of truth
    }
  }

  /// Get user's current streak information.
  /// Tries the backend first; falls back to local SharedPreferences.
  static Future<Map<String, dynamic>> getStreak() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/streak'), headers: headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final apiData =
            jsonDecode(response.body) as Map<String, dynamic>;
        // Merge: take max of API + local streak so neither source loses data
        final localData = await _readLocal();
        final localStreak = localData['current_streak'] as int;
        final apiStreak = (apiData['current_streak'] ?? 0) as int;
        if (localStreak > apiStreak) return localData;
        return apiData;
      }
    } catch (_) {
      // Fall through to local
    }
    return _readLocal();
  }

  /// Parse streak response into a typed model.
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

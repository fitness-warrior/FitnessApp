import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/daily_meal_plan.dart';
import 'auth_service.dart';

/// Persists daily meal plans to local storage using SharedPreferences.
///
/// Plans are keyed by calendar date (yyyy-MM-dd) so each day has its own plan.
class MealStorage {
  static const _prefix = 'meal_plan_';

  static Future<String> _userScope() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['user_id']?.toString();
    return userId == null || userId.isEmpty ? 'guest' : userId;
  }

  static Future<String> _keyFor(DateTime date) async {
    final scope = await _userScope();
    return '$_prefix$scope-${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
  }

  /// Load the plan for [date], or a fresh empty plan if none is saved.
  static Future<DailyMealPlan> loadPlan(DateTime date) async {
    // Prefer server copy when logged-in, fall back to local storage
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        final dateStr = date.toIso8601String().split('T').first;
        final uri = Uri.parse('${ApiConfig.baseUrl}/meals?plan_date=$dateStr');
        final headers = await AuthService.getAuthHeaders();
        final resp = await http.get(uri, headers: headers);
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          final planObj = body['plan'] as Map<String, dynamic>?;
          if (planObj == null || planObj.isEmpty) return DailyMealPlan(date: date);
          return DailyMealPlan.fromMap(planObj);
        }
      }
    } catch (_) {
      // ignore network errors and fall back to local
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _keyFor(date));
    if (raw == null) return DailyMealPlan(date: date);
    try {
      return DailyMealPlan.fromJson(raw);
    } catch (_) {
      return DailyMealPlan(date: date);
    }
  }

  /// Persist [plan] to local storage.
  static Future<void> savePlan(DailyMealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _keyFor(plan.date), plan.toJson());

    // Try to sync to server when logged in (best-effort)
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) return;

      final dateStr = plan.date.toIso8601String().split('T').first;
      final uri = Uri.parse('${ApiConfig.baseUrl}/meals');
      final headers = await AuthService.getAuthHeaders();
      final body = jsonEncode({
        'plan_date': dateStr,
        'plan': plan.toMap(),
      });

      await http.post(uri, headers: headers, body: body);
    } catch (_) {
      // ignore network/save errors — local copy remains authoritative until sync succeeds
    }
  }

  /// Delete the saved plan for [date].
  static Future<void> clearPlan(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _keyFor(date));
  }

  /// Returns all saved plan dates (newest first).
  static Future<List<DateTime>> savedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final scope = await _userScope();
    final keys =
        prefs.getKeys().where((k) => k.startsWith('$_prefix$scope-')).toList();
    final dates = keys
        .map((k) {
          try {
            return DateTime.parse(k.substring('$_prefix$scope-'.length));
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return dates;
  }
}

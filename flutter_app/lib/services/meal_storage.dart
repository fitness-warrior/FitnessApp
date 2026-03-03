import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_meal_plan.dart';

/// Persists daily meal plans to local storage using SharedPreferences.
///
/// Plans are keyed by calendar date (yyyy-MM-dd) so each day has its own plan.
class MealStorage {
  static const _prefix = 'meal_plan_';

  static String _keyFor(DateTime date) =>
      '$_prefix${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

  /// Load the plan for [date], or a fresh empty plan if none is saved.
  static Future<DailyMealPlan> loadPlan(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(date));
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
    await prefs.setString(_keyFor(plan.date), plan.toJson());
  }

  /// Delete the saved plan for [date].
  static Future<void> clearPlan(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(date));
  }

  /// Returns all saved plan dates (newest first).
  static Future<List<DateTime>> savedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    final dates = keys
        .map((k) {
          try {
            return DateTime.parse(k.substring(_prefix.length));
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

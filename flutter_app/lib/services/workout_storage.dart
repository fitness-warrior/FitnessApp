import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutStorage {
  static const _key = 'saved_workouts';

  /// Saves a completed workout to local storage.
  /// [exercises] is a list of {exer_id, exer_name, sets: [{kg, reps}]}
  static Future<void> saveWorkout(List<Map<String, dynamic>> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    final List<dynamic> all = existing != null ? jsonDecode(existing) : [];
    all.add({
      'date': DateTime.now().toIso8601String(),
      'exercises': exercises,
    });
    await prefs.setString(_key, jsonEncode(all));
  }

  /// Returns all saved workouts, newest first.
  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing == null) return [];
    final List<dynamic> all = jsonDecode(existing);
    return all.reversed
        .map((w) => Map<String, dynamic>.from(w))
        .toList();
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutStorage {
  static const _key = 'saved_workouts';
  static const _currentWorkoutKey = 'current_workout_session';

  /// Saves the current in-progress workout session (exercises being edited).
  /// This ensures exercises persist when navigating away and back.
  static Future<void> saveCurrentWorkoutSession(
    List<Map<String, dynamic>> exercises,
    Map<int, List<Map<String, dynamic>>> setControllers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Serialize set controllers (convert to string keys for JSON compatibility)
    final serializedSets = <String, List<Map<String, String>>>{};
    setControllers.forEach((index, sets) {
      serializedSets[index.toString()] = sets
          .map((set) => {
                'kg': set['kg'] is String ? set['kg'] as String : set['kg'].toString(),
                'reps': set['reps'] is String ? set['reps'] as String : set['reps'].toString(),
              })
          .toList();
    });

    final sessionData = {
      'exercises': exercises,
      'setControllers': serializedSets,
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_currentWorkoutKey, jsonEncode(sessionData));
  }

  /// Loads the current in-progress workout session if it exists.
  /// Returns null if no session was saved.
  static Future<Map<String, dynamic>?> loadCurrentWorkoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_currentWorkoutKey);
    if (sessionJson == null) return null;
    
    try {
      final data = Map<String, dynamic>.from(jsonDecode(sessionJson));
      
      // Convert setControllers string keys back to int keys if needed
      if (data['setControllers'] is Map) {
        final setControllersMap = Map<String, dynamic>.from(data['setControllers']);
        final convertedSets = <String, dynamic>{};
        
        setControllersMap.forEach((key, value) {
          convertedSets[key] = value;
        });
        
        data['setControllers'] = convertedSets;
      }
      
      return data;
    } catch (e) {
      print('Error deserializing workout session: $e');
      return null;
    }
  }

  /// Clears the current workout session.
  static Future<void> clearCurrentWorkoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentWorkoutKey);
  }

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

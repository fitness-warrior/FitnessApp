import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class WorkoutStorage {
  static const _key = 'saved_workouts';
  static const _currentWorkoutsKey = 'current_workout_sessions_list';

  static Future<String> _getNamespacedKey(String baseKey) async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['id']?.toString() ?? 'anonymous';
    return '${baseKey}_$userId';
  }

  /// Saves all current in-progress workout sessions.
  static Future<void> saveCurrentWorkoutSessions(
    List<List<Map<String, dynamic>>> activeExercisesList,
    List<Map<int, List<Map<String, dynamic>>>> activeSetsList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<Map<String, dynamic>> sessionsToSave = [];
    
    for (int i = 0; i < activeExercisesList.length; i++) {
      final exercises = activeExercisesList[i];
      final setControllers = activeSetsList[i];
      
      final serializedSets = <String, List<Map<String, String>>>{};
      setControllers.forEach((index, sets) {
        serializedSets[index.toString()] = sets
            .map((set) => {
                  'kg': set['kg'] is String ? set['kg'] as String : set['kg'].toString(),
                  'reps': set['reps'] is String ? set['reps'] as String : set['reps'].toString(),
                })
            .toList();
      });

      sessionsToSave.add({
        'exercises': exercises,
        'setControllers': serializedSets,
        'savedAt': DateTime.now().toIso8601String(),
      });
    }
    
    final key = await _getNamespacedKey(_currentWorkoutsKey);
    await prefs.setString(key, jsonEncode(sessionsToSave));
  }

  /// Loads all current in-progress workout sessions.
  static Future<List<Map<String, dynamic>>> loadCurrentWorkoutSessions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for old single session key to migrate or clear
    final oldSessionJson = prefs.getString('current_workout_session');
    if (oldSessionJson != null) {
      await prefs.remove('current_workout_session');
      try {
        final oldData = Map<String, dynamic>.from(jsonDecode(oldSessionJson));
        return [oldData]; // Migrate single to list temporarily
      } catch (e) {
        print('Error parsing old session: $e');
      }
    }

    final key = await _getNamespacedKey(_currentWorkoutsKey);
    final sessionsJson = prefs.getString(key);
    if (sessionsJson == null) return [];
    
    try {
      final List<dynamic> decodedList = jsonDecode(sessionsJson);
      final List<Map<String, dynamic>> result = [];
      
      for (final session in decodedList) {
        final data = Map<String, dynamic>.from(session);
        
        if (data['setControllers'] is Map) {
          final setControllersMap = Map<String, dynamic>.from(data['setControllers']);
          final convertedSets = <String, dynamic>{};
          
          setControllersMap.forEach((key, value) {
            convertedSets[key] = value;
          });
          
          data['setControllers'] = convertedSets;
        }
        result.add(data);
      }
      
      return result;
    } catch (e) {
      print('Error deserializing workout sessions: $e');
      return [];
    }
  }

  static Future<void> clearAllCurrentWorkoutSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_currentWorkoutsKey);
    await prefs.remove(key);
  }

  /// Saves a completed workout to local storage.
  /// [exercises] is a list of {exer_id, exer_name, sets: [{kg, reps}]}
  /// [workoutName] is an optional name for the routine
  static Future<void> saveWorkout(
    List<Map<String, dynamic>> exercises, {
    String? workoutName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_key);
    final existing = prefs.getString(key);
    final List<dynamic> all = existing != null ? jsonDecode(existing) : [];
    all.add({
      'date': DateTime.now().toIso8601String(),
      'name': workoutName,
      'exercises': exercises,
    });
    await prefs.setString(key, jsonEncode(all));
  }

  /// Returns all saved workouts, newest first.
  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_key);
    final existing = prefs.getString(key);
    if (existing == null) return [];
    final List<dynamic> all = jsonDecode(existing);
    return all.reversed
        .map((w) => Map<String, dynamic>.from(w))
        .toList();
  }

  /// Deletes a workout at the specified index (in the reversed list order).
  static Future<void> deleteWorkout(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_key);
    final existing = prefs.getString(key);
    if (existing == null) return;
    final List<dynamic> all = jsonDecode(existing);
    // Index is based on reversed list, so we need to convert it
    final actualIndex = all.length - 1 - index;
    if (actualIndex >= 0 && actualIndex < all.length) {
      all.removeAt(actualIndex);
      await prefs.setString(key, jsonEncode(all));
    }
  }
}

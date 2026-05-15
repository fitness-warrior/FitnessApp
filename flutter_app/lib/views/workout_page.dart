import 'package:flutter/material.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_storage.dart';
import '../services/workout_history_service.dart';
import '../services/streak_service.dart';
import '../services/weekly_plan_service.dart';
import '../widgets/common/navbar.dart';
import '../widgets/common/finish_button.dart';
import '../widgets/common/streak_display.dart';
import 'exercise_library_page.dart';
import 'workout_calendar_page.dart';
import '../services/user_stats_service.dart';
import '../widgets/xp_bar.dart';

class WorkoutPage extends StatefulWidget {
  final List<String>? initialRecommendationTags;
  final int initialTab;

  const WorkoutPage({
    Key? key,
    this.initialRecommendationTags,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<Map<String, dynamic>> _workoutExercises = [];
  Map<int, List<Map<String, TextEditingController>>> _setControllers = {};
  int _selectedTab = 0;
  List<Map<String, dynamic>> _savedWorkouts = [];
  bool _loadingSavedWorkouts = true;
  int _streakRefreshToken = 0;

  /// Maps routine name -> list of day names it is assigned to.
  Map<String, List<String>> _assignedRoutineDays = {};
  int _currentXP = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadSavedWorkoutSession();
    _loadSavedWorkouts();
    _loadAssignedRoutines();
    _loadXP();
    if (widget.initialRecommendationTags != null &&
        widget.initialRecommendationTags!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSearchDialogWithTags(widget.initialRecommendationTags!);
      });
    }
  }

  Future<void> _loadAssignedRoutines() async {
    // Clear old state first to prevent leakage from previous user session
    setState(() => _assignedRoutineDays = {});

    try {
      final plan = await WeeklyPlanService.getWeeklyPlan();
      if (plan != null && mounted) {
        const dayLabels = {
          'monday': 'Mon',
          'tuesday': 'Tue',
          'wednesday': 'Wed',
          'thursday': 'Thu',
          'friday': 'Fri',
          'saturday': 'Sat',
          'sunday': 'Sun',
        };
        final Map<String, List<String>> result = {};
        final weekPlan = plan['week_plan'] is Map
            ? Map<String, dynamic>.from(plan['week_plan'] as Map)
            : plan;

        weekPlan.forEach((day, names) {
          final label = dayLabels[day.toString()] ?? day.toString();
          if (names is List) {
            for (final name in names) {
              result.putIfAbsent(name.toString(), () => []).add(label);
            }
          }
        });
        setState(() => _assignedRoutineDays = result);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedWorkouts() async {
    setState(() => _loadingSavedWorkouts = true);
    try {
      // 1. Load local workouts
      final localWorkouts = (await WorkoutStorage.getWorkouts())
          .map((w) => {
                ...w,
                'source': 'local',
              })
          .toList();

      // 2. Load API workouts
      List<Map<String, dynamic>> apiWorkouts = [];
      try {
        final history = await WorkoutHistoryService.getWorkoutHistory();
        apiWorkouts = _mapApiWorkoutsToRoutines(history);
      } catch (e) {
        debugPrint('Error loading API history: $e');
      }

      // 3. Combine and deduplicate using robust UTC + Content matching
      final List<Map<String, dynamic>> combinedList = [];

      // API workouts are the source of truth
      for (var apiW in apiWorkouts) {
        combinedList.add(Map<String, dynamic>.from(apiW));
      }

      // Merge local workouts only if they don't match an API entry
      for (var localW in localWorkouts) {
        bool isDuplicate = false;
        final localDate =
            DateTime.tryParse(localW['date']?.toString() ?? '')?.toUtc() ??
                DateTime.now().toUtc();
        final localName =
            (localW['name']?.toString() ?? '').trim().toLowerCase();

        for (var apiW in apiWorkouts) {
          final apiDate =
              DateTime.tryParse(apiW['date']?.toString() ?? '')?.toUtc() ??
                  DateTime.now().toUtc();
          final apiName = (apiW['name']?.toString() ?? '').trim().toLowerCase();

          // 1. Check if names are identical and timestamps are within 60 minutes (UTC)
          final timeMatch = localName == apiName &&
              (localDate.difference(apiDate).abs().inMinutes < 60);

          if (timeMatch) {
            isDuplicate = true;
            break;
          }

          // 2. Content-based fallback: same day, same name, same exercises
          final sameDay = localDate.year == apiDate.year &&
              localDate.month == apiDate.month &&
              localDate.day == apiDate.day;
          if (sameDay && localName == apiName) {
            final localExs = localW['exercises'] as List? ?? [];
            final apiExs = apiW['exercises'] as List? ?? [];
            if (localExs.length == apiExs.length && localExs.isNotEmpty) {
              final localExNames = localExs
                  .map((e) => e['exer_name']?.toString() ?? '')
                  .join(',');
              final apiExNames =
                  apiExs.map((e) => e['exer_name']?.toString() ?? '').join(',');
              if (localExNames == apiExNames) {
                isDuplicate = true;
                break;
              }
            }
          }
        }

        if (!isDuplicate) {
          combinedList.add(Map<String, dynamic>.from(localW));
        }
      }

      // 4. Sort Oldest to Newest to assign sequential "Workout N" names
      final allWorkouts = combinedList;
      allWorkouts.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      int namelessCount = 0;
      for (var w in allWorkouts) {
        final name = (w['name']?.toString() ?? '').trim();
        if (name.isEmpty) {
          namelessCount++;
          w['name'] = 'Workout $namelessCount';
        }
      }

      // 5. Sort Newest to Oldest for display
      allWorkouts.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _savedWorkouts = allWorkouts;
        _loadingSavedWorkouts = false;
      });
    } catch (e) {
      debugPrint('Error loading saved workouts: $e');
      if (!mounted) return;
      setState(() {
        _loadingSavedWorkouts = false;
      });
    }
  }

  Future<void> _loadXP() async {
    final xp = await UserStatsService.getXP();
    if (mounted) setState(() => _currentXP = xp);
  }

  List<Map<String, dynamic>> _mapApiWorkoutsToRoutines(
    List<Map<String, dynamic>> apiHistory,
  ) {
    return apiHistory.map((workout) {
      final exercisesRaw = workout['exercises'];
      final exercisesList = exercisesRaw is List ? exercisesRaw : <dynamic>[];

      final mappedExercises = exercisesList.map((e) {
        final ex = Map<String, dynamic>.from(e as Map);
        final exerId = ex['exer_id'];
        final reps = ex['reps'] ?? 0;
        final weight = ex['weight'] ?? 0;
        final setCountRaw = ex['sets'];
        final int setCount = (setCountRaw is int)
            ? setCountRaw
            : (int.tryParse(setCountRaw?.toString() ?? '1') ?? 1);

        return {
          'exer_id': exerId,
          'exer_name': ex['name']?.toString().isNotEmpty == true
              ? ex['name']
              : ex['exer_name'] ?? 'Exercise ${exerId ?? ''}',
          'sets': List.generate(
              setCount > 0 ? setCount : 1,
              (index) => {
                    'kg': weight.toString(),
                    'reps': reps.toString(),
                  }),
        };
      }).toList();

      return {
        'id': workout['workout_id'],
        'date': workout['created_at']?.toString() ?? '1970-01-01T00:00:00Z',
        'name': workout['notes']?.toString() ?? '',
        'exercises': mappedExercises,
        'source': 'api',
      };
    }).toList();
  }

  Future<void> _loadSavedWorkoutSession() async {
    try {
      final sessions = await WorkoutStorage.loadCurrentWorkoutSessions();
      if (sessions.isEmpty) return;

      // Only load first session (single workout mode)
      final session = sessions.first;
      if (!mounted) return;

      setState(() {
        final exercises = session['exercises'] as List? ?? [];
        final savedSets = session['setControllers'] as Map? ?? {};

        _workoutExercises = exercises
            .cast<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _setControllers = <int, List<Map<String, TextEditingController>>>{};

        savedSets.forEach((indexStr, sets) {
          final index = int.tryParse(indexStr.toString()) ?? 0;
          if (sets is List && index < _workoutExercises.length) {
            final exercise = _workoutExercises[index];
            final exerType = exercise['exer_type']?.toString() ?? 'strength';
            final isCardio = exerType.toLowerCase() == 'cardio';
            _setControllers[index] = [];
            for (final set in sets) {
              final setMap = set is Map ? Map<String, dynamic>.from(set) : {};
              _setControllers[index]!.add(isCardio
                  ? {
                      'time': _createAutoSaveController(
                          initialText: setMap['time']?.toString() ?? ''),
                      'distance': _createAutoSaveController(
                          initialText: setMap['distance']?.toString() ?? ''),
                    }
                  : {
                      'kg': _createAutoSaveController(
                          initialText: setMap['kg']?.toString() ?? ''),
                      'reps': _createAutoSaveController(
                          initialText: setMap['reps']?.toString() ?? ''),
                    });
            }
          }
        });
      });
    } catch (e) {
      // // // print('Error loading workout session: $e');
    }
  }

  /// Save current workout session to persistent storage
  /// Helper method to create a TextEditingController with auto-save listener
  TextEditingController _createAutoSaveController({String initialText = ''}) {
    final controller = TextEditingController(text: initialText);
    controller.addListener(_saveCurrentWorkoutSession);
    return controller;
  }

  Future<void> _saveCurrentWorkoutSession() async {
    try {
      final serializableSets = <int, List<Map<String, String>>>{};
      _setControllers.forEach((index, sets) {
        final exercise =
            index < _workoutExercises.length ? _workoutExercises[index] : null;
        final exerType = exercise?['exer_type']?.toString() ?? 'strength';
        final isCardio = exerType.toLowerCase() == 'cardio';
        serializableSets[index] = sets
            .map((set) => isCardio
                ? {
                    'time': set['time']!.text,
                    'distance': set['distance']!.text,
                  }
                : {
                    'kg': set['kg']!.text,
                    'reps': set['reps']!.text,
                  })
            .toList();
      });

      await WorkoutStorage.saveCurrentWorkoutSessions(
        [_workoutExercises],
        [serializableSets],
      );
    } catch (e) {
      // // // print('Error saving workout session: $e');
    }
  }

  void _showWorkoutActiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        title:
            const Text('Active Workout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Please finish your current workout first.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9FFF)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addExercise(Map<String, dynamic> exercise) {
    if (exercise.isEmpty) return;
    setState(() {
      final normalizedExercise = _normalizeExercise(exercise);
      _workoutExercises.add(normalizedExercise);
      final exerType =
          normalizedExercise['exer_type']?.toString() ?? 'strength';
      final isCardio = exerType.toLowerCase() == 'cardio';
      _setControllers[_workoutExercises.length - 1] = [
        isCardio
            ? {
                'time': _createAutoSaveController(),
                'distance': _createAutoSaveController(),
              }
            : {
                'kg': _createAutoSaveController(),
                'reps': _createAutoSaveController(),
              },
      ];
    });
    _saveCurrentWorkoutSession();
  }

  Map<String, dynamic> _normalizeExercise(Map<String, dynamic> exercise) {
    final normalized = Map<String, dynamic>.from(exercise);
    // Ensure all fields have defaults
    normalized['exer_id'] = normalized['exer_id'] ?? 0;
    normalized['exer_name'] =
        (normalized['exer_name']?.toString().isNotEmpty == true
                ? normalized['exer_name']
                : normalized['name']?.toString().isNotEmpty == true
                    ? normalized['name']
                    : null) ??
            'Unknown Exercise';
    normalized['exer_descrip'] = normalized['exer_descrip']?.toString() ?? '';
    normalized['exer_body_area'] =
        normalized['exer_body_area']?.toString() ?? 'Unknown';
    normalized['exer_type'] = normalized['exer_type']?.toString() ?? 'General';
    normalized['exer_equip'] = normalized['exer_equip']?.toString() ?? 'None';
    normalized['exer_vid'] = normalized['exer_vid']?.toString() ?? '';
    return normalized;
  }

  void _removeExercise(int index) {
    if (_setControllers.containsKey(index)) {
      final exercise = _workoutExercises[index];
      final exerType = exercise['exer_type']?.toString() ?? 'strength';
      final isCardio = exerType.toLowerCase() == 'cardio';

      for (final set in _setControllers[index]!) {
        if (isCardio) {
          set['time']?.dispose();
          set['distance']?.dispose();
        } else {
          set['kg']?.dispose();
          set['reps']?.dispose();
        }
      }
      _setControllers.remove(index);
    }

    final newSetControllers = <int, List<Map<String, TextEditingController>>>{};
    int newIndex = 0;
    for (int i = 0; i < _setControllers.length + 1; i++) {
      if (i != index && _setControllers.containsKey(i)) {
        newSetControllers[newIndex] = _setControllers[i]!;
        newIndex++;
      }
    }
    _setControllers.clear();
    _setControllers.addAll(newSetControllers);

    setState(() {
      _workoutExercises.removeAt(index);
    });
    _saveCurrentWorkoutSession();
  }

  void _addSet(int exerciseIndex) {
    final exercise = exerciseIndex < _workoutExercises.length
        ? _workoutExercises[exerciseIndex]
        : null;
    final exerType = exercise?['exer_type']?.toString() ?? 'strength';
    final isCardio = exerType.toLowerCase() == 'cardio';
    setState(() {
      _setControllers[exerciseIndex]?.add(
        isCardio
            ? {
                'time': _createAutoSaveController(),
                'distance': _createAutoSaveController(),
              }
            : {
                'kg': _createAutoSaveController(),
                'reps': _createAutoSaveController(),
              },
      );
    });
    _saveCurrentWorkoutSession();
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    if ((_setControllers[exerciseIndex]?.length ?? 0) <= 1) return;
    setState(() {
      final set = _setControllers[exerciseIndex]!.removeAt(setIndex);
      final exercise = exerciseIndex < _workoutExercises.length
          ? _workoutExercises[exerciseIndex]
          : null;
      final exerType = exercise?['exer_type']?.toString() ?? 'strength';
      final isCardio = exerType.toLowerCase() == 'cardio';
      if (isCardio) {
        set['time']!.dispose();
        set['distance']!.dispose();
      } else {
        set['kg']!.dispose();
        set['reps']!.dispose();
      }
    });
    _saveCurrentWorkoutSession();
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => ExerciseSearchDialog(
        onExerciseSelected: (exercise) {
          if (mounted) {
            _addExercise(exercise);
          }
        },
      ),
    );
  }

  void _openSearchDialogWithTags(List<String> tags) {
    showDialog(
      context: context,
      builder: (context) => ExerciseSearchDialog(
        onExerciseSelected: (exercise) {
          if (mounted) {
            _addExercise(exercise);
          }
        },
        initialTags: tags,
      ),
    );
  }

  void _openGenerateDialog() {
    if (_workoutExercises.isNotEmpty) {
      _showWorkoutActiveDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => GenerateWorkoutDialog(
        onGenerate: (count, exercises, muscleGroup, equipment) {
          if (!mounted) return;

          // ✅ DO NOT POP HERE

          // Just add exercises
          for (final exercise in exercises) {
            _addExercise(exercise);
          }
        },
      ),
    );
  }

  Future<void> _deleteRoutine(int index) async {
    final workout = _savedWorkouts[index];
    final routineName = workout['name']?.toString() ?? 'Workout';
    final pageContext = context;

    // Check if this routine is assigned to any days in the weekly plan
    List<String> assignedDays = [];
    try {
      final plan = await WeeklyPlanService.getWeeklyPlan();
      if (plan != null) {
        const dayNames = {
          'monday': 'Monday',
          'tuesday': 'Tuesday',
          'wednesday': 'Wednesday',
          'thursday': 'Thursday',
          'friday': 'Friday',
          'saturday': 'Saturday',
          'sunday': 'Sunday',
        };
        final weekPlan = plan['week_plan'] is Map
            ? Map<String, dynamic>.from(plan['week_plan'] as Map)
            : plan;
        for (final entry in weekPlan.entries) {
          final value = entry.value;
          if (value is List &&
              value.map((e) => e.toString()).contains(routineName)) {
            assignedDays
                .add(dayNames[entry.key.toString()] ?? entry.key.toString());
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Routine',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$routineName"?',
              style: const TextStyle(color: Colors.grey),
            ),
            if (assignedDays.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This routine is assigned to: '
                        '${assignedDays.join(', ')}.\n'
                        'It will be removed from those days.',
                        style:
                            const TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Remove from weekly plan first if assigned
                if (assignedDays.isNotEmpty) {
                  final plan = await WeeklyPlanService.getWeeklyPlan();
                  if (plan != null) {
                    final structured = plan['week_plan'] is Map
                        ? Map<String, dynamic>.from(plan)
                        : <String, dynamic>{'week_plan': plan};
                    final weekPlan = structured['week_plan'] is Map
                        ? Map<String, dynamic>.from(
                            structured['week_plan'] as Map)
                        : <String, dynamic>{};
                    for (final day in weekPlan.keys) {
                      final names = weekPlan[day];
                      if (names is List) {
                        names.removeWhere(
                            (name) => name.toString() == routineName);
                      }
                    }
                    if (structured['routines'] is List) {
                      (structured['routines'] as List).removeWhere((routine) {
                        if (routine is Map) {
                          return routine['name']?.toString() == routineName;
                        }
                        return false;
                      });
                    }
                    structured['week_plan'] = weekPlan;
                    await WeeklyPlanService.saveWeeklyPlan(structured);
                  }
                }

                if (workout['source'] == 'local') {
                  final localWorkouts = _savedWorkouts
                      .where((w) => w['source'] == 'local')
                      .toList();
                  final localIndex = localWorkouts.indexOf(workout);
                  if (localIndex != -1) {
                    await WorkoutStorage.deleteWorkout(localIndex);
                  }
                } else if (workout['source'] == 'api') {
                  if (workout['id'] != null) {
                    final success = await WorkoutHistoryService.deleteWorkout(
                        workout['id'] as int);
                    if (!success) throw Exception('API returned failure');
                  }
                }

                await _loadSavedWorkouts();

                if (mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text('$routineName deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openRoutineDetailsDialog(
      Map<String, dynamic> workout, String routineName) {
    final exercises = workout['exercises'];
    final exerciseList = exercises is List ? exercises : [];
    final dateText = workout['date']?.toString() ?? 'Unknown date';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D0D14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$routineName Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: $dateText',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'EXERCISES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A9FFF),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    exerciseList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No exercises recorded',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : Column(
                            children: List.generate(exerciseList.length, (idx) {
                              final exercise = exerciseList[idx];
                              final exerName =
                                  exercise['exer_name'] ?? 'Unknown Exercise';
                              final sets = exercise['sets'];
                              final setsList = sets is List ? sets : [];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C2E),
                                  borderRadius: BorderRadius.circular(16),
<<<<<<< HEAD
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.05)),
=======
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> 7063d0a72c4a30019032b2b06ed3ee7c38ed9b59
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...List.generate(setsList.length, (setIdx) {
                                      final set = setsList[setIdx];
                                      final kg = set['kg']?.toString() ?? '0';
                                      final reps =
                                          set['reps']?.toString() ?? '0';
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
<<<<<<< HEAD
                                                color: Colors.white
                                                    .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(4),
=======
                                                color: Colors.white.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(4),
>>>>>>> 7063d0a72c4a30019032b2b06ed3ee7c38ed9b59
                                              ),
                                              child: Text(
                                                'Set ${setIdx + 1}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '$reps × ${kg}kg',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C1C2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
=======
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
>>>>>>> 7063d0a72c4a30019032b2b06ed3ee7c38ed9b59
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFinishDialog() {
    if (_workoutExercises.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => FinishWorkoutDialog(
        exercises: _workoutExercises,
        setControllers: _setControllers,
        onSuccess: (result) async {
          // Finish dialog handles both local save and API sync.
          setState(() {
            _workoutExercises.clear();
            _setControllers.clear();
            _streakRefreshToken++;
          });
          // Update the saved sessions
          await _saveCurrentWorkoutSession();
          // Refresh the routines list to show the newly saved workout
          await _loadSavedWorkouts();
          await _loadXP();
          StreakService.notifyStreakChanged();
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final sets in _setControllers.values) {
      for (final set in sets) {
        set['kg']?.dispose();
        set['reps']?.dispose();
        set['time']?.dispose();
        set['distance']?.dispose();
      }
    }
    super.dispose();
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF4A9FFF), Color(0xFF2979FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Workout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreakDisplay(
            compact: true,
            refreshToken: _streakRefreshToken,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedWorkouts,
        child: ListView(
          children: [
            // Segmented tabs only (no stats/XP/fire row)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTab('Tracker', 0),
                    const SizedBox(width: 6),
                    _buildTab('My Plan', 1),
                  ],
                ),
              ),
            ),
            // XP Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: XPBar(xp: _currentXP),
            ),
            // Current Workout Section
            if (_selectedTab == 0) ...[
              if (_workoutExercises.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Workout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_setControllers.values.fold<int>(0, (sum, sets) => sum + sets.length)} sets',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._workoutExercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        final sets = _setControllers[index] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C2E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      exercise['exer_name']?.toString() ??
                                          'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.redAccent),
                                    onPressed: () => _removeExercise(index),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(sets.length, (setIndex) {
                                final exerType =
                                    exercise['exer_type']?.toString() ??
                                        'strength';
                                final isCardio =
                                    exerType.toLowerCase() == 'cardio';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text('Set ${setIndex + 1}:',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12)),
                                      const SizedBox(width: 8),
                                      if (isCardio) ...[
                                        Expanded(
                                          child: TextField(
                                            controller: sets[setIndex]['time'],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'time (min)',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF252538),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              errorText: _validatePositive(
                                                  sets[setIndex]['time']!.text,
                                                  'Time'),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: sets[setIndex]
                                                ['distance'],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'distance (km)',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF252538),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              errorText: _validatePositive(
                                                  sets[setIndex]['distance']!
                                                      .text,
                                                  'Distance'),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        )
                                      ] else ...[
                                        Expanded(
                                          child: TextField(
                                            controller: sets[setIndex]['kg'],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'kg',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF252538),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              errorText: _validatePositive(
                                                  sets[setIndex]['kg']!.text,
                                                  'kg'),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: sets[setIndex]['reps'],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'reps',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF252538),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              errorText: _validatePositive(
                                                  sets[setIndex]['reps']!.text,
                                                  'reps'),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        )
                                      ],
                                      if (sets.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              size: 18,
                                              color: Colors.redAccent),
                                          onPressed: () =>
                                              _removeSet(index, setIndex),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              TextButton.icon(
                                onPressed: () => _addSet(index),
                                icon: const Icon(Icons.add,
                                    size: 16, color: Color(0xFF4A9FFF)),
                                label: const Text('Add Set',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4A9FFF))),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openFinishDialog,
                          icon: const Icon(Icons.check),
                          label: const Text('Finish & Save Workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // ── Action Cards ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildActionCard(
                  label: 'Exercise Library',
                  icon: Icons.fitness_center,
                  iconColor: const Color(0xFF4A9FFF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExerciseLibraryPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // ── New Workout ───────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'New Workout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildActionCard(
                  label: 'Start Empty Workout',
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFFFFB74D),
                  onTap: _openSearchDialog,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildActionCard(
                  label: 'Generate Workout',
                  icon: Icons.autorenew_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  onTap: _openGenerateDialog,
                ),
              ),
              const SizedBox(height: 28),
              // ── Routines ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Routines',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            color: Colors.grey[400], size: 22),
                        const SizedBox(width: 14),
                        Icon(Icons.add, color: Colors.grey[400], size: 22),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRoutinesSection(),
              ),
              const SizedBox(height: 100),
            ] else ...[
              WorkoutCalendarPage(
                savedWorkouts: _savedWorkouts,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onRefresh: () {
                  _loadSavedWorkouts();
                  _loadXP();
                },
              ),
              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
      floatingActionButton: _workoutExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openSearchDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              backgroundColor: const Color(0xFF4A9FFF),
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: _workoutExercises.isNotEmpty
          ? Stack(
              alignment: Alignment.topCenter,
              children: [
                const AppBottomNavBar(currentIndex: 0),
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: FinishButton(onPressed: _openFinishDialog),
                ),
              ],
            )
          : const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _validatePositive(String value, String fieldName) {
    if (value.isEmpty) return null;
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Must be a valid number';
    if (numValue <= 0) return '$fieldName must be > 0';
    return null;
  }

  Widget _buildActionCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesSection() {
    if (_loadingSavedWorkouts) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // "My Routines (N)" expandable header
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            collapsedIconColor: Colors.white,
            iconColor: const Color(0xFF4A9FFF),
            title: (() {
              // Calculate unique routines count for the header
              final Set<String> uniqueNames = {};
              int uniqueCount = 0;
              for (var w in _savedWorkouts) {
                String name = (w['name']?.toString() ?? '').trim();
                const dayNames = [
                  'monday',
                  'tuesday',
                  'wednesday',
                  'thursday',
                  'friday',
                  'saturday',
                  'sunday'
                ];
                if (dayNames.contains(name.toLowerCase())) name = '';

                if (name.isEmpty) {
                  uniqueCount++; // Nameless ones are always unique in our current logic
                } else if (!uniqueNames.contains(name.toLowerCase())) {
                  uniqueNames.add(name.toLowerCase());
                  uniqueCount++;
                }
              }
              return Text(
                'My Routines ($uniqueCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );
            })(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, color: Colors.white),
              ],
            ),
            children: _savedWorkouts.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No saved routines yet.\nFinish a workout to save it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    )
                  ]
                : (() {
                    // Get unique routines by name, keeping only the newest one (since list is already sorted newest first)
                    final Map<String, Map<String, dynamic>> uniqueRoutinesMap =
                        {};
                    final List<Map<String, dynamic>> displayList = [];

                    for (var workout in _savedWorkouts) {
                      String rawName =
                          (workout['name']?.toString() ?? '').trim();

                      // Filter out day names to treat them as nameless
                      const dayNames = [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday',
                        'sunday'
                      ];
                      if (dayNames.contains(rawName.toLowerCase())) {
                        rawName = '';
                      }

                      if (rawName.isEmpty) {
                        // Nameless workouts are always shown uniquely
                        displayList.add(workout);
                      } else {
                        if (!uniqueRoutinesMap
                            .containsKey(rawName.toLowerCase())) {
                          uniqueRoutinesMap[rawName.toLowerCase()] = workout;
                          displayList.add(workout);
                        }
                      }
                    }

                    return displayList.map((workout) {
                      final exercises = workout['exercises'];
                      final exerciseList = exercises is List ? exercises : [];
                      final dateText = workout['date']?.toString() ?? '';

                      // Numbering based on original list position for consistency
                      final originalIdx = _savedWorkouts.indexOf(workout);
                      final workoutNumber = _savedWorkouts.length - originalIdx;

                      String routineName =
                          (workout['name']?.toString() ?? '').trim();
                      const dayNames = [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday',
                        'sunday'
                      ];
                      if (dayNames.contains(routineName.toLowerCase()) ||
                          routineName.isEmpty) {
                        routineName = 'Workout $workoutNumber';
                      }

                      final assignedDays =
                          _assignedRoutineDays[routineName] ?? [];
                      final isAssigned = assignedDays.isNotEmpty;

                      return GestureDetector(
                        onTap: () =>
                            _openRoutineDetailsDialog(workout, routineName),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isAssigned
                                ? const Color(0xFF1E1A3A)
                                : const Color(0xFF252538),
                            borderRadius: BorderRadius.circular(12),
                            border: isAssigned
                                ? Border.all(
                                    color: const Color(0xFF7C5CBF), width: 1.2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            routineName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (isAssigned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
<<<<<<< HEAD
                                              color: const Color(0xFF7C5CBF)
                                                  .withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF7C5CBF),
                                                  width: 1),
=======
                                              color: const Color(0xFF7C5CBF).withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF7C5CBF), width: 1),
>>>>>>> 7063d0a72c4a30019032b2b06ed3ee7c38ed9b59
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 11,
                                                    color: Color(0xFFB39DDB)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  assignedDays.join(', '),
                                                  style: const TextStyle(
                                                      color: Color(0xFFB39DDB),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${exerciseList.length} exercises  •  $dateText',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteRoutine(originalIdx),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  })(),
          ),
        ),
      ],
    );
  }
}

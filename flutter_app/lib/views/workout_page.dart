import 'package:flutter/material.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_storage.dart';
import '../services/workout_history_service.dart';
import '../services/streak_service.dart';
import '../widgets/common/navbar.dart';
import '../widgets/common/finish_button.dart';
import '../widgets/common/streak_display.dart';
import 'exercise_library_page.dart';
import 'workout_calendar_page.dart';

class WorkoutPage extends StatefulWidget {
  final List<String>? initialRecommendationTags;

  const WorkoutPage({Key? key, this.initialRecommendationTags})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadSavedWorkoutSession();
    _loadSavedWorkouts();
    // If launched with recommendation tags, open the search dialog after build
    if (widget.initialRecommendationTags != null &&
        widget.initialRecommendationTags!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSearchDialogWithTags(widget.initialRecommendationTags!);
      });
    }
  }

  Future<void> _loadSavedWorkouts() async {
    try {
      final localWorkouts = (await WorkoutStorage.getWorkouts())
          .map((w) => {
                ...w,
                'source': 'local',
              })
          .toList();

      List<Map<String, dynamic>> apiWorkouts = [];
      try {
        final apiHistory = await WorkoutHistoryService.getWorkoutHistory();
        apiWorkouts = _mapApiWorkoutsToRoutines(apiHistory);
      } catch (e) {
        print('Error fetching API workouts: $e');
      }

      final List<Map<String, dynamic>> combined = [];
      final Set<String> seenHashes = {};

      // Merge and deduplicate
      for (final w in [...localWorkouts, ...apiWorkouts]) {
        final name = w['name']?.toString() ?? 'Workout';
        final dateStr = w['date']?.toString() ?? '';
        final datePrefix =
            dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
        final exercises = w['exercises'] as List? ?? [];

        // Hash based on name, day, and exercise count to reliably deduplicate
        final hash = '$name-$datePrefix-${exercises.length}';

        if (!seenHashes.contains(hash)) {
          seenHashes.add(hash);
          combined.add(w);
        }
      }

      combined.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // Newest first
      });

      if (!mounted) return;
      setState(() {
        _savedWorkouts = combined;
        _loadingSavedWorkouts = false;
      });
    } catch (e) {
      print('Error loading saved workouts: $e');
      if (!mounted) return;
      setState(() {
        _loadingSavedWorkouts = false;
      });
    }
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
          'exer_name': ex['exer_name'] ?? 'Exercise ${exerId ?? ''}',
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
        'date': workout['created_at']?.toString() ??
            DateTime.now().toIso8601String(),
        'name': workout['notes']?.toString().isNotEmpty == true
            ? workout['notes']
            : 'Workout ${workout['workout_id'] ?? ''}',
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
                      'calories': _createAutoSaveController(
                          initialText: setMap['calories']?.toString() ?? ''),
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
      print('Error loading workout session: $e');
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
                    'calories': set['calories']!.text,
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
      print('Error saving workout session: $e');
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
                'calories': _createAutoSaveController(),
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
        normalized['exer_name']?.toString() ?? 'Unknown Exercise';
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
          set['calories']?.dispose();
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
                'calories': _createAutoSaveController(),
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
        set['calories']!.dispose();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        title: const Text(
          'Delete Routine',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$routineName"?',
          style: const TextStyle(color: Colors.grey),
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
                if (workout['source'] == 'local') {
                  final localWorkouts = _savedWorkouts
                      .where((w) => w['source'] == 'local')
                      .toList();
                  final localIndex = localWorkouts.indexOf(workout);
                  if (localIndex != -1) {
                    await WorkoutStorage.deleteWorkout(localIndex);
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
                print('Error deleting workout: $e');
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
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
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
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: $dateText',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(setsList.length, (setIdx) {
                                      final set = setsList[setIdx];
                                      final kg = set['kg']?.toString() ?? '0';
                                      final reps =
                                          set['reps']?.toString() ?? '0';
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Set ${setIdx + 1}: $reps × ${kg}kg',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
        set['calories']?.dispose();
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
                              color: Colors.orange.withOpacity(0.15),
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
                                color: Colors.black.withOpacity(0.3),
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
                                                ['calories'],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'calories',
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
                                                  sets[setIndex]['calories']!
                                                      .text,
                                                  'Calories'),
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
              color: Colors.black.withOpacity(0.35),
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
                color: iconColor.withOpacity(0.15),
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
            title: Text(
              'My Routines (${_savedWorkouts.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                : _savedWorkouts.asMap().entries.map((entry) {
                    final workout = entry.value;
                    final idx = entry.key;
                    final exercises = workout['exercises'];
                    final exerciseList = exercises is List ? exercises : [];
                    final dateText = workout['date']?.toString() ?? '';
                    final workoutNumber = _savedWorkouts.length - idx;
                    final routineName =
                        workout['name']?.toString() ?? 'Workout $workoutNumber';

                    return GestureDetector(
                      onTap: () =>
                          _openRoutineDetailsDialog(workout, routineName),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252538),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routineName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${exerciseList.length} exercises  •  $dateText',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteRoutine(idx),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../data/exercise_db.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_service.dart';
import '../services/workout_storage.dart';
import '../widgets/common/header.dart';
import '../widgets/common/navbar.dart';
import '../widgets/common/finish_button.dart';
import 'profile_page.dart';

class WorkoutPage extends StatefulWidget {
  final List<String>? initialRecommendationTags;

  const WorkoutPage({Key? key, this.initialRecommendationTags})
      : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<Map<String, dynamic>> _workoutExercises = [];
  final Map<int, List<Map<String, TextEditingController>>> _setControllers = {};
  int _selectedTab = 0;
  Map<String, dynamic>? _placeholderExercise;
  bool _isLoadingPlaceholder = true;
  List<Map<String, dynamic>> _savedWorkouts = [];
  bool _loadingSavedWorkouts = true;

  @override
  void initState() {
    super.initState();
    _loadPlaceholderExercise();
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
      final workouts = await WorkoutStorage.getWorkouts();
      if (!mounted) return;
      setState(() {
        _savedWorkouts = workouts;
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

  /// Load previously saved workout session (exercises and their set data)
  Future<void> _loadSavedWorkoutSession() async {
    try {
      final session = await WorkoutStorage.loadCurrentWorkoutSession();
      if (session == null) return;

      if (!mounted) return;
      setState(() {
        // Restore exercises
        final exercises = session['exercises'];
        if (exercises is List) {
          _workoutExercises.addAll(
            exercises.cast<Map<String, dynamic>>().map((e) {
              return Map<String, dynamic>.from(e);
            }),
          );
        }

        // Restore set controllers with saved values
        final savedSets = session['setControllers'];
        if (savedSets is Map) {
          savedSets.forEach((indexStr, sets) {
            final index = int.tryParse(indexStr.toString()) ?? 0;
            if (sets is List) {
              _setControllers[index] = [];
              for (final set in sets) {
                final setMap = set is Map ? Map<String, dynamic>.from(set) : {};
                _setControllers[index]!.add({
                  'kg': _createAutoSaveController(
                    initialText: setMap['kg']?.toString() ?? '',
                  ),
                  'reps': _createAutoSaveController(
                    initialText: setMap['reps']?.toString() ?? '',
                  ),
                });
              }
            }
          });
        }
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
      // Build serializable set data (convert TextEditingController values to strings)
      final serializableSets = <int, List<Map<String, String>>>{};
      _setControllers.forEach((index, sets) {
        serializableSets[index] = sets
            .map((set) => {
                  'kg': set['kg']!.text,
                  'reps': set['reps']!.text,
                })
            .toList();
      });

      await WorkoutStorage.saveCurrentWorkoutSession(
        _workoutExercises,
        serializableSets,
      );
    } catch (e) {
      print('Error saving workout session: $e');
    }
  }

  Future<void> _loadPlaceholderExercise() async {
    try {
      final exercises = await ExerciseDb.instance.listExercises().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Exercise loading timed out');
            },
          );
      if (mounted) {
        setState(() {
          _placeholderExercise = exercises.isNotEmpty
              ? exercises.first
              : {
                  'exer_name': 'Sample Exercise',
                  'exer_descrip': 'No exercises available',
                  'exer_vid': '',
                };
          _isLoadingPlaceholder = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _placeholderExercise = {
            'exer_name': 'Error Loading Exercises',
            'exer_descrip': 'Tap the search button to browse exercises manually',
            'exer_vid': '',
          };
          _isLoadingPlaceholder = false;
        });
      }
    }
  }

  void _addExercise() {
    if (_placeholderExercise == null) return;
    setState(() {
      final normalizedExercise = _normalizeExercise(_placeholderExercise!);
      _workoutExercises.add(normalizedExercise);
      // Start each exercise with one empty set
      _setControllers[_workoutExercises.length - 1] = [
        {
          'kg': _createAutoSaveController(),
          'reps': _createAutoSaveController(),
        },
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Added ${_placeholderExercise!['exer_name']} to workout!'),
        duration: const Duration(seconds: 2),
      ),
    );
    _saveCurrentWorkoutSession();
  }

  Map<String, dynamic> _normalizeExercise(Map<String, dynamic> exercise) {
    final normalized = Map<String, dynamic>.from(exercise);
    // Ensure all fields have defaults
    normalized['exer_id'] = normalized['exer_id'] ?? 0;
    normalized['exer_name'] = normalized['exer_name']?.toString() ?? 'Unknown Exercise';
    normalized['exer_descrip'] = normalized['exer_descrip']?.toString() ?? '';
    normalized['exer_body_area'] = normalized['exer_body_area']?.toString() ?? 'Unknown';
    normalized['exer_type'] = normalized['exer_type']?.toString() ?? 'General';
    normalized['exer_equip'] = normalized['exer_equip']?.toString() ?? 'None';
    normalized['exer_vid'] = normalized['exer_vid']?.toString() ?? '';
    return normalized;
  }

  void _removeExercise(int index) {
    // Dispose controllers for this exercise
    if (_setControllers.containsKey(index)) {
      for (final set in _setControllers[index]!) {
        set['kg']!.dispose();
        set['reps']!.dispose();
      }
      _setControllers.remove(index);
    }
    setState(() {
      _workoutExercises.removeAt(index);
    });
    _saveCurrentWorkoutSession();
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      _setControllers[exerciseIndex]?.add(
        {
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
      set['kg']!.dispose();
      set['reps']!.dispose();
    });
    _saveCurrentWorkoutSession();
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => ExerciseSearchDialog(
        onExerciseSelected: (exercise) {
          if (mounted) {
            setState(() {
              _placeholderExercise = exercise;
            });
            _addExercise();
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
            setState(() {
              _placeholderExercise = exercise;
            });
            _addExercise();
          }
        },
        initialTags: tags,
      ),
    );
  }

  void _openGenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => GenerateWorkoutDialog(
        onGenerate: (count, exercises) {
          if (mounted) {
            for (final exercise in exercises) {
              setState(() {
                _placeholderExercise = exercise;
              });
              _addExercise();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Generated ${exercises.length} exercises!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
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
          // Submit the completed workout to the backend
          try {
            final exercisesWithSets = List.generate(
              _workoutExercises.length,
              (i) {
                final sets = _setControllers[i] ?? [];
                return {
                  ..._workoutExercises[i],
                  'sets': List.generate(
                      sets.length,
                      (s) => {
                            'kg': double.tryParse(sets[s]['kg']!.text) ?? 0,
                            'reps': int.tryParse(sets[s]['reps']!.text) ?? 0,
                          }),
                };
              },
            );
            await WorkoutService.submitWorkout(exercisesWithSets);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Warning: Could not save workout: $e')),
              );
            }
          }
          setState(() {
            _workoutExercises.clear();
            _setControllers.clear();
          });
          // Clear the saved session after completing workout
          await WorkoutStorage.clearCurrentWorkoutSession();
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final sets in _setControllers.values) {
      for (final set in sets) {
        set['kg']!.dispose();
        set['reps']!.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: HeaderWithDropdown(
          title: 'My Workout',
          onMenuSelected: (value) {
            final route = '/${value.toLowerCase().replaceAll(' ', '_')}';
            final routes = {'/my_workout', '/my_meal'};
            if (routes.contains(route)) {
              Navigator.of(context).pushReplacementNamed(route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value coming soon')),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _isLoadingPlaceholder ? null : _openSearchDialog,
            tooltip: 'Search Exercises',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _isLoadingPlaceholder ? null : _openGenerateDialog,
            tooltip: 'Generate Workout',
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedWorkouts,
        child: ListView(
          children: [
            // Top stats row + segmented tabs (Step 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.person, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lv.1',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: 0.25,
                                        minHeight: 8,
                                        color: const Color(0xFF4A9FFF),
                                        backgroundColor:
                                            Colors.blue.withOpacity(0.12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.local_fire_department,
                                    color: Colors.orange),
                                SizedBox(width: 6),
                                Text('1', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.public, color: Color(0xFF4A9FFF)),
                                SizedBox(width: 6),
                                Text('200', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? const Color(0xFF4A9FFF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Tracker',
                                  style: TextStyle(
                                    color: _selectedTab == 0
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? const Color(0xFF4A9FFF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'My Plan',
                                  style: TextStyle(
                                    color: _selectedTab == 1
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Current/In-Progress Workout Section
            if (_workoutExercises.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Workout',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add exercises and set your reps/weight',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor:
                                  Colors.orange.withValues(alpha: 0.12),
                              child: Text(
                                '${_workoutExercises.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._workoutExercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          final sets = _setControllers[index] ?? [];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise['exer_name']
                                                  ?.toString() ??
                                              'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 18),
                                        onPressed: () =>
                                            _removeExercise(index),
                                        color: Colors.red,
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(sets.length, (setIndex) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text('Set ${setIndex + 1}:',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: sets[setIndex]
                                                  ['kg'],
                                              decoration: InputDecoration(
                                                labelText: 'kg',
                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.all(8),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: sets[setIndex]
                                                  ['reps'],
                                              decoration: InputDecoration(
                                                labelText: 'reps',
                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.all(8),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          if (sets.length > 1)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle,
                                                  size: 18),
                                              onPressed: () => _removeSet(
                                                  index, setIndex),
                                              color: Colors.red,
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => _addSet(index),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Set',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openFinishDialog,
                                icon: const Icon(Icons.check),
                                label: const Text('Finish & Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // Saved Workouts History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_loadingSavedWorkouts)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_savedWorkouts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No saved workouts yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _savedWorkouts.asMap().entries.map((entry) {
                    final workout = entry.value;
                    final index = entry.key;
                    final dateText = workout['date']?.toString() ?? 'Unknown';
                    final exercises = workout['exercises'];
                    final exerciseList =
                        exercises is List ? exercises : const [];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        title: Text(
                          'Workout ${_savedWorkouts.length - index}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(dateText, style: const TextStyle(fontSize: 12)),
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.blue.withValues(alpha: 0.12),
                          child: Text(
                            '${exerciseList.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        children: [
                          if (exerciseList.isEmpty)
                            const Text('No exercises recorded')
                          else
                            ...exerciseList.map((exercise) {
                              final exerciseMap = exercise is Map
                                  ? Map<String, dynamic>.from(exercise)
                                  : <String, dynamic>{};
                              final name = exerciseMap['exer_name']
                                      ?.toString() ??
                                  'Exercise';
                              final sets = exerciseMap['sets'];
                              final setList =
                                  sets is List ? sets : const [];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        setList.isEmpty
                                            ? 'No sets'
                                            : setList.map((set) {
                                                final setMap = set is Map
                                                    ? Map<String, dynamic>
                                                        .from(set)
                                                    : <String, dynamic>{};
                                                return '${setMap['reps'] ?? '-'} reps x ${setMap['kg'] ?? '-'} kg';
                                              }).join(' | '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearchDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
}

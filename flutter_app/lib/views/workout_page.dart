import 'package:flutter/material.dart';
import '../data/exercise_db.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_service.dart';
import '../services/workout_storage.dart';
import '../widgets/common/navbar.dart';
import '../widgets/common/finish_button.dart';
import 'exercise_library_page.dart';
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
          // Refresh the routines list to show the newly saved workout
          await _loadSavedWorkouts();
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
            // Current/In-Progress Workout Section
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
                            '${_workoutExercises.length} exercises',
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
                                    exercise['exer_name']?.toString() ?? 'Unknown',
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
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text('Set ${setIndex + 1}:',
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: sets[setIndex]['kg'],
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'kg',
                                          labelStyle: TextStyle(color: Colors.grey[500]),
                                          filled: true,
                                          fillColor: const Color(0xFF252538),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(8),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: sets[setIndex]['reps'],
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'reps',
                                          labelStyle: TextStyle(color: Colors.grey[500]),
                                          filled: true,
                                          fillColor: const Color(0xFF252538),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(8),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    if (sets.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            size: 18, color: Colors.redAccent),
                                        onPressed: () => _removeSet(index, setIndex),
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
                                      fontSize: 12, color: Color(0xFF4A9FFF))),
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
                        label: const Text('Finish & Save'),
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
                    MaterialPageRoute(builder: (_) => const ExerciseLibraryPage()),
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
                      Icon(Icons.folder_outlined, color: Colors.grey[400], size: 22),
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
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    return Container(
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
                                  'Workout ${_savedWorkouts.length - idx}',
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
                          Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

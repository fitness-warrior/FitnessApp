import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Map<String, dynamic>? _placeholderExercise;
  bool _isLoadingPlaceholder = true;

  @override
  void initState() {
    super.initState();
    _loadPlaceholderExercise();
    _loadSavedWorkoutSession();
    // If launched with recommendation tags, open the search dialog after build
    if (widget.initialRecommendationTags != null &&
        widget.initialRecommendationTags!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSearchDialogWithTags(widget.initialRecommendationTags!);
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
                  'kg': TextEditingController(
                    text: setMap['kg']?.toString() ?? '',
                  ),
                  'reps': TextEditingController(
                    text: setMap['reps']?.toString() ?? '',
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
        {'kg': TextEditingController(), 'reps': TextEditingController()},
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
        {'kg': TextEditingController(), 'reps': TextEditingController()},
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

  Future<void> _openExerciseVideo(String? videoUrl) async {
    if (videoUrl == null || videoUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video available for this exercise.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid video URL.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the exercise video.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
      body: Column(
        children: [
          Expanded(
            child: _workoutExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises added yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the search icon to add exercises',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workoutExercises.length,
                    itemBuilder: (context, index) {
                      try {
                        final exercise = _workoutExercises[index];
                        final sets = _setControllers[index] ?? [];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exercise['exer_name']?.toString() ?? 'Unknown Exercise',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeExercise(index),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(sets.length, (setIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text('Set ${setIndex + 1}:'),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: sets[setIndex]['kg'],
                                          decoration: const InputDecoration(
                                            labelText: 'Weight (kg)',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: sets[setIndex]['reps'],
                                          decoration: const InputDecoration(
                                            labelText: 'Reps',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: sets.length > 1
                                            ? () => _removeSet(index, setIndex)
                                            : null,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              TextButton.icon(
                                onPressed: () => _addSet(index),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Set'),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'How To Do It',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _openExerciseVideo(
                                  exercise['exer_vid'] as String?,
                                ),
                                icon: const Icon(Icons.play_circle_outline),
                                label: const Text('Watch Exercise Video'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 44),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      } catch (e) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Error displaying exercise',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  e.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _removeExercise(index),
                                  child: const Text('Remove Exercise'),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
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

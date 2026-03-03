import 'package:flutter/material.dart';
import '../data/exercise_db.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_service.dart';
import '../widgets/common/header.dart';
import '../widgets/common/footer.dart';

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
    // If launched with recommendation tags, open the search dialog after build
    if (widget.initialRecommendationTags != null &&
        widget.initialRecommendationTags!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSearchDialogWithTags(widget.initialRecommendationTags!);
      });
    }
  }

  Future<void> _loadPlaceholderExercise() async {
    try {
      final exercises = await ExerciseDb.instance.listExercises();
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
    } catch (e) {
      setState(() {
        _placeholderExercise = {
          'exer_name': 'Sample Exercise',
          'exer_descrip': 'Error loading exercises: $e',
          'exer_vid': '',
        };
        _isLoadingPlaceholder = false;
      });
    }
  }

  void _addExercise() {
    if (_placeholderExercise == null) return;
    setState(() {
      _workoutExercises.add(Map.from(_placeholderExercise!));
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
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      _setControllers[exerciseIndex]?.add(
        {'kg': TextEditingController(), 'reps': TextEditingController()},
      );
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    if ((_setControllers[exerciseIndex]?.length ?? 0) <= 1) return;
    setState(() {
      final set = _setControllers[exerciseIndex]!.removeAt(setIndex);
      set['kg']!.dispose();
      set['reps']!.dispose();
    });
  }

  void _openSearchDialog() async {
    final selectedExercise = await showDialog(
      context: context,
      builder: (context) => ExerciseSearchDialog(
        onExerciseSelected: (exercise) {
          Navigator.pop(context, exercise);
        },
      ),
    );

    if (selectedExercise != null) {
      setState(() {
        _placeholderExercise = selectedExercise;
      });
      _addExercise();
    }
  }

  void _openSearchDialogWithTags(List<String> tags) async {
    final selectedExercise = await showDialog(
      context: context,
      builder: (context) => ExerciseSearchDialog(
        onExerciseSelected: (exercise) {
          Navigator.pop(context, exercise);
        },
        initialTags: tags,
      ),
    );

    if (selectedExercise != null) {
      setState(() {
        _placeholderExercise = selectedExercise;
      });
      _addExercise();
    }
  }

  void _openGenerateDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => GenerateWorkoutDialog(
        onGenerate: (count, exercises) {
          Navigator.pop(context, {'count': count, 'exercises': exercises});
        },
      ),
    );

    if (result != null) {
      final exercises = result['exercises'] as List<Map<String, dynamic>>;
      for (final exercise in exercises) {
        setState(() {
          _placeholderExercise = exercise;
        });
        _addExercise();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${exercises.length} exercises!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
            Navigator.of(context).pushReplacementNamed(
                '/${value.toLowerCase().replaceAll(' ', '_')}');
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
                                      exercise['exer_name'] ?? 'Unknown',
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_workoutExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _openFinishDialog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Finish Workout'),
              ),
            ),
          const ResponsiveFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearchDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Exercise',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

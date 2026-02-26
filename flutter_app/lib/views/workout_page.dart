import 'package:flutter/material.dart';
import '../data/exercise_db.dart';
import '../dialogs/excercise_search_dialog.dart';
import '../dialogs/generate_workout_dialog.dart';
import '../dialogs/finish_workout_dialog.dart';
import '../services/workout_service.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

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
  }

  Future<void> _loadPlaceholderExercise() async {
    try {
      final exercises = await ExerciseDb.instance.listExercises();
      setState(() {
        _placeholderExercise = exercises.isNotEmpty
            ? exercises.first
            : {
                'exer_name': 'Sample Exercise',
                'exer_descrip': 'No exercises in database yet.',
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
            content: Text('Added ${exercises.length} exercises to your workout!'),
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
        onSuccess: (result) {
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
        title: const Text('My Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Exercises',
            onPressed: _openSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Generate Workout',
            onPressed: _openGenerateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add Exercise',
            onPressed: _isLoadingPlaceholder ? null : _addExercise,
          ),
        ],
      ),
      body: _workoutExercises.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No exercises in your workout yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add an exercise',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoadingPlaceholder ? null : _addExercise,
                    icon: const Icon(Icons.add),
                    label: Text(
                        _isLoadingPlaceholder ? 'Loading...' : 'Add Exercise'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _workoutExercises.length,
              itemBuilder: (context, index) {
                final exercise = _workoutExercises[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          '${index + 1}. ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exercise['exer_name'] ?? 'Unknown Exercise',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeExercise(index),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sets header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sets',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  tooltip: 'Add Set',
                                  onPressed: () => _addSet(index),
                                ),
                              ],
                            ),
                            // One row per set
                            if (_setControllers[index] != null)
                              ...List.generate(
                                _setControllers[index]!.length,
                                (setIndex) {
                                  final ctrl =
                                      _setControllers[index]![setIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${setIndex + 1}.',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // KG field
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: ctrl['kg'],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'KG',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // REPS field
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: ctrl['reps'],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'REPS',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // Remove set button
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          tooltip: 'Remove Set',
                                          onPressed: (_setControllers[index]
                                                          ?.length ??
                                                      0) >
                                                  1
                                              ? () =>
                                                  _removeSet(index, setIndex)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const Divider(height: 24),
                            // Description
                            if (exercise['exer_descrip'] != null &&
                                exercise['exer_descrip']
                                    .toString()
                                    .isNotEmpty) ...[
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exercise['exer_descrip'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Video
                            if (exercise['exer_vid'] != null &&
                                exercise['exer_vid'].toString().isNotEmpty) ...[
                              const Text(
                                'Video Guidance',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Video: ${exercise['exer_vid']}'),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blue, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          exercise['exer_vid'],
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _workoutExercises.isNotEmpty
          ? FloatingActionButton(
              onPressed: _openFinishDialog,
              backgroundColor: Colors.green,
              tooltip: 'Finish Workout',
              child: const Icon(Icons.check_circle),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

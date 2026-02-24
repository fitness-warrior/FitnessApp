import 'package:flutter/material.dart';
import '../data/exercise_db.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<Map<String, dynamic>> _workoutExercises = [];
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
    setState(() {
      _workoutExercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout'),
        actions: [
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
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Sets coming in next step...'),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _workoutExercises.isNotEmpty
          ? FloatingActionButton(
              onPressed: _isLoadingPlaceholder ? null : _addExercise,
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

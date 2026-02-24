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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout'),
      ),
      body: const Center(
        child: Text('Workout Page - Step 1 Complete'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../data/exercise_db.dart';

class ExerciseDropdown extends StatefulWidget {
  final Function(Map<String, dynamic>?) onExerciseSelected;

  const ExerciseDropdown({
    Key? key,
    required this.onExerciseSelected,
  }) : super(key: key);

  @override
  State<ExerciseDropdown> createState() => _ExerciseDropdownState();
}

class _ExerciseDropdownState extends State<ExerciseDropdown> {
  List<Map<String, dynamic>> _exercises = [];
  Map<String, dynamic>? _selectedExercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseDb.instance.listExercises();
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercises: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

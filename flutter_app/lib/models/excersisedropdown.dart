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
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

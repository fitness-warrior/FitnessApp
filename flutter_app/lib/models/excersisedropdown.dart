import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

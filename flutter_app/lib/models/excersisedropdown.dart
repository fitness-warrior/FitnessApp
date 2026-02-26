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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_exercises.isEmpty) {
      return const Center(
        child: Text('No exercises available'),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedExercise,
      decoration: InputDecoration(
        labelText: 'Select Exercise',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: const Text('Choose an exercise'),
      isExpanded: true,
      items: _exercises.map((exercise) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: exercise,
          child: Text(
            exercise['exer_name'] ?? 'Unknown Exercise',
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (Map<String, dynamic>? value) {
        setState(() {
          _selectedExercise = value;
        });
        widget.onExerciseSelected(value);
      },
    );
  }
}

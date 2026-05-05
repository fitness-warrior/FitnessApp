import 'package:flutter/material.dart';
import '../services/exercise_service.dart';

class GenerateWorkoutDialog extends StatefulWidget {
  final Function(int, List<Map<String, dynamic>>, String, String) onGenerate;

  const GenerateWorkoutDialog({
    Key? key,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<GenerateWorkoutDialog> createState() => _GenerateWorkoutDialogState();
}

class _GenerateWorkoutDialogState extends State<GenerateWorkoutDialog> {
  String? _selectedMuscleGroup;
  String? _selectedEquipmentType;
  bool _isLoading = false;
  String? _error;

  final Map<String, List<String>> _muscleGroupMapping = {
    'Chest': ['Chest'],
    'Back': ['Back'],
    'Legs': ['Legs', 'Quadriceps', 'Hamstrings', 'Calves', 'Glutes'],
    'Arms': ['Arms', 'Biceps', 'Triceps'],
    'Full Body': [
      'Chest',
      'Back',
      'Shoulders',
      'Triceps',
      'Biceps',
      'Quadriceps',
      'Hamstrings',
      'Calves',
      'Glutes'
    ],
  };

  final Map<String, List<String>> _equipmentTypeMapping = {
    'At Home': ['Bodyweight', 'Dumbbells'],
    'Gym': ['Machine'],
    'Cardio': ['Cardio'],
    'Dumbbells': ['Dumbbells'],
  };

  Future<void> _generateWorkout() async {
    if (_selectedMuscleGroup == null) {
      setState(() => _error = 'Select a muscle group');
      return;
    }

    if (_selectedEquipmentType == null) {
      setState(() => _error = 'Select equipment type');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allExercises = await ExerciseService.listExercises();

      final targetAreas = _muscleGroupMapping[_selectedMuscleGroup]!;
      final targetEquipment = _equipmentTypeMapping[_selectedEquipmentType]!;

      final filtered = allExercises.where((e) {
        final area = (e['exer_body_area'] ?? '').toString().toLowerCase();
        final equip = (e['exer_equip'] ?? '').toString().toLowerCase();

        return targetAreas.any((a) => area.contains(a.toLowerCase())) &&
            targetEquipment.any((t) => equip.contains(t.toLowerCase()));
      }).toList();

      if (filtered.isEmpty) {
        setState(() {
          _error = 'No exercises found';
          _isLoading = false;
        });
        return;
      }

      filtered.shuffle();
      final generated = filtered.take(6).toList();

      // 👉 Loading delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 👉 SHOW SUCCESS AND WAIT FOR USER
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );

      // 👉 NOW CLOSE GENERATE DIALOG ONLY ONCE
      Navigator.of(context).pop();

      // 👉 THEN RETURN DATA
      widget.onGenerate(
        generated.length,
        generated,
        _selectedMuscleGroup!,
        _selectedEquipmentType!,
      );
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  Widget _chip(String label) {
    final selected = _selectedMuscleGroup == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _isLoading
          ? null
          : (_) {
              setState(() {
                _selectedMuscleGroup = label;
                _error = null;
              });
            },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _equipment(String label, IconData icon) {
    final selected = _selectedEquipmentType == label;

    return ElevatedButton.icon(
      onPressed: _isLoading
          ? null
          : () {
              setState(() {
                _selectedEquipmentType = label;
                _error = null;
              });
            },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.green : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Generating workout...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Target Muscle"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('Chest'),
                      _chip('Back'),
                      _chip('Legs'),
                      _chip('Arms'),
                      _chip('Full Body'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Workout Type"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _equipment('At Home', Icons.home),
                      _equipment('Gym', Icons.fitness_center),
                      _equipment('Cardio', Icons.favorite),
                      _equipment('Dumbbells', Icons.sports_gymnastics),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateWorkout,
                        child: const Text("Generate"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Workout Generated!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ONLY closes success dialog
              },
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}

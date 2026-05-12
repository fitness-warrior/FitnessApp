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
      final isCardioTarget = _selectedEquipmentType == 'Cardio';

      final filtered = allExercises.where((e) {
        final area = (e['exer_body_area'] ?? '').toString().toLowerCase();
        final equip = (e['exer_equip'] ?? '').toString().toLowerCase();
        final type = (e['exer_type'] ?? '').toString().toLowerCase();

        if (isCardioTarget) {
          // If Cardio is selected, we want anything that is type cardio
          return type == 'cardio';
        }

        final targetAreas = _muscleGroupMapping[_selectedMuscleGroup]!;
        final targetEquipment = _equipmentTypeMapping[_selectedEquipmentType]!;

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
      // ignore: use_build_context_synchronously
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
      selectedColor: const Color(0xFF4A9FFF),
      backgroundColor: const Color(0xFF1C1C2E),
      side: BorderSide(color: selected ? const Color(0xFF4A9FFF) : const Color(0xFF2A2A3E)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey[400],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        // ignore: deprecated_member_use
        backgroundColor: selected ? const Color(0xFF66BB6A).withOpacity(0.2) : const Color(0xFF1C1C2E),
        foregroundColor: selected ? const Color(0xFF66BB6A) : Colors.grey[400],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? const Color(0xFF66BB6A) : const Color(0xFF2A2A3E),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A9FFF)),
                  SizedBox(height: 24),
                  Text(
                    "Generating workout...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Target Muscle",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Chest'),
                      _chip('Back'),
                      _chip('Legs'),
                      _chip('Arms'),
                      _chip('Full Body'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Workout Type",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _equipment('At Home', Icons.home),
                      _equipment('Gym', Icons.fitness_center),
                      _equipment('Cardio', Icons.favorite),
                      _equipment('Dumbbells', Icons.sports_gymnastics),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey[400])),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A9FFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
      backgroundColor: const Color(0xFF0D0D14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF66BB6A), size: 64),
            const SizedBox(height: 20),
            const Text(
              "Workout Generated!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ONLY closes success dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}

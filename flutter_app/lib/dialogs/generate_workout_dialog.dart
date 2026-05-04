import 'package:flutter/material.dart';
import '../services/exercise_service.dart';

class GenerateWorkoutDialog extends StatefulWidget {
  final Function(int, List<Map<String, dynamic>>) onGenerate;

  const GenerateWorkoutDialog({
    Key? key,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<GenerateWorkoutDialog> createState() => _GenerateWorkoutDialogState();
}

class _GenerateWorkoutDialogState extends State<GenerateWorkoutDialog> {
  List<String> _selectedMuscles = [];
  String? _selectedEquipmentType; // 'At Home', 'Gym (Machines)', 'Cardio', 'Dumbbells'
  bool _isLoading = false;
  bool _showMusclesSection = false;
  String? _error;

  final List<String> _allMuscles = [
    'Chest',
    'Shoulders',
    'Triceps',
    'Back',
    'Biceps',
    'Quadriceps',
    'Hamstrings',
    'Calves',
    'Glutes',
  ];

  final Map<String, List<String>> _equipmentTypeMapping = {
    'At Home': ['Bodyweight Only', 'Dumbbells'],
    'Gym (Machines)': ['Machine'],
    'Cardio': ['Cardio'],
    'Dumbbells': ['Dumbbells'],
  };

  Future<void> _generateWorkout() async {
    if (_selectedMuscles.isEmpty) {
      setState(() {
        _error = 'Please select at least one target muscle';
      });
      return;
    }

    if (_selectedEquipmentType == null) {
      setState(() {
        _error = 'Please select an equipment type';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allExercises = await ExerciseService.listExercises().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Loading exercises timed out');
            },
          );

      if (allExercises.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'No exercises available';
            _isLoading = false;
          });
        }
        return;
      }

      // Filter exercises by selected muscles and equipment type
      final targetEquipment = _equipmentTypeMapping[_selectedEquipmentType] ?? [];
      
      final filteredExercises = allExercises.where((exercise) {
        final bodyArea = (exercise['exer_body_area'] ?? '').toString().toLowerCase();
        final equipment = (exercise['exer_equip'] ?? '').toString().toLowerCase();
        
        final matchesArea = _selectedMuscles.any((muscle) => bodyArea.contains(muscle.toLowerCase()));
        final matchesEquipment = targetEquipment.any((equip) => equipment.contains(equip.toLowerCase()));
        
        return matchesArea && matchesEquipment;
      }).toList();

      if (filteredExercises.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'No exercises found for this combination. Try different selections.';
            _isLoading = false;
          });
        }
        return;
      }

      widget.onGenerate(filteredExercises.length, filteredExercises);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMuscleButton(String muscle) {
    final isSelected = _selectedMuscles.contains(muscle);
    return ElevatedButton(
      onPressed: _isLoading ? null : () {
        setState(() {
          if (isSelected) {
            _selectedMuscles.remove(muscle);
          } else {
            _selectedMuscles.add(muscle);
          }
          _error = null;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(muscle),
    );
  }

  Widget _buildEquipmentTypeButton(String type, IconData icon) {
    final isSelected = _selectedEquipmentType == type;
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () {
        setState(() {
          _selectedEquipmentType = type;
          _error = null;
        });
      },
      icon: Icon(icon),
      label: Text(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generate Workout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target Muscles',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          setState(() {
                            _showMusclesSection = !_showMusclesSection;
                          });
                        },
                        tooltip: 'Select muscles to target',
                      ),
                    ],
                  ),
                  if (_showMusclesSection) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _allMuscles.map((muscle) => _buildMuscleButton(muscle)).toList(),
                    ),
                  ],
                  if (_selectedMuscles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.purple.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_selectedMuscles.join(", ")}',
                              style: TextStyle(
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Select Equipment Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildEquipmentTypeButton('At Home', Icons.home),
                      _buildEquipmentTypeButton('Gym (Machines)', Icons.fitness_center),
                      _buildEquipmentTypeButton('Cardio', Icons.directions_run),
                      _buildEquipmentTypeButton('Dumbbells', Icons.sports_gymnastics),
                    ],
                  ),
                  if (_selectedEquipmentType != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Equipment: $_selectedEquipmentType',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateWorkout,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Generate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

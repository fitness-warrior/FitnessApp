import 'package:flutter/material.dart';
import '../services/workout_storage.dart';
import '../services/workout_service.dart';

class FinishWorkoutDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final Map<int, List<Map<String, TextEditingController>>> setControllers;
  final Function(Map<String, dynamic>) onSuccess;

  const FinishWorkoutDialog({
    Key? key,
    required this.exercises,
    required this.setControllers,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<FinishWorkoutDialog> createState() => _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState extends State<FinishWorkoutDialog> {
  bool _isLoading = false;
  String? _error;
  late TextEditingController _workoutNameController;

  @override
  void initState() {
    super.initState();
    _workoutNameController = TextEditingController();
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    super.dispose();
  }

  bool _validateWorkoutData() {
    for (int i = 0; i < widget.exercises.length; i++) {
      final exercise = widget.exercises[i];
      final exerType = exercise['exer_type']?.toString() ?? 'strength';
      final isCardio = exerType.toLowerCase() == 'cardio';

      if (widget.setControllers.containsKey(i)) {
        for (final set in widget.setControllers[i]!) {
          if (isCardio) {
            // Validate cardio fields
            final time = set['time']?.text.trim() ?? '';
            final calories = set['calories']?.text.trim() ?? '';

            if (time.isEmpty || calories.isEmpty) {
              return false;
            }

            final timeValue = double.tryParse(time);
            if (timeValue == null || timeValue <= 0) {
              return false;
            }

            final caloriesValue = double.tryParse(calories);
            if (caloriesValue == null || caloriesValue <= 0) {
              return false;
            }
          } else {
            // Validate strength fields
            final kg = set['kg']?.text.trim() ?? '';
            final reps = set['reps']?.text.trim() ?? '';

            if (kg.isEmpty || reps.isEmpty) {
              return false;
            }

            final kgValue = double.tryParse(kg);
            if (kgValue == null || kgValue <= 0 || kgValue >= 500) {
              return false;
            }

            final repsValue = int.tryParse(reps);
            if (repsValue == null || repsValue <= 0) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _buildExerciseData() {
    final data = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.exercises.length; i++) {
      final exercise = widget.exercises[i];
      final exerType = exercise['exer_type']?.toString() ?? 'strength';
      final isCardio = exerType.toLowerCase() == 'cardio';
      final sets = <Map<String, dynamic>>[];

      if (widget.setControllers.containsKey(i)) {
        for (final set in widget.setControllers[i]!) {
          if (isCardio) {
            sets.add({
              'time': set['time']?.text.isNotEmpty == true ? set['time']!.text : '0',
              'calories': set['calories']?.text.isNotEmpty == true ? set['calories']!.text : '0',
            });
          } else {
            sets.add({
              'kg': set['kg']?.text.isNotEmpty == true ? set['kg']!.text : '0',
              'reps': set['reps']?.text.isNotEmpty == true ? set['reps']!.text : '0',
            });
          }
        }
      }

      data.add({
        'exer_id': exercise['exer_id'] ?? 0,
        'exer_name': exercise['exer_name'] ?? 'Unknown',
        'exer_type': exerType,
        'sets': sets,
      });
    }

    return data;
  }

  Future<void> _showSaveConfirmationDialog() async {
    if (!_validateWorkoutData()) {
      setState(() {
        _error = 'Invalid values: All fields must be positive numbers';
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save as Routine?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Would you like to save this workout as a routine for future reference?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitWorkout(saveAsRoutine: false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('No'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRoutineNameDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Yes'),
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

  Future<void> _showRoutineNameDialog() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Name Your Routine',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter a name for this routine (optional)',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Chest Day, Push Workout',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _workoutNameController.text = nameController.text;
                          _submitWorkout(saveAsRoutine: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Save'),
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

  Future<void> _submitWorkout({bool saveAsRoutine = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exerciseData = _buildExerciseData();
      final workoutName = _workoutNameController.text.trim();

      // Save locally (works on all platforms including web) only if user chooses to
      if (saveAsRoutine) {
        await WorkoutStorage.saveWorkout(
          exerciseData,
          workoutName: workoutName.isNotEmpty ? workoutName : null,
        );
      }

      // Best-effort sync to API (skip if backend unreachable)
      try {
        await WorkoutService.submitWorkout(exerciseData)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

      widget.onSuccess({});
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saveAsRoutine
                  ? 'Workout saved successfully!'
                  : 'Workout completed!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseData = _buildExerciseData();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Finish Workout',
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
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${exerciseData.length} exercises completed',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Workout Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: exerciseData.length,
                      itemBuilder: (context, index) {
                        final exercise = exerciseData[index];
                        final sets = exercise['sets'] as List;
                        final exerType = exercise['exer_type']?.toString() ?? 'strength';
                        final isCardio = exerType.toLowerCase() == 'cardio';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['exer_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${sets.length} set${sets.length > 1 ? 's' : ''}: ${sets.map((s) => isCardio ? '${s['time']}min, ${s['calories']}cal' : '${s['reps']}x${s['kg']}kg').join(', ')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _showSaveConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Finish & Save'),
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

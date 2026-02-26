import 'package:flutter/material.dart';
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

  List<Map<String, dynamic>> _buildExerciseData() {
    final data = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.exercises.length; i++) {
      final exercise = widget.exercises[i];
      final sets = <Map<String, dynamic>>[];

      if (widget.setControllers.containsKey(i)) {
        for (final set in widget.setControllers[i]!) {
          sets.add({
            'kg': set['kg']!.text.isNotEmpty ? set['kg']!.text : '0',
            'reps': set['reps']!.text.isNotEmpty ? set['reps']!.text : '0',
          });
        }
      }

      data.add({
        'exer_id': exercise['exer_id'] ?? 0,
        'exer_name': exercise['exer_name'] ?? 'Unknown',
        'sets': sets,
      });
    }

    return data;
  }

  Future<void> _submitWorkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exerciseData = _buildExerciseData();
      final result = await WorkoutService.submitWorkout(exerciseData);

      widget.onSuccess(result);
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully!'),
            duration: Duration(seconds: 2),
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
                                  '${sets.length} set${sets.length > 1 ? 's' : ''}: ${sets.map((s) => '${s['reps']}x${s['kg']}kg').join(', ')}',
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
                        onPressed: _isLoading ? null : _submitWorkout,
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

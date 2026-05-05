import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutDayView extends StatefulWidget {
  final String dayName;
  final List<Map<String, dynamic>> routines;

  const WorkoutDayView({
    Key? key,
    required this.dayName,
    required this.routines,
  }) : super(key: key);

  @override
  State<WorkoutDayView> createState() => _WorkoutDayViewState();
}

class _WorkoutDayViewState extends State<WorkoutDayView> {
  // Map structure: routineIndex -> exerciseIndex -> list of boolean for sets
  final Map<int, Map<int, List<bool>>> _completedSets = {};

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    for (int rIndex = 0; rIndex < widget.routines.length; rIndex++) {
      _completedSets[rIndex] = {};
      final routine = widget.routines[rIndex];
      final exercises =
          routine['exercises'] is List ? routine['exercises'] as List : [];

      for (int eIndex = 0; eIndex < exercises.length; eIndex++) {
        final exercise = exercises[eIndex];
        final sets = exercise['sets'] is List ? exercise['sets'] as List : [];
        _completedSets[rIndex]![eIndex] =
            List.generate(sets.length, (_) => false);
      }
    }
  }

  void _toggleSet(int rIndex, int eIndex, int sIndex, bool isCurrentlyComplete) {
    if (isCurrentlyComplete) {
      // Allow un-ticking
      HapticFeedback.lightImpact();
      setState(() {
        _completedSets[rIndex]![eIndex]![sIndex] = false;
      });
      return;
    }

    // Ticking as complete
    HapticFeedback.mediumImpact();
    setState(() {
      _completedSets[rIndex]![eIndex]![sIndex] = true;
    });

    _showRestTimerDialog();
  }

  void _showRestTimerDialog() {
    int remainingSeconds = 120; // 2 minutes rest
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (remainingSeconds > 0) {
                if (mounted) {
                  setDialogState(() {
                    remainingSeconds--;
                  });
                }
              } else {
                t.cancel();
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            });

            final minutes = (remainingSeconds / 60).floor();
            final seconds = remainingSeconds % 60;
            final timeString =
                '$minutes:${seconds.toString().padLeft(2, '0')}';

            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Rest Time',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 48, color: Color(0xFF4A9FFF)),
                  const SizedBox(height: 16),
                  Text(
                    timeString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Skip Rest'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
    });
  }

  bool _isExerciseComplete(int rIndex, int eIndex) {
    final sets = _completedSets[rIndex]?[eIndex] ?? [];
    if (sets.isEmpty) return false;
    return sets.every((isComplete) => isComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        title: Text('${widget.dayName} Workout',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: widget.routines.isEmpty
          ? const Center(
              child: Text('No routines for this day.',
                  style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.routines.length,
              itemBuilder: (context, rIndex) {
                final routine = widget.routines[rIndex];
                final routineName =
                    routine['name']?.toString() ?? 'Routine ${rIndex + 1}';
                final exercises = routine['exercises'] is List
                    ? routine['exercises'] as List
                    : [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rIndex > 0) const SizedBox(height: 32),
                    Text(
                      routineName,
                      style: const TextStyle(
                        color: Color(0xFF4A9FFF),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(exercises.length, (eIndex) {
                      final exercise = exercises[eIndex];
                      final exerName =
                          exercise['exer_name'] ?? 'Unknown Exercise';
                      final setsRaw = exercise['sets'];
                      final sets = setsRaw is List ? setsRaw : [];

                      final isComplete = _isExerciseComplete(rIndex, eIndex);
                      final setsCompletedCount = _completedSets[rIndex]![eIndex]!
                          .where((c) => c)
                          .length;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isComplete
                              ? Colors.green.withOpacity(0.15)
                              : const Color(0xFF1C1C2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isComplete
                                ? Colors.green.withOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    exerName,
                                    style: TextStyle(
                                      color: isComplete
                                          ? Colors.greenAccent
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isComplete)
                                  const Icon(Icons.check_circle,
                                      color: Colors.greenAccent),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sets.isEmpty
                                  ? 'No sets'
                                  : '$setsCompletedCount / ${sets.length} sets completed',
                              style: TextStyle(
                                color: isComplete
                                    ? Colors.greenAccent.withOpacity(0.8)
                                    : Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(sets.length, (sIndex) {
                              final set = sets[sIndex];

                              final kg = set['kg']?.toString() ?? '0';
                              final reps = set['reps']?.toString() ?? '0';
                              final time = set['time']?.toString() ?? '';
                              final calories =
                                  set['calories']?.toString() ?? '';

                              String setText = '';
                              if (time.isNotEmpty || calories.isNotEmpty) {
                                setText = 'Time: $time min';
                                if (calories.isNotEmpty) {
                                  setText += ' | Cal: $calories';
                                }
                              } else {
                                setText = '$kg kg × $reps reps';
                              }

                              final isSetComplete =
                                  _completedSets[rIndex]![eIndex]![sIndex];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252538),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Set ${sIndex + 1}:  $setText',
                                      style: TextStyle(
                                        color: isSetComplete
                                            ? Colors.grey[500]
                                            : Colors.white,
                                        fontSize: 15,
                                        decoration: isSetComplete
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _toggleSet(rIndex, eIndex, sIndex,
                                            isSetComplete);
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSetComplete
                                              ? Colors.green
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSetComplete
                                                ? Colors.green
                                                : Colors.grey[500]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSetComplete
                                            ? const Icon(Icons.check,
                                                size: 20, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

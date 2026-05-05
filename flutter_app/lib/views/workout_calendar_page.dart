import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> savedWorkouts;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const WorkoutCalendarPage({
    Key? key,
    required this.savedWorkouts,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday'
  };

  final Map<String, List<Map<String, dynamic>>> _weeklyPlan = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyPlan();
  }

  Future<void> _loadWeeklyPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planString = prefs.getString('workout_weekly_plan');
      if (planString != null) {
        final decoded = jsonDecode(planString) as Map<String, dynamic>;
        setState(() {
          for (final day in _days) {
            if (decoded.containsKey(day)) {
              final routinesRaw = decoded[day] as List;
              _weeklyPlan[day] = routinesRaw
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          }
        });
      }
    } catch (e) {
      print('Error loading weekly plan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWeeklyPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planString = jsonEncode(_weeklyPlan);
      await prefs.setString('workout_weekly_plan', planString);
    } catch (e) {
      print('Error saving weekly plan: $e');
    }
  }

  void _openAssignRoutineDialog(String day) {
    List<Map<String, dynamic>> selectedRoutines =
        List.from(_weeklyPlan[day] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Assign to ${_dayNames[day]}',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: widget.savedWorkouts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No saved routines found. Create a routine first.",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.savedWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = widget.savedWorkouts[index];
                          final routineName =
                              workout['name']?.toString() ?? 'Workout ${index + 1}';
                          // Compare by name
                          final isSelected = selectedRoutines
                              .any((r) => r['name'] == workout['name']);

                          return CheckboxListTile(
                            title: Text(
                              routineName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: isSelected,
                            activeColor: const Color(0xFF4A9FFF),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedRoutines.add(workout);
                                } else {
                                  selectedRoutines.removeWhere(
                                      (r) => r['name'] == workout['name']);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _weeklyPlan[day] = selectedRoutines;
                    });
                    _saveWeeklyPlan();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9FFF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDayDetailsDialog(String day) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final routines = _weeklyPlan[day] ?? [];
            return Dialog(
              backgroundColor: const Color(0xFF1C1C2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_dayNames[day]} Routines',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF4A9FFF)),
                              onPressed: () {
                                Navigator.pop(context);
                                _openAssignRoutineDialog(day);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    routines.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No routines assigned.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: routines.length,
                              itemBuilder: (context, index) {
                                final routine = routines[index];
                                final routineName =
                                    routine['name']?.toString() ?? 'Workout';
                                final exercises = routine['exercises'];
                                final exerciseList =
                                    exercises is List ? exercises : [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252538),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            routineName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent,
                                                size: 20),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setDialogState(() {
                                                routines.removeAt(index);
                                                _weeklyPlan[day] = routines;
                                              });
                                              setState(() {});
                                              _saveWeeklyPlan();
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...List.generate(exerciseList.length,
                                          (exIdx) {
                                        final exercise = exerciseList[exIdx];
                                        final exerName =
                                            exercise['exer_name'] ??
                                                'Unknown Exercise';
                                        final sets = exercise['sets'];
                                        final setsList =
                                            sets is List ? sets : [];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text(
                                            '• $exerName (${setsList.length} sets)',
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ));
    }

    // DateTime.now().weekday returns 1 for Monday, 7 for Sunday
    final int currentWeekday = DateTime.now().weekday;

    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final isToday = (index + 1) == currentWeekday;
        final routines = _weeklyPlan[day] ?? [];

        return GestureDetector(
          onTap: () {
            if (routines.isEmpty) {
              _openAssignRoutineDialog(day);
            } else {
              _openDayDetailsDialog(day);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(16),
              border: isToday
                  ? Border.all(color: const Color(0xFF4A9FFF), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _dayNames[day]!,
                          style: TextStyle(
                            color: isToday
                                ? const Color(0xFF4A9FFF)
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A9FFF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                  color: Color(0xFF4A9FFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      routines.isEmpty
                          ? 'No routines assigned'
                          : '${routines.length} routine${routines.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: routines.isEmpty
                            ? Colors.grey[500]
                            : Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Icon(
                  routines.isEmpty
                      ? Icons.add_circle_outline
                      : Icons.chevron_right,
                  color: routines.isEmpty
                      ? const Color(0xFF4A9FFF)
                      : Colors.grey[400],
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

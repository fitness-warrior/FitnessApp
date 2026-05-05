import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/workout_storage.dart';
import '../services/streak_service.dart';
import '../services/user_stats_service.dart';

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

class _WorkoutDayViewState extends State<WorkoutDayView>
    with TickerProviderStateMixin {
  // routineIndex -> exerciseIndex -> list<bool> for each set
  final Map<int, Map<int, List<bool>>> _completedSets = {};
  // routineIndex -> exerciseIndex -> setIndex -> controllers
  final Map<int, Map<int, List<Map<String, TextEditingController>>>>
      _setControllers = {};

  bool _workoutFinished = false;
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  // ── Quit interception ─────────────────────────────────────────────────────
  bool _showingQuitScreen = false;
  late AnimationController _quitController;
  late Animation<double> _quitAnimation;

  // ── Elapsed timer ─────────────────────────────────────────────────────────
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  String get _formattedTime {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initializeState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _quitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _quitAnimation = CurvedAnimation(
      parent: _quitController,
      curve: Curves.elasticOut,
    );
    // Start the elapsed workout timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_workoutFinished) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _initializeState() {
    for (int rIndex = 0; rIndex < widget.routines.length; rIndex++) {
      _completedSets[rIndex] = {};
      _setControllers[rIndex] = {};
      final routine = widget.routines[rIndex];
      final exercises =
          routine['exercises'] is List ? routine['exercises'] as List : [];

      for (int eIndex = 0; eIndex < exercises.length; eIndex++) {
        final exercise = exercises[eIndex];
        final sets = exercise['sets'] is List ? exercise['sets'] as List : [];
        _completedSets[rIndex]![eIndex] =
            List.generate(sets.length, (_) => false);

        _setControllers[rIndex]![eIndex] =
            List.generate(sets.length, (sIndex) {
          final setMap = sets[sIndex];
          return {
            'kg': TextEditingController(
                text: setMap['kg']?.toString() ?? '0'),
            'reps': TextEditingController(
                text: setMap['reps']?.toString() ?? '0'),
            'time': TextEditingController(
                text: setMap['time']?.toString() ?? ''),
            'calories': TextEditingController(
                text: setMap['calories']?.toString() ?? ''),
          };
        });
      }
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _quitController.dispose();
    for (var routine in _setControllers.values) {
      for (var exercise in routine.values) {
        for (var set in exercise) {
          set['kg']?.dispose();
          set['reps']?.dispose();
          set['time']?.dispose();
          set['calories']?.dispose();
        }
      }
    }
    _successController.dispose();
    super.dispose();
  }

  // ── State helpers ─────────────────────────────────────────────────────────

  bool _isExerciseComplete(int rIndex, int eIndex) {
    final sets = _completedSets[rIndex]?[eIndex] ?? [];
    if (sets.isEmpty) return false;
    return sets.every((c) => c);
  }

  /// Returns true when every set in every exercise across all routines is done.
  bool _areAllComplete() {
    if (_completedSets.isEmpty) return false;
    for (final rEntry in _completedSets.entries) {
      for (final eEntry in rEntry.value.entries) {
        final sets = eEntry.value;
        if (sets.isEmpty) return false;
        if (!sets.every((c) => c)) return false;
      }
    }
    return true;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _toggleSet(
      int rIndex, int eIndex, int sIndex, bool isCurrentlyComplete, bool isCardio) {
    if (isCurrentlyComplete) {
      HapticFeedback.lightImpact();
      setState(() => _completedSets[rIndex]![eIndex]![sIndex] = false);
      return;
    }

    final controllers = _setControllers[rIndex]![eIndex]![sIndex];
    bool isValid = true;
    String errorMessage = '';

    if (isCardio) {
      final timeText = controllers['time']!.text.trim();
      final caloriesText = controllers['calories']!.text.trim();
      final time = double.tryParse(timeText);
      final calories = double.tryParse(caloriesText);

      if ((timeText.isEmpty && caloriesText.isEmpty) ||
          (time != null && time < 0) ||
          (calories != null && calories < 0)) {
        isValid = false;
        errorMessage = 'Please enter valid time or calories.';
      }
    } else {
      final kgText = controllers['kg']!.text.trim();
      final repsText = controllers['reps']!.text.trim();
      final kg = double.tryParse(kgText);
      final reps = int.tryParse(repsText);

      if (kgText.isEmpty ||
          repsText.isEmpty ||
          kg == null ||
          reps == null ||
          kg < 0 ||
          reps <= 0) {
        isValid = false;
        errorMessage = 'Please enter valid weight and reps (>0).';
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _completedSets[rIndex]![eIndex]![sIndex] = true);
    _showRestTimerDialog();
  }

  void _handleBackPress() {
    if (_workoutFinished) {
      Navigator.of(context).pop();
      return;
    }
    // If all done, let them leave (finish button handles it)
    if (_areAllComplete()) {
      Navigator.of(context).pop();
      return;
    }
    // Mid-workout: show the quit screen
    setState(() => _showingQuitScreen = true);
    _quitController.forward(from: 0);
  }

  void _keepGoing() {
    _quitController.reverse().then((_) {
      if (mounted) setState(() => _showingQuitScreen = false);
    });
  }

  void _confirmQuit() {
    Navigator.of(context).pop();
  }

  void _finishWorkout() async {
    HapticFeedback.heavyImpact();
    setState(() => _workoutFinished = true);
    _successController.forward();

    // Prepare data to save to history
    final List<Map<String, dynamic>> allExercises = [];
    for (int rIndex = 0; rIndex < widget.routines.length; rIndex++) {
      final routine = widget.routines[rIndex];
      final exercises =
          routine['exercises'] is List ? routine['exercises'] as List : [];

      for (int eIndex = 0; eIndex < exercises.length; eIndex++) {
        final exercise = exercises[eIndex];
        final sets = <Map<String, dynamic>>[];
        final controllers = _setControllers[rIndex]?[eIndex] ?? [];

        for (var setControllers in controllers) {
          sets.add({
            'kg': setControllers['kg']?.text ?? '0',
            'reps': setControllers['reps']?.text ?? '0',
          });
        }

        allExercises.add({
          'exer_id': exercise['exer_id'] ?? 0,
          'exer_name': exercise['exer_name'] ?? 'Unknown',
          'exer_type': exercise['exer_type'] ?? 'strength',
          'sets': sets,
        });
      }
    }

    // Save to local history so the app knows we did a workout today
    await WorkoutStorage.saveWorkout(
      allExercises,
      workoutName: widget.dayName,
    );

    // Update streak for the user
    try {
      await StreakService.updateStreak();
    } catch (_) {}

    // Grant XP: 20 XP per exercise
    final xpEarned = allExercises.length * 20;
    await UserStatsService.addXP(xpEarned);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showRestTimerDialog() {
    int remainingSeconds = 120;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (remainingSeconds > 0) {
              if (mounted) setDialogState(() => remainingSeconds--);
            } else {
              t.cancel();
              if (mounted && Navigator.canPop(context)) Navigator.pop(context);
            }
          });

          final minutes = (remainingSeconds / 60).floor();
          final seconds = remainingSeconds % 60;
          final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Rest Time',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 48, color: Color(0xFF4A9FFF)),
                const SizedBox(height: 16),
                Text(timeString,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  timer?.cancel();
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Skip Rest'),
              ),
            ],
          );
        });
      },
    ).then((_) => timer?.cancel());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show full-screen quit overlay when back is pressed mid-workout
    if (_showingQuitScreen) {
      return _buildQuitScreen();
    }

    // Show full-screen success overlay when workout is finished
    if (_workoutFinished) {
      return _buildSuccessScreen();
    }

    final allDone = _areAllComplete();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.dayName} Workout',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 13, color: Color(0xFF4A9FFF)),
                const SizedBox(width: 4),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                      color: Color(0xFF4A9FFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Sticky finish button at the bottom — only visible when all sets done
      bottomNavigationBar: allDone
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ElevatedButton.icon(
                  onPressed: _finishWorkout,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: const Text(
                    'Finish Workout',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ),
            )
          : null,
      body: widget.routines.isEmpty
          ? const Center(
              child: Text('No routines for this day.',
                  style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    Text(routineName,
                        style: const TextStyle(
                          color: Color(0xFF4A9FFF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
                    ...List.generate(exercises.length, (eIndex) {
                      final exercise = exercises[eIndex];
                      final exerName =
                          exercise['exer_name'] ?? 'Unknown Exercise';
                      final setsRaw = exercise['sets'];
                      final sets = setsRaw is List ? setsRaw : [];

                      final isComplete = _isExerciseComplete(rIndex, eIndex);
                      final setsCompletedCount =
                          _completedSets[rIndex]![eIndex]!
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                              final isSetComplete =
                                  _completedSets[rIndex]![eIndex]![sIndex];
                              final controllers =
                                  _setControllers[rIndex]![eIndex]![sIndex];
                              final isCardio =
                                  controllers['time']!.text.isNotEmpty ||
                                      controllers['calories']!.text.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252538),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Set ${sIndex + 1}',
                                      style: TextStyle(
                                        color: isSetComplete
                                            ? Colors.grey[500]
                                            : Colors.grey[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (isCardio) ...[
                                      Expanded(
                                          child: _buildCompactTextField(
                                              controller: controllers['time']!,
                                              label: 'min',
                                              isComplete: isSetComplete)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildCompactTextField(
                                              controller:
                                                  controllers['calories']!,
                                              label: 'cal',
                                              isComplete: isSetComplete)),
                                    ] else ...[
                                      Expanded(
                                          child: _buildCompactTextField(
                                              controller: controllers['kg']!,
                                              label: 'kg',
                                              isComplete: isSetComplete)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildCompactTextField(
                                              controller: controllers['reps']!,
                                              label: 'reps',
                                              isComplete: isSetComplete,
                                              isInteger: true)),
                                    ],
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => _toggleSet(rIndex, eIndex,
                                          sIndex, isSetComplete, isCardio),
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
        ),
      );
    }

  Widget _buildQuitScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _quitAnimation,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.heart_broken_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Really? Giving up?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I thought you weren\'t a quitter... \ud83d\ude14\nYour future self will thank you for finishing.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _keepGoing,
                    icon: const Icon(Icons.fitness_center, size: 20),
                    label: const Text(
                      'Keep Going! \ud83d\udcaa',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9FFF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _confirmQuit,
                    child: Text(
                      'Yes, I give up',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Workout Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Great job crushing ${widget.dayName}\'s workout.\nKeep the streak going! 🔥',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Stats summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statColumn(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: _formattedTime,
                        ),
                        _divider(),
                        _statColumn(
                          icon: Icons.list_alt,
                          label: 'Exercises',
                          value: '${_totalExercises()}',
                        ),
                        _divider(),
                        _statColumn(
                          icon: Icons.repeat,
                          label: 'Sets',
                          value: '${_totalSets()}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    label: const Text(
                      'Back to Plan',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[400],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statColumn(
      {required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.greenAccent, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 50, color: Colors.white.withOpacity(0.1));

  int _totalExercises() {
    int total = 0;
    for (final r in widget.routines) {
      final exs = r['exercises'];
      if (exs is List) total += exs.length;
    }
    return total;
  }

  int _totalSets() {
    int total = 0;
    for (final rMap in _completedSets.values) {
      for (final eSets in rMap.values) {
        total += eSets.length;
      }
    }
    return total;
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required bool isComplete,
    bool isInteger = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !isComplete,
      keyboardType: isInteger
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        isInteger
            ? FilteringTextInputFormatter.digitsOnly
            : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: TextStyle(
        color: isComplete ? Colors.grey[600] : Colors.white,
        fontSize: 16,
        decoration: isComplete ? TextDecoration.lineThrough : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: isComplete ? Colors.transparent : const Color(0xFF1C1C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

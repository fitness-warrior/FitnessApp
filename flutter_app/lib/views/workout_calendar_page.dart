import 'package:flutter/material.dart';
import '../services/weekly_plan_service.dart';
import 'workout_day_view.dart';

class WorkoutCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> savedWorkouts;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final VoidCallback? onRefresh;

  const WorkoutCalendarPage({
    Key? key,
    required this.savedWorkouts,
    this.shrinkWrap = false,
    this.physics,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  static const List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  static const Map<String, String> _dayNames = {
    'monday': 'Monday', 'tuesday': 'Tuesday', 'wednesday': 'Wednesday',
    'thursday': 'Thursday', 'friday': 'Friday',
    'saturday': 'Saturday', 'sunday': 'Sunday',
  };

  final Map<String, List<String>> _weeklyPlanNames = {
    for (final d in ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']) d: [],
  };

  final Map<String, Map<String, dynamic>> _routineCatalog = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadFromApi() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final plan = await WeeklyPlanService.getWeeklyPlan();
    if (!mounted) return;
    if (plan != null) {
      setState(() {
        _routineCatalog.clear();

        final weekPlan = plan['week_plan'] is Map
            ? Map<String, dynamic>.from(plan['week_plan'] as Map)
            : plan;

        for (final day in _days) {
          final names = weekPlan[day];
          _weeklyPlanNames[day] = names is List
              ? names.map((n) => n.toString()).toList()
              : <String>[];
        }

        final routinesRaw = plan['routines'];
        if (routinesRaw is List) {
          for (final routine in routinesRaw) {
            if (routine is Map) {
              final data = Map<String, dynamic>.from(routine);
              final name = data['name']?.toString();
              if (name != null && name.isNotEmpty) {
                _routineCatalog[name] = data;
              }
            }
          }
        }
      });
    } else {
      setState(() => _errorMessage = 'Could not load plan. Are you logged in?');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveToApi() async {
    final snapshot = <String, dynamic>{
      'week_plan': {
        for (final day in _days) day: List<String>.from(_weeklyPlanNames[day] ?? []),
      },
      'routines': _routineCatalog.values.toList(),
    };
    final ok = await WeeklyPlanService.saveWeeklyPlan(snapshot);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save plan — check your connection'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _removeRoutineFromDay(String day, String name) async {
    setState(() => _weeklyPlanNames[day]?.remove(name));
    await _saveToApi();
  }



  List<Map<String, dynamic>> _resolvedRoutines(String day) {
    final names = _weeklyPlanNames[day] ?? [];
    return names.map((name) {
      final planRoutine = _routineCatalog[name];
      if (planRoutine != null && planRoutine.isNotEmpty) {
        return planRoutine;
      }
      return widget.savedWorkouts.firstWhere(
        (w) => w['name']?.toString() == name,
        orElse: () => <String, dynamic>{},
      );
    }).where((w) => w.isNotEmpty).toList();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _openAssignDialog(String day) {
    List<String> selected = List<String>.from(_weeklyPlanNames[day] ?? []);
<<<<<<< HEAD
    final availableRoutines = _routineCatalog.isNotEmpty
        ? _routineCatalog.values.toList()
        : widget.savedWorkouts;
=======
    // Deduplicate routines by name to avoid showing the same routine multiple times
    final Set<String> seenNames = {};
    final List<Map<String, dynamic>> uniqueRoutines = [];
    
    for (var workout in widget.savedWorkouts) {
      String name = workout['name']?.toString() ?? '';
      // If nameless, it will be assigned a "Workout N" name in the UI, which we treat as unique-ish 
      // but let's at least deduplicate the ones that HAVE names.
      if (name.isEmpty) {
        uniqueRoutines.add(workout);
      } else if (!seenNames.contains(name.toLowerCase().trim())) {
        seenNames.add(name.toLowerCase().trim());
        uniqueRoutines.add(workout);
      }
    }
>>>>>>> 62b2ad7ec2f49f3b3bcc0dfcc3a680036b2a29c3

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Assign to ${_dayNames[day]}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
<<<<<<< HEAD
            child: availableRoutines.isEmpty
=======
            child: uniqueRoutines.isEmpty
>>>>>>> 62b2ad7ec2f49f3b3bcc0dfcc3a680036b2a29c3
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No saved routines. Finish a workout first.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
<<<<<<< HEAD
                    itemCount: availableRoutines.length,
                    itemBuilder: (_, i) {
                      final name = availableRoutines[i]['name']?.toString()
                          ?? 'Workout ${i + 1}';
=======
                    itemCount: uniqueRoutines.length,
                    itemBuilder: (_, i) {
                      final name = uniqueRoutines[i]['name']?.toString();
                      final displayName = (name == null || name.isEmpty)
                          ? 'Workout ${widget.savedWorkouts.length - i}'
                          : name;
>>>>>>> 62b2ad7ec2f49f3b3bcc0dfcc3a680036b2a29c3
                      return CheckboxListTile(
                        title: Text(displayName, style: const TextStyle(color: Colors.white)),
                        value: selected.contains(displayName),
                        activeColor: const Color(0xFF4A9FFF),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        onChanged: (v) => setD(() {
                          if (v == true) { if (!selected.contains(displayName)) selected.add(displayName); }
                          else { selected.remove(displayName); }
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _weeklyPlanNames[day] = List<String>.from(selected));
                Navigator.pop(ctx);
                await _saveToApi();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9FFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDayView(String day) async {
    final dayIndex = _days.indexOf(day);
    final alreadyDone = _isDayCompleted(dayIndex);

    if (alreadyDone) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4A9FFF)),
              SizedBox(width: 12),
              Text('Session Done', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'You have already completed a workout today. Would you like to start another session?',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9FFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Workout'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final routines = _resolvedRoutines(day);
    if (routines.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayView(
          dayName: _dayNames[day] ?? day,
          routines: routines,
        ),
      ),
    );
    widget.onRefresh?.call();
  }

  bool _isDayCompleted(int dayIndex) {
    // dayIndex is 0-6 (Mon-Sun)
    final now = DateTime.now();
    // Get this week's Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final targetDate = DateTime(monday.year, monday.month, monday.day)
        .add(Duration(days: dayIndex));
    final datePrefix =
        "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    return widget.savedWorkouts.any((w) {
      final date = w['date']?.toString() ?? '';
      return date.startsWith(datePrefix);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFromApi,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9FFF)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final int todayWeekday = DateTime.now().weekday; // 1=Mon, 7=Sun

    return RefreshIndicator(
      onRefresh: _loadFromApi,
      child: ListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _days.length,
        itemBuilder: (_, i) {
          final day = _days[i];
          final isToday = (i + 1) == todayWeekday;
          final isCompleted = _isDayCompleted(i);
          final assignedCount = (_weeklyPlanNames[day] ?? []).length;
          final resolved = _resolvedRoutines(day);

          return GestureDetector(
            onLongPress: () => _openAssignDialog(day),
            onTap: () =>
                assignedCount == 0 ? _openAssignDialog(day) : _openDayView(day),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF0F2D1F)
                    : const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(16),
                border: isCompleted
                    ? Border.all(color: const Color(0xFF66BB6A), width: 1.5)
                    : (isToday
                        ? Border.all(color: const Color(0xFF4A9FFF), width: 1.5)
                        : null),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            _dayNames[day]!,
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF66BB6A)
                                  : (isToday
                                      ? const Color(0xFF4A9FFF)
                                      : Colors.white),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Color(0xFF66BB6A), size: 18),
                          ],
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A9FFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Today',
                                  style: TextStyle(
                                      color: Color(0xFF4A9FFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 6),
                        if (assignedCount == 0)
                          Text(
                            'No routines assigned',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (_weeklyPlanNames[day] ?? [])
                                .map((name) => Container(
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 4,
                                          top: 3, bottom: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A9FFF)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF4A9FFF)
                                              .withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Color(0xFF4A9FFF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () =>
                                                _removeRoutineFromDay(
                                                    day, name),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Color(0xFF4A9FFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    assignedCount == 0 ? Icons.add_circle_outline : Icons.chevron_right,
                    color: assignedCount == 0 ? const Color(0xFF4A9FFF) : Colors.grey[400],
                    size: 28,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

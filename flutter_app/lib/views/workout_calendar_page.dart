import 'package:flutter/material.dart';
import '../services/weekly_plan_service.dart';
import 'workout_day_view.dart';

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
  static const List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  static const Map<String, String> _dayNames = {
    'monday': 'Monday', 'tuesday': 'Tuesday', 'wednesday': 'Wednesday',
    'thursday': 'Thursday', 'friday': 'Friday',
    'saturday': 'Saturday', 'sunday': 'Sunday',
  };

  // Only routine *names* are stored — resolved to full objects at render time.
  final Map<String, List<String>> _weeklyPlanNames = {
    for (final d in ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']) d: [],
  };

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
        for (final day in _days) {
          _weeklyPlanNames[day] = List<String>.from(plan[day] ?? []);
        }
      });
    } else {
      setState(() => _errorMessage = 'Could not load plan. Are you logged in?');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveToApi() async {
    final snapshot = Map<String, List<String>>.fromEntries(
      _days.map((d) => MapEntry(d, List<String>.from(_weeklyPlanNames[d] ?? []))),
    );
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
    return names
        .map((name) => widget.savedWorkouts.firstWhere(
              (w) => w['name']?.toString() == name,
              orElse: () => <String, dynamic>{},
            ))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _openAssignDialog(String day) {
    List<String> selected = List<String>.from(_weeklyPlanNames[day] ?? []);

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
            child: widget.savedWorkouts.isEmpty
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
                    itemCount: widget.savedWorkouts.length,
                    itemBuilder: (_, i) {
                      final name = widget.savedWorkouts[i]['name']?.toString()
                          ?? 'Workout ${i + 1}';
                      return CheckboxListTile(
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        value: selected.contains(name),
                        activeColor: const Color(0xFF4A9FFF),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        onChanged: (v) => setD(() {
                          if (v == true) { if (!selected.contains(name)) selected.add(name); }
                          else { selected.remove(name); }
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

  void _openDayView(String day) {
    final routines = _resolvedRoutines(day);
    if (routines.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayView(
          dayName: _dayNames[day] ?? day,
          routines: routines,
        ),
      ),
    );
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
          final assignedCount = (_weeklyPlanNames[day] ?? []).length;
          final resolved = _resolvedRoutines(day);

          return GestureDetector(
            onLongPress: () => _openAssignDialog(day),
            onTap: () => assignedCount == 0 ? _openAssignDialog(day) : _openDayView(day),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            _dayNames[day]!,
                            style: TextStyle(
                              color: isToday ? const Color(0xFF4A9FFF) : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

import 'package:flutter/material.dart';
import '../../services/streak_service.dart';

class StreakDisplay extends StatefulWidget {
  final bool compact;
  final int refreshToken;

  const StreakDisplay({
    Key? key,
    this.compact = true,
    this.refreshToken = 0,
  }) : super(key: key);

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay> {
  late Future<StreakData> _streakFuture;

  void _handleSharedStreakChange() {
    _refreshStreak();
  }

  @override
  void initState() {
    super.initState();
    _loadStreak();
    StreakService.streakVersion.addListener(_handleSharedStreakChange);
  }

  @override
  void didUpdateWidget(covariant StreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshStreak();
    }
  }

  @override
  void dispose() {
    StreakService.streakVersion.removeListener(_handleSharedStreakChange);
    super.dispose();
  }

  void _loadStreak() {
    _streakFuture = StreakService.getStreak().then((json) {
      return StreakService.parseStreakData(json);
    }).catchError((e) {
      debugPrint('Error loading streak: $e');
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        workoutsThisWeek: 0,
        weeklyGoal: 3,
      );
    });
  }

  void _refreshStreak() {
    setState(() {
      _loadStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakData>(
      future: _streakFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child:
                Icon(Icons.local_fire_department_outlined, color: Colors.grey),
          );
        }

        final streak = snapshot.data!;

        if (widget.compact) {
          // Compact app bar version
          return GestureDetector(
            onTap: () => _showStreakDetails(context, streak),
            child: Tooltip(
              message: 'Streak: ${streak.currentStreak} days',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${streak.currentStreak}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Expanded card version for profile/dashboard
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${streak.currentStreak}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text('Day Streak'),
                  const SizedBox(height: 12),
                  Text(
                    'Longest: ${streak.longestStreak}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: streak.weeklyProgressPercent / 100,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${streak.workoutsThisWeek}/${streak.weeklyGoal} workouts this week',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  void _showStreakDetails(BuildContext context, StreakData streak) {
    showDialog(
      context: context,
      builder: (context) => _StreakDetailsDialog(
        streak: streak,
        onGoalChanged: (newGoal) async {
          await StreakService.setWeeklyGoal(newGoal);
          // The notifyStreakChanged inside setWeeklyGoal will rebuild the display
        },
      ),
    );
  }

}

// ── Stateful dialog so the weekly goal updates in real time ──────────────────

class _StreakDetailsDialog extends StatefulWidget {
  final StreakData streak;
  final Future<void> Function(int) onGoalChanged;

  const _StreakDetailsDialog({
    required this.streak,
    required this.onGoalChanged,
  });

  @override
  State<_StreakDetailsDialog> createState() => _StreakDetailsDialogState();
}

class _StreakDetailsDialogState extends State<_StreakDetailsDialog> {
  late int _weeklyGoal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weeklyGoal = widget.streak.weeklyGoal;
  }

  Future<void> _pickGoal() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Workouts per week'),
        children: List.generate(7, (i) {
          final days = i + 1;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, days),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    days == _weeklyGoal
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFF4A9FFF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$days ${days == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontWeight: days == _weeklyGoal
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );

    if (picked != null && picked != _weeklyGoal) {
      setState(() {
        _weeklyGoal = picked;
        _saving = true;
      });
      await widget.onGoalChanged(picked);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsThisWeek = widget.streak.workoutsThisWeek;
    final remaining = (_weeklyGoal - workoutsThisWeek).clamp(0, _weeklyGoal);
    final progress = (workoutsThisWeek / _weeklyGoal).clamp(0.0, 1.0);
    final goalMet = workoutsThisWeek >= _weeklyGoal;

    return AlertDialog(
      title: const Text('Your Streak'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Current streak row ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Streak'),
                    Text(
                      '${widget.streak.currentStreak} days',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stats box ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statRow('Longest Streak',
                      '${widget.streak.longestStreak} days'),
                  _statRow('This Week', '$workoutsThisWeek/$_weeklyGoal'),
                  _statRow('Days Remaining', '$remaining'),

                  // ── Weekly goal editor ────────────────────────────────
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weekly Goal',
                          style: TextStyle(fontSize: 12)),
                      GestureDetector(
                        onTap: _saving ? null : _pickGoal,
                        child: Row(
                          children: [
                            Text(
                              '$_weeklyGoal ${_weeklyGoal == 1 ? 'day' : 'days'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A9FFF),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _saving
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5),
                                  )
                                : const Icon(Icons.edit,
                                    size: 13, color: Color(0xFF4A9FFF)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Progress bar ──────────────────────────────────────────────
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFF2E2E45),
              color: goalMet ? Colors.green : const Color(0xFF4A9FFF),
            ),
            const SizedBox(height: 8),
            Text(
              goalMet
                  ? '✅ Weekly goal met!'
                  : 'Keep it up! $remaining more to go.',
              style: TextStyle(
                fontSize: 12,
                color: goalMet ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

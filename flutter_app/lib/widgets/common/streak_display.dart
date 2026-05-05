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
      builder: (context) => AlertDialog(
        title: const Text('Your Streak'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Streak'),
                      Text(
                        '${streak.currentStreak} days',
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                        'Longest Streak', '${streak.longestStreak} days'),
                    _buildStatRow('This Week',
                        '${streak.workoutsThisWeek}/${streak.weeklyGoal}'),
                    _buildStatRow(
                        'Days Remaining', '${streak.workoutsRemaining}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: streak.weeklyProgressPercent / 100,
                minHeight: 12,
              ),
              const SizedBox(height: 8),
              Text(
                streak.goalMet
                    ? '✅ Weekly goal met!'
                    : 'Keep it up! ${streak.workoutsRemaining} more to go.',
                style: TextStyle(
                  fontSize: 12,
                  color: streak.goalMet ? Colors.green : Colors.orange,
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
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshStreak();
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

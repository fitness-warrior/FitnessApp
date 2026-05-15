import 'package:fitness_app_flutter/services/streak_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _formatDate(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _todayKey() => _formatDate(DateTime.now());

String _yesterdayKey() =>
    _formatDate(DateTime.now().subtract(const Duration(days: 1)));

String _weekAgoKey() =>
    _formatDate(DateTime.now().subtract(const Duration(days: 7)));

String _weekStartKey() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return _formatDate(monday);
}

String _previousWeekStartKey() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return _formatDate(monday.subtract(const Duration(days: 7)));
}

String _k(String base) => '${base}_anonymous';

Future<void> _setInt(String baseKey, int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_k(baseKey), value);
}

Future<void> _setString(String baseKey, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_k(baseKey), value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    // ignore: deprecated_member_use
    secureStorageChannel.setMockMethodCallHandler((call) async {
      return null;
    });
  });

  tearDownAll(() {
    // ignore: deprecated_member_use
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakService UTC-020 to UTC-031', () {
    test('UTC-020 first workout sets streak to 1 and records today', () async {
      final result = await StreakService.updateStreak();

      expect(result['current_streak'], equals(1));
      expect(result['longest_streak'], equals(1));
      expect(result['workouts_this_week'], equals(1));
      expect(result['last_workout_date'], equals(_todayKey()));
      expect(result['week_start_date'], equals(_weekStartKey()));
    });

    test('UTC-021 consecutive day workout increments streak by 1', () async {
      await _setInt('local_current_streak', 2);
      await _setInt('local_longest_streak', 5);
      await _setInt('local_workouts_this_week', 1);
      await _setString('local_last_workout_date', _yesterdayKey());
      await _setString('local_week_start_date', _weekStartKey());

      final result = await StreakService.updateStreak();

      expect(result['current_streak'], equals(3));
      expect(result['workouts_this_week'], equals(2));
      expect(result['last_workout_date'], equals(_todayKey()));
    });

    test('UTC-022 non-consecutive gap resets streak to 1', () async {
      await _setInt('local_current_streak', 6);
      await _setInt('local_longest_streak', 8);
      await _setInt('local_workouts_this_week', 2);
      await _setString('local_last_workout_date', _weekAgoKey());
      await _setString('local_week_start_date', _weekStartKey());

      final result = await StreakService.updateStreak();

      expect(result['current_streak'], equals(1));
      expect(result['longest_streak'], equals(8));
      expect(result['last_workout_date'], equals(_todayKey()));
    });

    test('UTC-023 multiple workouts same day only count once', () async {
      final first = await StreakService.updateStreak();
      final second = await StreakService.updateStreak();

      expect(first['current_streak'], equals(1));
      expect(second['current_streak'], equals(1));
      expect(first['workouts_this_week'], equals(1));
      expect(second['workouts_this_week'], equals(1));
      expect(second['last_workout_date'], equals(_todayKey()));
    });

    test('UTC-024 longest streak updates when current surpasses previous best',
        () async {
      await _setInt('local_current_streak', 6);
      await _setInt('local_longest_streak', 6);
      await _setInt('local_workouts_this_week', 1);
      await _setString('local_last_workout_date', _yesterdayKey());
      await _setString('local_week_start_date', _weekStartKey());

      final result = await StreakService.updateStreak();

      expect(result['current_streak'], equals(7));
      expect(result['longest_streak'], equals(7));
    });

    test('UTC-025 each workout increments workouts_this_week', () async {
      await _setInt('local_current_streak', 2);
      await _setInt('local_longest_streak', 4);
      await _setInt('local_workouts_this_week', 3);
      await _setString('local_last_workout_date', _yesterdayKey());
      await _setString('local_week_start_date', _weekStartKey());

      final result = await StreakService.updateStreak();

      expect(result['workouts_this_week'], equals(4));
    });

    test('UTC-026 new week resets weekly count and updates week_start_date',
        () async {
      await _setInt('local_current_streak', 4);
      await _setInt('local_longest_streak', 9);
      await _setInt('local_workouts_this_week', 5);
      await _setString('local_last_workout_date', _weekAgoKey());
      await _setString('local_week_start_date', _previousWeekStartKey());

      final result = await StreakService.updateStreak();

      expect(result['workouts_this_week'], equals(1));
      expect(result['week_start_date'], equals(_weekStartKey()));
    });

    test('UTC-027 setWeeklyGoal clamps input between 1 and 7', () async {
      await StreakService.setWeeklyGoal(0);
      final low = await StreakService.readWeeklyGoal();

      await StreakService.setWeeklyGoal(10);
      final high = await StreakService.readWeeklyGoal();

      expect(low, equals(1));
      expect(high, equals(7));
    });

    test('UTC-028 readWeeklyGoal defaults to 3 when not set', () async {
      final goal = await StreakService.readWeeklyGoal();
      expect(goal, equals(3));
    });

    test('UTC-029 parseStreakData maps all fields correctly', () {
      final data = StreakService.parseStreakData({
        'current_streak': 4,
        'longest_streak': 11,
        'workouts_this_week': 2,
        'weekly_goal': 5,
        'last_workout_date': '2026-05-14',
        'streak_start_date': '2026-05-10',
        'week_start_date': '2026-05-12',
      });

      expect(data.currentStreak, equals(4));
      expect(data.longestStreak, equals(11));
      expect(data.workoutsThisWeek, equals(2));
      expect(data.weeklyGoal, equals(5));
      expect(data.lastWorkoutDate, equals('2026-05-14'));
      expect(data.streakStartDate, equals('2026-05-10'));
      expect(data.weekStartDate, equals('2026-05-12'));
    });

    test('UTC-030 StreakData.goalMet is true when goal is reached', () {
      final data = StreakData(
        currentStreak: 1,
        longestStreak: 3,
        workoutsThisWeek: 3,
        weeklyGoal: 3,
      );

      expect(data.goalMet, isTrue);
    });

    test('UTC-031 weeklyProgressPercent calculates correctly', () {
      final data = StreakData(
        currentStreak: 1,
        longestStreak: 3,
        workoutsThisWeek: 2,
        weeklyGoal: 4,
      );

      expect(data.weeklyProgressPercent, equals(50));
    });

    test('StreakData.workoutsRemaining calculates correctly', () {
      final data = StreakData(
        currentStreak: 1,
        longestStreak: 3,
        workoutsThisWeek: 1,
        weeklyGoal: 3,
      );
      expect(data.workoutsRemaining, equals(2));
      
      final met = StreakData(
        currentStreak: 1,
        longestStreak: 3,
        workoutsThisWeek: 5,
        weeklyGoal: 3,
      );
      expect(met.workoutsRemaining, equals(0));
    });

    test('getStreak returns local when API fails', () async {
      // Mocked channel already returns null for read which leads to 400/fail usually
      await _setInt('local_current_streak', 5);
      final result = await StreakService.getStreak();
      expect(result['current_streak'], equals(5));
    });

    test('parseStreakData uses defaults for missing fields', () {
      final data = StreakService.parseStreakData({});
      expect(data.currentStreak, 0);
      expect(data.weeklyGoal, 3);
    });

    test('notifyStreakChanged increments version', () {
      final initial = StreakService.streakVersion.value;
      StreakService.notifyStreakChanged();
      expect(StreakService.streakVersion.value, equals(initial + 1));
    });
  });
}

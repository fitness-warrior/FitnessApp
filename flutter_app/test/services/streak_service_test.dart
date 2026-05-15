import 'dart:convert';
import 'package:fitness_app_flutter/services/streak_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _formatDate(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _todayKey() => _formatDate(DateTime.now());
String _yesterdayKey() => _formatDate(DateTime.now().subtract(const Duration(days: 1)));
String _weekAgoKey() => _formatDate(DateTime.now().subtract(const Duration(days: 7)));
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

String _k(String base) => '${base}_123'; // Using 123 for namespaced tests

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
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorageChannel.setMockMethodCallHandler((call) async {
      if (call.method == 'read') return jsonEncode({'user_id': 123});
      return null;
    });
  });

  tearDown(() {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  group('StreakService 100% Coverage', () {
    test('first workout sets streak to 1', () async {
      final result = await StreakService.updateStreak();
      expect(result['current_streak'], 1);
    });

    test('consecutive day increments streak', () async {
      await _setInt('local_current_streak', 2);
      await _setString('local_last_workout_date', _yesterdayKey());
      final result = await StreakService.updateStreak();
      expect(result['current_streak'], 3);
    });

    test('non-consecutive gap resets streak', () async {
      await _setInt('local_current_streak', 5);
      await _setString('local_last_workout_date', _weekAgoKey());
      final result = await StreakService.updateStreak();
      expect(result['current_streak'], 1);
    });

    test('multiple workouts same day only count once', () async {
      await StreakService.updateStreak();
      final result = await StreakService.updateStreak();
      expect(result['current_streak'], 1);
    });

    test('longest streak updates', () async {
      await _setInt('local_current_streak', 5);
      await _setInt('local_longest_streak', 5);
      await _setString('local_last_workout_date', _yesterdayKey());
      final result = await StreakService.updateStreak();
      expect(result['longest_streak'], 6);
    });

    test('new week resets weekly count', () async {
      await _setString('local_week_start_date', _previousWeekStartKey());
      await _setInt('local_workouts_this_week', 5);
      final result = await StreakService.updateStreak();
      expect(result['workouts_this_week'], 1);
    });

    test('setWeeklyGoal clamps and notifies', () async {
      await StreakService.setWeeklyGoal(10);
      expect(await StreakService.readWeeklyGoal(), 7);
      await StreakService.setWeeklyGoal(0);
      expect(await StreakService.readWeeklyGoal(), 1);
    });

    test('getStreak handles API success and merging (API > Local)', () async {
      StreakService.client = MockClient((request) async {
        return http.Response(jsonEncode({'current_streak': 10, 'longest_streak': 15}), 200);
      });
      await _setInt('local_current_streak', 5);
      final result = await StreakService.getStreak();
      expect(result['current_streak'], 10);
    });

    test('getStreak handles API success and merging (Local > API)', () async {
      StreakService.client = MockClient((request) async {
        return http.Response(jsonEncode({'current_streak': 3}), 200);
      });
      await _setInt('local_current_streak', 8);
      final result = await StreakService.getStreak();
      expect(result['current_streak'], 8);
    });

    test('getStreak handles API failure', () async {
      StreakService.client = MockClient((request) async {
        throw Exception('API Failed');
      });
      await _setInt('local_current_streak', 4);
      final result = await StreakService.getStreak();
      expect(result['current_streak'], 4);
    });

    test('StreakData model properties', () {
      final data = StreakData(currentStreak: 1, longestStreak: 1, workoutsThisWeek: 2, weeklyGoal: 5);
      expect(data.goalMet, isFalse);
      expect(data.workoutsRemaining, 3);
      expect(data.weeklyProgressPercent, 40);
      
      final met = StreakData(currentStreak: 1, longestStreak: 1, workoutsThisWeek: 5, weeklyGoal: 3);
      expect(met.goalMet, isTrue);
      expect(met.workoutsRemaining, 0);
      expect(met.weeklyProgressPercent, 100);
    });

    test('parseStreakData defaults', () {
      final data = StreakService.parseStreakData({});
      expect(data.currentStreak, 0);
      expect(data.weeklyGoal, 3);
    });
  });
}

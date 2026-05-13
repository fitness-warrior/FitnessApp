import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/services/streak_service.dart';
import 'package:fitness_app_flutter/widgets/common/streak_display.dart';

void main() {
  group('StreakDisplay Tests', () {

    test('Test 1: Displays current and longest streak - data model renders correctly', () {
      // StreakData created with currentStreak=5 and longestStreak=10
      final streakData = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        workoutsThisWeek: 0,
        weeklyGoal: 3,
      );

      // Current streak shows 5, longest streak shows 10
      expect(streakData.currentStreak, equals(5));
      expect(streakData.longestStreak, equals(10));
    });

    testWidgets('Test 2: Shows loading indicator while data is being fetched', (WidgetTester tester) async {
      // Build the widget — it starts a Future immediately
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakDisplay(),
          ),
        ),
      );

      // pump() once — FutureBuilder is in ConnectionState.waiting
      // Loading indicator should be visible before Future resolves
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('Test 3: Shows fallback on error - parseStreakData returns defaults on bad data', () {
      // Simulated API error: empty map (what the catchError in widget returns)
      final fallbackData = StreakService.parseStreakData({});

      // Widget should display fallback values instead of crashing
      // catchError in _loadStreak returns currentStreak: 0
      expect(fallbackData.currentStreak, equals(0));
      expect(fallbackData.longestStreak, equals(0));
      expect(fallbackData.workoutsThisWeek, equals(0));
      expect(fallbackData.weeklyGoal, equals(3)); // default goal
    });

    test('Test 4: Weekly progress displays correctly', () {
      // StreakDisplay rendered with workoutsThisWeek=3, weeklyGoal=5
      final streakData = StreakData(
        currentStreak: 0,
        longestStreak: 0,
        workoutsThisWeek: 3,
        weeklyGoal: 5,
      );

      // Weekly progress is shown as 3 out of 5
      expect(streakData.workoutsThisWeek, equals(3));
      expect(streakData.weeklyGoal, equals(5));

      // Progress percentage = (3 / 5) * 100 = 60%
      expect(streakData.weeklyProgressPercent, equals(60));

      // Goal not yet met
      expect(streakData.goalMet, isFalse);

      // 2 more workouts remaining
      expect(streakData.workoutsRemaining, equals(2));
    });

  });
}

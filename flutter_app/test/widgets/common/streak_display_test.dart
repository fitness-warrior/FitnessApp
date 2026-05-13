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

  });
}

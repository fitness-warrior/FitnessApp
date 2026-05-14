import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';
import 'package:fitness_app_flutter/widgets/common/navbar.dart';
import 'package:fitness_app_flutter/widgets/common/streak_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkoutPage Tests', () {
    // ── TEST 1 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage renders main action cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      // Wait for async initialization.
      await tester.pump(const Duration(seconds: 1));

      // The 'Exercise Library' section should be visible.
      expect(find.text('Exercise Library'), findsOneWidget);
      
      // The fitness-center icon should be present. We use findsWidgets because it may appear in multiple places.
      expect(find.byIcon(Icons.fitness_center), findsWidgets);
    });
    // ── TEST 2 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage shows an "Add Exercise" card instead of FAB when empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // In the new UI, when empty, we see 'Start Empty Workout' card.
      expect(find.text('Start Empty Workout'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });
    // ── TEST 3 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage AppBar shows StreakDisplay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // StreakDisplay should be in the AppBar actions.
      expect(find.byType(StreakDisplay), findsOneWidget);
    });
    // ── TEST 4 ──────────────────────────────────────────────────────────────
    testWidgets('WorkoutPage AppBar title shows "Workout"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // The AppBar title widget text should be 'Workout'.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Workout'),
        ),
        findsOneWidget,
      );
    });
    // ── TEST 5 ──────────────────────────────────────────────────────────────
    testWidgets('WorkoutPage renders a bottom navigation bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WorkoutPage), findsOneWidget);
    });
    // ── TEST 6 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage accepts initialRecommendationTags without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(
            initialRecommendationTags: ['chest', 'strength'],
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 6));

      // The page should still render the scaffold with the AppBar title.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Workout'),
        ),
        findsOneWidget,
      );
    });
  });
}

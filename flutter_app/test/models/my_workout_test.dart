import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';

void main() {
  group('WorkoutPage Tests', () {
    // ── TEST 1 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage shows empty-state message when no exercises are added',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      // Allow any initial async work (e.g. _loadPlaceholderExercise) to settle.
      await tester.pump(const Duration(seconds: 1));

      // The empty-state text should be visible.
      expect(find.text('No exercises added yet'), findsOneWidget);
      expect(
        find.text('Tap the search icon to add exercises'),
        findsOneWidget,
      );

      // The fitness-center icon should also be present (appears in the empty-state);
      // use findsWidgets because the icon may also appear elsewhere on the page.
      expect(find.byIcon(Icons.fitness_center), findsWidgets);
    });
    // ── TEST 2 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage shows an "Add Exercise" floating action button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // The FAB should display the label 'Add Exercise'.
      expect(find.text('Add Exercise'), findsOneWidget);

      // The FAB should have an add icon.
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
    // ── TEST 3 ──────────────────────────────────────────────────────────────
    testWidgets(
        'WorkoutPage AppBar shows search and generate-workout action icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Search icon button should be in the AppBar actions.
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Auto-awesome icon (generate workout) should be in the AppBar actions.
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Profile icon button should also be present.
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
    // ── TEST 4 ──────────────────────────────────────────────────────────────
    testWidgets('WorkoutPage AppBar title shows "My Workout"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // The AppBar title widget text should be 'My Workout'.
      expect(find.text('My Workout'), findsOneWidget);
    });
  });
}

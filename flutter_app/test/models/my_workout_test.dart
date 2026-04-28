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
  });
}

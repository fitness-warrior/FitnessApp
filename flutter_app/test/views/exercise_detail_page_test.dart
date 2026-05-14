import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/views/exercise_detail_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('ExerciseDetailPage', () {
    final sampleExercise = {
      'name': 'Bench Press',
      'area': 'Chest',
      'type': 'Strength',
      'description': 'Press the bar from chest to lockout.',
      'equipment': ['Barbell'],
      'video': '',
    };

    testWidgets('renders exercise name in app bar and body', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      // Title is rendered in the sliver app bar and again in the page body.
      expect(find.text('Bench Press'), findsNWidgets(2));
    });

    testWidgets('area badge renders with correct label', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      // The badge text uses a specific accent colour for the area 'Chest'.
      final badgeFinder = find.byWidgetPredicate((w) {
        return w is Text &&
            w.data == 'Chest' &&
            w.style?.color == const Color(0xFFEF5350);
      });

      expect(badgeFinder, findsOneWidget);
    });

    testWidgets('type badge renders when type provided', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      expect(find.text('Strength'), findsNWidgets(2));
    });

    testWidgets('equipment information tile displays correctly',
        (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      expect(find.text('Barbell'), findsOneWidget);
    });

    testWidgets(
        'renders empty exercise map without crashing and shows fallback text',
        (tester) async {
      await tester.pumpWidget(_wrap(const ExerciseDetailPage(exercise: {})));
      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsWidgets);
      expect(find.text('No description available.'), findsOneWidget);
    });
  });
}

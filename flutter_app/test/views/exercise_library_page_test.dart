import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitness_app_flutter/data/exercise_db.dart';
import 'package:fitness_app_flutter/views/exercise_library_page.dart';
import 'package:fitness_app_flutter/views/exercise_detail_page.dart';

void main() {
  group('ExerciseLibraryPage Widget Tests', () {
    final sampleExercises = [
      {
        'exer_id': 1,
        'exer_name': 'Bench Press',
        'exer_body_area': 'Chest',
        'exer_type': 'strength',
        'exer_equip': 'barbell',
      },
      {
        'exer_id': 2,
        'exer_name': 'Squat',
        'exer_body_area': 'Legs',
        'exer_type': 'strength',
        'exer_equip': 'barbell',
      },
      {
        'exer_id': 3,
        'exer_name': 'Running',
        'exer_body_area': 'Cardio',
        'exer_type': 'cardio',
        'exer_equip': 'none',
      },
      {
        'exer_id': 4,
        'exer_name': 'Pull-up',
        'exer_body_area': 'Back',
        'exer_type': 'strength',
        'exer_equip': ['bodyweight', 'bar'],
      },
    ];

    setUp(() {
      ExerciseDb.instance.client = MockClient((request) async {
        return http.Response(jsonEncode(sampleExercises), 200);
      });
    });

    testWidgets('Renders AppBar, search bar, chips, and list of exercises', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle(); // Wait for data load

      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);

      expect(find.text('4 exercises'), findsOneWidget);
    });

    testWidgets('Filtering by search text and clearing search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'bench');
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsNothing);
      expect(find.text('1 exercises'), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('4 exercises'), findsOneWidget);
    });

    testWidgets('Filtering by area chips and resetting with All', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Chest chip
      final chestChip = find.byKey(const ValueKey('filter_chip_Chest'));
      await tester.tap(chestChip);
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsNothing);
      expect(find.text('1 exercises'), findsOneWidget);

      // Tap Back chip (which is at index 2, fully visible in viewport)
      final backChip = find.byKey(const ValueKey('filter_chip_Back'));
      await tester.tap(backChip);
      await tester.pumpAndSettle();

      expect(find.text('Pull-up'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);

      // Tap All chip
      final allChip = find.byKey(const ValueKey('filter_chip_All'));
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('4 exercises'), findsOneWidget);
    });

    testWidgets('Search query with no matches shows empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No exercises found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('Tapping exercise card navigates to ExerciseDetailPage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseDetailPage), findsOneWidget);
    });

    testWidgets('Handles network error gracefully', (WidgetTester tester) async {
      ExerciseDb.instance.client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseLibraryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 exercises'), findsOneWidget);
    });
  });
}

import 'dart:async';

import 'package:fitness_app_flutter/widgets/exercise_detail_widget.dart';
import 'package:fitness_app_flutter/widgets/exercise_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('ExerciseDetailWidget', () {
    testWidgets(
      'WTC-035 renders exercise name, details, area, type, and equipment',
      (tester) async {
        Future<Map<String, dynamic>> loader(int _) async {
          return {
            'exer_name': 'Bench Press',
            'exer_body_area': 'Chest',
            'exer_type': 'Strength',
            'exer_descrip': 'Press the bar from chest to lockout.',
            'exer_equip': 'Barbell',
            'exer_vid': 'https://example.com/bench',
          };
        }

        await tester.pumpWidget(
          _wrap(
            ExerciseDetailWidget(
              exerId: 101,
              exerciseLoader: loader,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Bench Press'), findsOneWidget);
        expect(find.text('Chest'), findsOneWidget);
        expect(find.text('Strength'), findsOneWidget);
        expect(find.text('Barbell'), findsOneWidget);
        expect(
            find.text('Press the bar from chest to lockout.'), findsOneWidget);
      },
    );

    testWidgets('WTC-036 taps video button and launches tutorial URL',
        (tester) async {
      String? launchedUrl;

      Future<Map<String, dynamic>> loader(int _) async {
        return {
          'exer_name': 'Bench Press',
          'exer_body_area': 'Chest',
          'exer_type': 'Strength',
          'exer_descrip': 'Sample description',
          'exer_equip': 'Barbell',
          'exer_vid': 'https://example.com/tutorial',
        };
      }

      Future<bool> launcher(String url) async {
        launchedUrl = url;
        return true;
      }

      await tester.pumpWidget(
        _wrap(
          ExerciseDetailWidget(
            exerId: 102,
            exerciseLoader: loader,
            videoUrlLauncher: launcher,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open video'));
      await tester.pump();

      expect(launchedUrl, equals('https://example.com/tutorial'));
    });

    testWidgets('WTC-037 shows loading spinner while exercise is retrieved',
        (tester) async {
      final completer = Completer<Map<String, dynamic>>();

      Future<Map<String, dynamic>> loader(int _) => completer.future;

      await tester.pumpWidget(
        _wrap(
          ExerciseDetailWidget(
            exerId: 103,
            exerciseLoader: loader,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete({
        'exer_name': 'Push Up',
        'exer_body_area': 'Chest',
        'exer_type': 'Strength',
        'exer_descrip': 'Done',
      });
      await tester.pumpAndSettle();
    });

    testWidgets('WTC-038 displays error message when exercise is missing',
        (tester) async {
      Future<Map<String, dynamic>> loader(int _) async {
        throw Exception('Exercise not found');
      }

      await tester.pumpWidget(
        _wrap(
          ExerciseDetailWidget(
            exerId: 9999,
            exerciseLoader: loader,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Exercise not found'), findsOneWidget);
    });
  });

  group('ExerciseListWidget', () {
    final allExercises = List<Map<String, dynamic>>.generate(
      10,
      (i) => {
        'exer_name': i.isEven ? 'Bench Variant ${i + 1}' : 'Leg Day ${i + 1}',
        'exer_body_area': i.isEven ? 'chest' : 'legs',
        'exer_type': 'strength',
        'exer_equip': i.isEven ? 'Barbell' : 'Bodyweight Only',
      },
    );

    Future<List<Map<String, dynamic>>> listLoader({
      String? name,
      String? area,
      String? type,
      List<String>? equipment,
      List<String>? recommendationTags,
      bool forceRefresh = false,
    }) async {
      return allExercises.where((exercise) {
        final exerciseName =
            (exercise['exer_name'] ?? '').toString().toLowerCase();
        final exerciseArea =
            (exercise['exer_body_area'] ?? '').toString().toLowerCase();

        final matchesName = name == null || name.trim().isEmpty
            ? true
            : exerciseName.contains(name.toLowerCase());
        final matchesArea = area == null || area.isEmpty
            ? true
            : exerciseArea == area.toLowerCase();

        return matchesName && matchesArea;
      }).toList();
    }

    testWidgets('WTC-039 renders all 10 exercises in the list', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            listLoader: listLoader,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bench Variant 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Leg Day 10'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Leg Day 10'), findsOneWidget);
    });

    testWidgets('WTC-040 search filters list to exercises containing Bench',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            listLoader: listLoader,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Bench');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Bench Variant 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Bench Variant 9'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Bench Variant 9'), findsOneWidget);
      expect(find.textContaining('Leg Day'), findsNothing);
    });

    testWidgets('WTC-041 body area dropdown filters to legs exercises',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            listLoader: listLoader,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('legs').last);
      await tester.pumpAndSettle();

      expect(find.text('Leg Day 2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Leg Day 10'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Leg Day 10'), findsOneWidget);
      expect(find.textContaining('Bench Variant'), findsNothing);
    });
  });
}

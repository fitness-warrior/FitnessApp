import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/dialogs/excercise_search_dialog.dart';

Widget buildDialog({
  required void Function(Map<String, dynamic>) onExerciseSelected,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('openExerciseSearchButton'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => ExerciseSearchDialog(
                  onExerciseSelected: onExerciseSelected,
                ),
              );
            },
            child: const Text('Open Exercise Search'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    buildDialog(onExerciseSelected: (_) {}),
  );

  await tester.tap(find.byKey(const Key('openExerciseSearchButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('ExerciseSearchDialog Tests', () {
    testWidgets('renders header, search field and filters',
        (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.text('Search Exercises'), findsOneWidget);
      expect(find.text('Exercise name'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Body Area'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (WidgetTester tester) async {
      await openDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('shows initial empty placeholder', (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.textContaining('Start typing'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('typing search text shows clear icon',
        (WidgetTester tester) async {
      await openDialog(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(
          tester.widget<TextField>(searchField).controller?.text, equals(''));
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('body area dropdown opens options',
        (WidgetTester tester) async {
      await openDialog(tester);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsWidgets);

      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
    });

    testWidgets('type dropdown opens options', (WidgetTester tester) async {
      await openDialog(tester);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
      expect(find.text('Isolation'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
    });

    testWidgets('selecting a filter keeps dialog visible',
        (WidgetTester tester) async {
      await openDialog(tester);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest').last);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('search field updates controller text',
        (WidgetTester tester) async {
      await openDialog(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'bicep');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(searchField).controller?.text,
          equals('bicep'));
    });

    test('ExerciseSearchDialog can be instantiated', () {
      final dialog = ExerciseSearchDialog(
        key: null,
        onExerciseSelected: (_) {},
      );

      expect(dialog, isNotNull);
      expect(dialog.onExerciseSelected, isNotNull);
    });
  });
}

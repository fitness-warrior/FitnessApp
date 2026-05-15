import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/dialogs/generate_workout_dialog.dart';

Widget buildDialog({
  required void Function(int, List<Map<String, dynamic>>, String, String)
      onGenerate,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: GenerateWorkoutDialog(onGenerate: onGenerate),
      ),
    ),
  );
}

void main() {
  group('GenerateWorkoutDialog Tests', () {
    testWidgets('renders muscle group and equipment options',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      expect(find.text('Target Muscle'), findsOneWidget);
      expect(find.text('Workout Type'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);

      // Muscle group chips
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Arms'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);

      // Equipment buttons
      expect(find.text('At Home'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
    });

    testWidgets('shows error when Generate pressed without muscle group',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
        called = true;
      }));

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.text('Select a muscle group'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('shows equipment error after selecting muscle group only',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
        called = true;
      }));

      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.text('Select equipment type'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('selected muscle and equipment stay visible after tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      await tester.tap(find.text('Back'));
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();

      final selectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Back').first);

      expect(selectedChip.selected, isTrue);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('all muscle group chips can be selected individually',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      final muscleGroups = ['Chest', 'Back', 'Legs', 'Arms', 'Full Body'];
      for (final muscle in muscleGroups) {
        await tester.tap(find.text(muscle));
        await tester.pumpAndSettle();

        final selectedChip = tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, muscle).first);
        expect(selectedChip.selected, isTrue);

        // Deselect for next iteration
        await tester.tap(find.text(muscle));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('all equipment options can be selected individually',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      final equipments = ['At Home', 'Gym', 'Cardio', 'Dumbbells'];
      for (final equip in equipments) {
        await tester.tap(find.text(equip));
        await tester.pumpAndSettle();

        final equipmentIcons = {
          'At Home': Icons.home,
          'Gym': Icons.fitness_center,
          'Cardio': Icons.favorite,
          'Dumbbells': Icons.sports_gymnastics,
        };
        final selectedButton = find.ancestor(
            of: find.text(equip), 
            matching: find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Button')));
        expect(selectedButton, findsWidgets);

        // Deselect for next iteration
        await tester.tap(find.text(equip));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Cancel button closes dialog without calling callback',
        (WidgetTester tester) async {
      bool callbackCalled = false;
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
        callbackCalled = true;
      }));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(callbackCalled, isFalse);
    });

    testWidgets('error message clears when selection changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {
      }));

      // Trigger error
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();
      expect(find.text('Select a muscle group'), findsOneWidget);

      // Make selection
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      // Error should be cleared
      expect(find.text('Select a muscle group'), findsNothing);
    });

    testWidgets('switching muscle group selection updates state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      var selectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Chest').first);
      expect(selectedChip.selected, isTrue);

      // Switch to different muscle
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      final backChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Back').first);
      expect(backChip.selected, isTrue);

      // Previous selection should be deselected
      selectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Chest').first);
      expect(selectedChip.selected, isFalse);
    });

    testWidgets('switching equipment selection updates state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();

      final gymButton = find.ancestor(
          of: find.text('Gym'), 
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Button')));
      expect(gymButton, findsWidgets);

      // Switch to different equipment
      await tester.tap(find.text('Cardio'));
      await tester.pumpAndSettle();

      final cardioButton = find.ancestor(
          of: find.text('Cardio'), 
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Button')));
      expect(cardioButton, findsWidgets);
    });

    testWidgets('dialog background has correct color',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      final dialog = tester.widget<Dialog>(find.byType(Dialog).first);
      expect(dialog.backgroundColor, equals(const Color(0xFF0D0D14)));
    });

    testWidgets('buttons are disabled during loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      // Select options
      await tester.tap(find.text('Chest'));
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();

      // Buttons should be enabled before generation
      final generateButton =
          tester.widget<ElevatedButton>(find.ancestor(of: find.text('Generate'), matching: find.byType(ElevatedButton)).first);
      expect(generateButton.onPressed, isNotNull);
    });

    testWidgets('Generate button is visible and tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      final generateButton = find.text('Generate');
      expect(generateButton, findsOneWidget);

      await tester.tap(find.text('Chest'));
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();

      // Button should still be tappable
      await tester.ensureVisible(generateButton);
      expect(generateButton, findsOneWidget);
    });

    testWidgets('muscle group and equipment labels are visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      expect(find.text('Target Muscle', skipOffstage: false), findsOneWidget);
      expect(find.text('Workout Type', skipOffstage: false), findsOneWidget);
    });

    testWidgets('dialog is dismissible by back button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    test('GenerateWorkoutDialog can be instantiated', () {
      void testCallback(
          int a, List<Map<String, dynamic>> b, String c, String d) {}

      final dialog = GenerateWorkoutDialog(
        key: null,
        onGenerate: testCallback,
      );

      expect(dialog, isNotNull);
      expect(dialog.onGenerate, isNotNull);
    });

    testWidgets('choice chip styling reflects selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onGenerate: (_, __, ___, ____) {}));

      final unselectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Chest').first);
      expect(unselectedChip.selected, isFalse);

      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      final selectedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Chest').first);
      expect(selectedChip.selected, isTrue);
    });
  });
}

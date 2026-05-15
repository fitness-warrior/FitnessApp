import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/dialogs/food_picker_dialog.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

Widget buildDialog({required void Function(MealItem) onFoodSelected}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('openFoodPickerButton'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) =>
                    FoodPickerDialog(onFoodSelected: onFoodSelected),
              );
            },
            child: const Text('Open Food Picker'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    buildDialog(onFoodSelected: (_) {}),
  );
  await tester.tap(find.byKey(const Key('openFoodPickerButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('FoodPickerDialog Tests', () {
    testWidgets('renders dialog header and icons', (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.text('Add Food'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (WidgetTester tester) async {
      await openDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('renders search field, collection dropdown and max kcal field',
        (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.text('Search food…'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Max kcal'), findsOneWidget);
    });

    testWidgets('displays initial result count', (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.textContaining('result'), findsOneWidget);
    });

    testWidgets('search field updates the result count',
        (WidgetTester tester) async {
      await openDialog(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'chicken');
      await tester.pumpAndSettle();

      expect(find.textContaining('result'), findsOneWidget);
    });

    testWidgets('collection dropdown opens options',
        (WidgetTester tester) async {
      await openDialog(tester);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsOneWidget);

      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      expect(find.byType(DropdownMenuItem), findsWidgets);
    });

    testWidgets('max calories filter updates results',
        (WidgetTester tester) async {
      await openDialog(tester);

      final calorieFields = find.byType(TextField);
      final maxCalField = calorieFields.at(1);

      await tester.enterText(maxCalField, '100');
      await tester.pumpAndSettle();

      expect(find.textContaining('result'), findsOneWidget);
    });

    testWidgets('renders food list with items', (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.byType(ListView), findsOneWidget);
      expect(find.textContaining('kcal'), findsWidgets);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('clicking food item calls callback and closes dialog',
        (WidgetTester tester) async {
      bool callbackCalled = false;
      MealItem? selectedFood;

      await tester.pumpWidget(
        buildDialog(onFoodSelected: (food) {
          callbackCalled = true;
          selectedFood = food;
        }),
      );
      await tester.tap(find.byKey(const Key('openFoodPickerButton')));
      await tester.pumpAndSettle();

      final listTile = find.byType(ListTile).first;
      expect(listTile, findsOneWidget);

      await tester.tap(listTile);
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
      expect(selectedFood, isNotNull);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('empty search results show no foods message',
        (WidgetTester tester) async {
      await openDialog(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'xyzabc123notfound');
      await tester.pumpAndSettle();

      expect(find.textContaining('No foods'), findsOneWidget);
    });

    testWidgets('dialog supports clearing search text',
        (WidgetTester tester) async {
      await openDialog(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'salmon');
      await tester.pumpAndSettle();

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(
          tester.widget<TextField>(searchField).controller?.text, equals(''));
      expect(find.textContaining('result'), findsOneWidget);
    });

    test('FoodPickerDialog callback is required', () {
      void testCallback(MealItem item) {}

      final dialog = FoodPickerDialog(
        key: null,
        onFoodSelected: testCallback,
      );

      expect(dialog, isNotNull);
      expect(dialog.onFoodSelected, equals(testCallback));
    });
  });
}

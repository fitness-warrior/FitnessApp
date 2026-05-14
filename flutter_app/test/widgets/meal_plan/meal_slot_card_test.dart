import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/meal_plan/meal_slot_card.dart';
import 'package:fitness_app_flutter/models/daily_meal_plan.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  group('MealSlotCard Tests', () {

    testWidgets('Test 1: Meal slot label and icon display correctly', (WidgetTester tester) async {
      // MealSlotCard rendered with slotType: Dinner
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MealSlotCard(
              slot: MealSlot.dinner,
              items: [],
            ),
          ),
        ),
      );

      // Dinner label visible
      expect(find.text('Dinner'), findsOneWidget);

      // Dinner icon (dinner_dining) visible
      expect(find.byIcon(Icons.dinner_dining), findsOneWidget);
    });

    testWidgets('Test 2: Meal items render in the slot', (WidgetTester tester) async {
      // MealSlotCard rendered with 2 meal items
      final items = <MealItem>[
        const MealItem(id: 1, name: 'Chicken Breast', type: 'Protein', calories: 165, quantity: 100),
        const MealItem(id: 2, name: 'Brown Rice',     type: 'Carb',    calories: 112, quantity: 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSlotCard(
              slot: MealSlot.lunch,
              items: items,
            ),
          ),
        ),
      );

      // Both meal items listed inside the card
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Brown Rice'), findsOneWidget);
    });

    testWidgets('Test 3: Total calories calculated and displayed', (WidgetTester tester) async {
      // calories = (caloriesPer100Unit * quantity) / 100
      // 500 cal/100 * 100g = 500 kcal each; total = 1000 kcal
      final items = <MealItem>[
        const MealItem(id: 1, name: 'Food A', type: 'Carb',    calories: 500, quantity: 100),
        const MealItem(id: 2, name: 'Food B', type: 'Protein', calories: 500, quantity: 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSlotCard(
              slot: MealSlot.breakfast,
              items: items,
            ),
          ),
        ),
      );

      // Card displays total of 1000 kcal
      expect(find.text('1000 kcal'), findsOneWidget);
    });

    testWidgets('Test 4: Add food button callback fires', (WidgetTester tester) async {
      bool addFoodCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSlotCard(
              slot: MealSlot.snack,
              items: const [],
              onAddFood: () {
                addFoodCalled = true;
              },
            ),
          ),
        ),
      );

      // User taps 'Add Food' button
      await tester.tap(find.text('Add Food'));
      await tester.pump();

      // onAddFood callback is invoked
      expect(addFoodCalled, isTrue);
    });

    testWidgets('Test 5: Delete meal item callback fires', (WidgetTester tester) async {
      int? deletedIndex;

      final items = <MealItem>[
        const MealItem(id: 1, name: 'Chicken Breast', type: 'Protein', calories: 165, quantity: 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSlotCard(
              slot: MealSlot.dinner,
              items: items,
              onDeleteFood: (index) {
                deletedIndex = index;
              },
            ),
          ),
        ),
      );

      // User selects delete on the first meal item
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // onDelete callback invoked for that item (index 0)
      expect(deletedIndex, equals(0));
    });

  });
}

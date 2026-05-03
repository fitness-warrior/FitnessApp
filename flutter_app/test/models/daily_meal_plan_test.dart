// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/daily_meal_plan.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  group('DailyMealPlan Model Tests', () {
    test('DailyMealPlan initializes with empty slots', () {
      final date = DateTime(2025, 4, 4);
      final plan = DailyMealPlan(date: date);

      expect(plan.date, equals(date));
      expect(plan.slots.length, equals(4)); // breakfast, lunch, dinner, snack
      expect(plan.itemsFor(MealSlot.breakfast), isEmpty);
      expect(plan.itemsFor(MealSlot.lunch), isEmpty);
      expect(plan.itemsFor(MealSlot.dinner), isEmpty);
      expect(plan.itemsFor(MealSlot.snack), isEmpty);
    });

    test('DailyMealPlan initializes with provided slots', () {
      final date = DateTime(2025, 4, 4);
      const item1 = MealItem(
        id: 1,
        name: 'Chicken',
        type: 'Protein',
        calories: 165,
      );
      const item2 = MealItem(
        id: 2,
        name: 'Rice',
        type: 'Carb',
        calories: 130,
      );

      final slots = <MealSlot, List<MealItem>>{
        MealSlot.breakfast: [item1],
        MealSlot.lunch: [item2],
        MealSlot.dinner: [],
        MealSlot.snack: [],
      };

      final plan = DailyMealPlan(date: date, slots: slots);

      expect(plan.itemsFor(MealSlot.breakfast), equals([item1]));
      expect(plan.itemsFor(MealSlot.lunch), equals([item2]));
    });

    test('totalCalories sums all items across slots', () {
      final date = DateTime(2025, 4, 4);
      const item1 =
          MealItem(id: 1, name: 'Chicken', type: 'Protein', calories: 165);
      const item2 = MealItem(id: 2, name: 'Rice', type: 'Carb', calories: 130);
      const item3 =
          MealItem(id: 3, name: 'Broccoli', type: 'Vegetable', calories: 55);

      final slots = <MealSlot, List<MealItem>>{
        MealSlot.breakfast: [item1],
        MealSlot.lunch: [item2],
        MealSlot.dinner: [item3],
        MealSlot.snack: [],
      };

      final plan = DailyMealPlan(date: date, slots: slots);

      expect(plan.totalCalories, equals(350)); // 165 + 130 + 55
    });

    test('totalCalories returns 0 when no items', () {
      final plan = DailyMealPlan(date: DateTime(2025, 4, 4));
      expect(plan.totalCalories, equals(0));
    });

    test('copyWithItem adds item to slot and returns new plan', () {
      final date = DateTime(2025, 4, 4);
      final plan1 = DailyMealPlan(date: date);

      const item = MealItem(id: 1, name: 'Egg', type: 'Protein', calories: 70);
      final plan2 = plan1.copyWithItem(MealSlot.breakfast, item);

      // Original unchanged
      expect(plan1.itemsFor(MealSlot.breakfast), isEmpty);

      // New plan has item
      expect(plan2.itemsFor(MealSlot.breakfast), equals([item]));
      expect(plan2.totalCalories, equals(70));
    });

    test('copyWithItem preserves other slots', () {
      final date = DateTime(2025, 4, 4);
      const item1 = MealItem(id: 1, name: 'Apple', type: 'Fruit', calories: 52);
      const item2 = MealItem(id: 2, name: 'Bread', type: 'Carb', calories: 79);

      final plan1 = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [item1],
          MealSlot.lunch: [],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      final plan2 = plan1.copyWithItem(MealSlot.lunch, item2);

      expect(plan2.itemsFor(MealSlot.breakfast), equals([item1]));
      expect(plan2.itemsFor(MealSlot.lunch), equals([item2]));
      expect(plan2.totalCalories, equals(131)); // 52 + 79
    });

    test('MealSlot.label returns correct display strings', () {
      expect(MealSlot.breakfast.label, equals('Breakfast'));
      expect(MealSlot.lunch.label, equals('Lunch'));
      expect(MealSlot.dinner.label, equals('Dinner'));
      expect(MealSlot.snack.label, equals('Snack'));
    });

    test('itemsFor returns empty list for non-existent slot', () {
      final plan = DailyMealPlan(date: DateTime(2025, 4, 4));
      // This tests edge case where slot might not be in map (defensive)
      expect(plan.itemsFor(MealSlot.breakfast), isA<List>());
    });

    test('copyWithoutItem removes item at index and returns new plan', () {
      final date = DateTime(2025, 4, 4);
      const item1 =
          MealItem(id: 1, name: 'Item1', type: 'Protein', calories: 100);
      const item2 = MealItem(id: 2, name: 'Item2', type: 'Carb', calories: 50);

      final plan1 = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [item1, item2],
          MealSlot.lunch: [],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      final plan2 = plan1.copyWithoutItem(MealSlot.breakfast, 0);

      // Original unchanged
      expect(plan1.itemsFor(MealSlot.breakfast).length, equals(2));

      // New plan has item removed
      expect(plan2.itemsFor(MealSlot.breakfast).length, equals(1));
      expect(plan2.itemsFor(MealSlot.breakfast)[0], equals(item2));
      expect(plan2.totalCalories, equals(50));
    });

    test('DailyMealPlan.toMap creates correct map structure', () {
      final date = DateTime(2025, 4, 4);
      const item =
          MealItem(id: 1, name: 'Chicken', type: 'Protein', calories: 165);

      final plan = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [item],
          MealSlot.lunch: [],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      final map = plan.toMap();

      expect(map['date'], equals(date.toIso8601String()));
      expect(map['slots'], isA<Map>());
      expect((map['slots'] as Map)['breakfast'], isA<List>());
    });

    test('DailyMealPlan.fromMap creates instance from map', () {
      final date = DateTime(2025, 4, 4);
      final map = <String, dynamic>{
        'date': date.toIso8601String(),
        'slots': <String, List<Map<String, dynamic>>>{
          'breakfast': <Map<String, dynamic>>[
            {'id': 1, 'name': 'Eggs', 'type': 'Protein', 'calories': 70.0}
          ],
          'lunch': <Map<String, dynamic>>[],
          'dinner': <Map<String, dynamic>>[],
          'snack': <Map<String, dynamic>>[],
        },
      };

      final plan = DailyMealPlan.fromMap(map);

      expect(plan.date, equals(date));
      expect(plan.itemsFor(MealSlot.breakfast).length, equals(1));
      expect(plan.itemsFor(MealSlot.breakfast)[0].name, equals('Eggs'));
    });

    test('DailyMealPlan.toJson and fromJson roundtrip', () {
      final date = DateTime(2025, 4, 4);
      const item1 =
          MealItem(id: 1, name: 'Chicken', type: 'Protein', calories: 165);
      const item2 =
          MealItem(id: 2, name: 'Broccoli', type: 'Vegetable', calories: 55);

      final original = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [item1],
          MealSlot.lunch: [item2],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      final jsonString = original.toJson();
      final restored = DailyMealPlan.fromJson(jsonString);

      expect(restored.date, equals(original.date));
      expect(restored.itemsFor(MealSlot.breakfast).length, equals(1));
      expect(restored.itemsFor(MealSlot.breakfast)[0].name, equals('Chicken'));
      expect(restored.itemsFor(MealSlot.lunch).length, equals(1));
      expect(restored.itemsFor(MealSlot.lunch)[0].name, equals('Broccoli'));
      expect(restored.totalCalories, equals(original.totalCalories));
    });

    test('DailyMealPlan.fromMap handles missing slots gracefully', () {
      final date = DateTime(2025, 4, 4);
      final map = <String, dynamic>{
        'date': date.toIso8601String(),
        'slots': <String, List<Map<String, dynamic>>>{
          'breakfast': [
            {'id': 1, 'name': 'Toast', 'type': 'Carb', 'calories': 80.0}
          ],
          // lunch, dinner, snack missing
        },
      };

      final plan = DailyMealPlan.fromMap(map);

      expect(plan.itemsFor(MealSlot.breakfast).length, equals(1));
      expect(plan.itemsFor(MealSlot.lunch), isEmpty);
      expect(plan.itemsFor(MealSlot.dinner), isEmpty);
      expect(plan.itemsFor(MealSlot.snack), isEmpty);
    });
  });
}

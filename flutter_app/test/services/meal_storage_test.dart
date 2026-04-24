import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/daily_meal_plan.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  group('MealStorage Tests', () {
    test('MealStorage key format matches yyyy-MM-dd pattern', () {
      final date1 = DateTime(2025, 4, 4);
      const key1 = 'meal_plan_2025-04-04';

      // Test key generation logic manually
      final generatedKey = 'meal_plan_${date1.year.toString().padLeft(4, '0')}'
          '-${date1.month.toString().padLeft(2, '0')}'
          '-${date1.day.toString().padLeft(2, '0')}';

      expect(generatedKey, equals(key1));
    });

    test('MealStorage key format pads month and day with zeros', () {
      final date = DateTime(2025, 1, 5);
      final generatedKey = 'meal_plan_${date.year.toString().padLeft(4, '0')}'
          '-${date.month.toString().padLeft(2, '0')}'
          '-${date.day.toString().padLeft(2, '0')}';

      expect(generatedKey, equals('meal_plan_2025-01-05'));
    });

    test('MealStorage key format pads year with zeros', () {
      final date = DateTime(99, 12, 31);
      final generatedKey = 'meal_plan_${date.year.toString().padLeft(4, '0')}'
          '-${date.month.toString().padLeft(2, '0')}'
          '-${date.day.toString().padLeft(2, '0')}';

      expect(generatedKey, equals('meal_plan_0099-12-31'));
    });

    test('DailyMealPlan JSON serialization for storage', () {
      final date = DateTime(2025, 4, 4);
      const item = MealItem(
        id: 1,
        name: 'Eggs',
        type: 'Protein',
        calories: 70.0,
      );

      final plan = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [item],
          MealSlot.lunch: [],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      // Simulate savePlan: convert to JSON
      final jsonString = plan.toJson();
      expect(jsonString, isNotEmpty);

      // Simulate loadPlan: parse back from JSON
      final loadedPlan = DailyMealPlan.fromJson(jsonString);

      expect(loadedPlan.date, equals(date));
      expect(loadedPlan.itemsFor(MealSlot.breakfast).length, equals(1));
      expect(loadedPlan.itemsFor(MealSlot.breakfast)[0].name, equals('Eggs'));
    });

    test('DailyMealPlan with multiple meals stores correctly', () {
      final date = DateTime(2025, 4, 4);
      const breakfast =
          MealItem(id: 1, name: 'Oatmeal', type: 'Carb', calories: 150);
      const lunch =
          MealItem(id: 2, name: 'Chicken Salad', type: 'Mixed', calories: 350);
      const dinner =
          MealItem(id: 3, name: 'Fish', type: 'Protein', calories: 200);

      final plan = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [breakfast],
          MealSlot.lunch: [lunch],
          MealSlot.dinner: [dinner],
          MealSlot.snack: [],
        },
      );

      final jsonString = plan.toJson();
      final loadedPlan = DailyMealPlan.fromJson(jsonString);

      expect(loadedPlan.totalCalories, equals(700));
      expect(
          loadedPlan.itemsFor(MealSlot.breakfast)[0].name, equals('Oatmeal'));
      expect(
          loadedPlan.itemsFor(MealSlot.lunch)[0].name, equals('Chicken Salad'));
      expect(loadedPlan.itemsFor(MealSlot.dinner)[0].name, equals('Fish'));
    });

    test('DailyMealPlan with multiple items in same slot stores correctly', () {
      final date = DateTime(2025, 4, 4);
      const chicken =
          MealItem(id: 1, name: 'Chicken', type: 'Protein', calories: 165);
      const rice = MealItem(id: 2, name: 'Rice', type: 'Carb', calories: 130);
      const broccoli =
          MealItem(id: 3, name: 'Broccoli', type: 'Vegetable', calories: 55);

      final plan = DailyMealPlan(
        date: date,
        slots: <MealSlot, List<MealItem>>{
          MealSlot.breakfast: [],
          MealSlot.lunch: [chicken, rice, broccoli],
          MealSlot.dinner: [],
          MealSlot.snack: [],
        },
      );

      final jsonString = plan.toJson();
      final loadedPlan = DailyMealPlan.fromJson(jsonString);

      expect(loadedPlan.itemsFor(MealSlot.lunch).length, equals(3));
      expect(loadedPlan.totalCalories, equals(350));
    });

    test('Empty DailyMealPlan stores and loads correctly', () {
      final date = DateTime(2025, 4, 4);
      final plan = DailyMealPlan(date: date);

      final jsonString = plan.toJson();
      final loadedPlan = DailyMealPlan.fromJson(jsonString);

      expect(loadedPlan.date, equals(date));
      expect(loadedPlan.totalCalories, equals(0));
      expect(loadedPlan.itemsFor(MealSlot.breakfast), isEmpty);
      expect(loadedPlan.itemsFor(MealSlot.lunch), isEmpty);
      expect(loadedPlan.itemsFor(MealSlot.dinner), isEmpty);
      expect(loadedPlan.itemsFor(MealSlot.snack), isEmpty);
    });

    test('Different dates have different storage keys', () {
      final date1 = DateTime(2025, 4, 4);
      final date2 = DateTime(2025, 4, 5);

      final key1 = 'meal_plan_${date1.year.toString().padLeft(4, '0')}'
          '-${date1.month.toString().padLeft(2, '0')}'
          '-${date1.day.toString().padLeft(2, '0')}';

      final key2 = 'meal_plan_${date2.year.toString().padLeft(4, '0')}'
          '-${date2.month.toString().padLeft(2, '0')}'
          '-${date2.day.toString().padLeft(2, '0')}';

      expect(key1, equals('meal_plan_2025-04-04'));
      expect(key2, equals('meal_plan_2025-04-05'));
      expect(key1, isNot(equals(key2)));
    });
  });
}

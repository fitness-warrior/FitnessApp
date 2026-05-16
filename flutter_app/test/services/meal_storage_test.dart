import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitness_app_flutter/services/meal_storage.dart';
import 'package:fitness_app_flutter/models/daily_meal_plan.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealStorage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    test('loadPlan returns empty plan if none is saved locally and offline', () async {
      final date = DateTime(2025, 4, 4);
      final plan = await MealStorage.loadPlan(date);
      expect(plan.date, date);
      expect(plan.totalCalories, 0);
    });

    test('savePlan saves locally and loadPlan retrieves it', () async {
      final date = DateTime(2025, 4, 4);
      final plan = DailyMealPlan(date: date, slots: {
        MealSlot.breakfast: [const MealItem(id: 1, name: 'Eggs', type: 'Protein', calories: 70)]
      });

      await MealStorage.savePlan(plan);

      final loadedPlan = await MealStorage.loadPlan(date);
      expect(loadedPlan.date, date);
      expect(loadedPlan.totalCalories, 70);
      expect(loadedPlan.itemsFor(MealSlot.breakfast).first.name, 'Eggs');
    });

    test('clearPlan removes plan from local storage', () async {
      final date = DateTime(2025, 4, 4);
      final plan = DailyMealPlan(date: date);
      await MealStorage.savePlan(plan);

      var loaded = await MealStorage.loadPlan(date);
      expect(loaded.date, date);

      await MealStorage.clearPlan(date);

      // It should still return an empty plan for that date
      loaded = await MealStorage.loadPlan(date);
      expect(loaded.totalCalories, 0);
    });

    test('savedDates returns a list of sorted dates', () async {
      final date1 = DateTime(2025, 4, 4);
      final date2 = DateTime(2025, 4, 5);
      
      await MealStorage.savePlan(DailyMealPlan(date: date1));
      await MealStorage.savePlan(DailyMealPlan(date: date2));

      final dates = await MealStorage.savedDates();
      expect(dates.length, 2);
      expect(dates[0], date2); // Newest first
      expect(dates[1], date1);
    });

    test('savePlan persists locally even if backend save fails when logged in', () async {
      final date = DateTime(2025, 6, 6);
      // Make AuthService think we're logged in by populating secure storage
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'fake-token',
        'current_user': '{}',
      });

      final plan = DailyMealPlan(date: date, slots: {
        MealSlot.lunch: [const MealItem(id: 5, name: 'Salad', type: 'Veg', calories: 150)]
      });

      // The backend call will fail (no server). savePlan should throw, but local copy remains.
      try {
        await MealStorage.savePlan(plan);
        fail('Expected savePlan to throw due to backend failure');
      } catch (e) {
        // expected
      }

      final loaded = await MealStorage.loadPlan(date);
      expect(loaded.totalCalories, 150);
      expect(loaded.itemsFor(MealSlot.lunch).first.name, 'Salad');
    });

    test('savedDates ignores malformed keys and returns only valid dates', () async {
      final goodDate = DateTime(2025, 7, 7);
      final prefsInitial = {
        'meal_plan_guest-2025-07-07': DailyMealPlan(date: goodDate).toJson(),
        'meal_plan_guest-badkey': 'x',
        'some_other_key': 'y',
      };
      SharedPreferences.setMockInitialValues(prefsInitial);

      final dates = await MealStorage.savedDates();
      expect(dates.length, 1);
      expect(dates.first, goodDate);
    });

    test('loadPlan returns empty plan on corrupted JSON', () async {
      final date = DateTime(2025, 8, 8);
      const key = 'meal_plan_guest-2025-08-08';
      SharedPreferences.setMockInitialValues({key: 'not-a-json'});

      final loaded = await MealStorage.loadPlan(date);
      expect(loaded.totalCalories, 0);
    });
  });
}

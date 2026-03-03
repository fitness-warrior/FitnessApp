import 'dart:convert';
import 'meal_item.dart';

/// Meal slots available in a daily plan.
enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotLabel on MealSlot {
  String get label {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.dinner:
        return 'Dinner';
      case MealSlot.snack:
        return 'Snack';
    }
  }
}

/// A full daily meal plan containing items grouped by slot.
class DailyMealPlan {
  final DateTime date;
  final Map<MealSlot, List<MealItem>> slots;

  DailyMealPlan({
    required this.date,
    Map<MealSlot, List<MealItem>>? slots,
  }) : slots = slots ??
            {
              MealSlot.breakfast: [],
              MealSlot.lunch: [],
              MealSlot.dinner: [],
              MealSlot.snack: [],
            };

  double get totalCalories =>
      slots.values.expand((items) => items).fold(0, (s, i) => s + i.calories);

  List<MealItem> itemsFor(MealSlot slot) => slots[slot] ?? [];

  DailyMealPlan copyWithItem(MealSlot slot, MealItem item) {
    final updated = Map<MealSlot, List<MealItem>>.from(
      slots.map((k, v) => MapEntry(k, List<MealItem>.from(v))),
    );
    updated[slot]!.add(item);
    return DailyMealPlan(date: date, slots: updated);
  }

  DailyMealPlan copyWithoutItem(MealSlot slot, int index) {
    final updated = Map<MealSlot, List<MealItem>>.from(
      slots.map((k, v) => MapEntry(k, List<MealItem>.from(v))),
    );
    updated[slot]!.removeAt(index);
    return DailyMealPlan(date: date, slots: updated);
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'slots': slots.map(
          (k, v) => MapEntry(k.name, v.map((i) => i.toMap()).toList()),
        ),
      };

  factory DailyMealPlan.fromMap(Map<String, dynamic> map) {
    final rawSlots = map['slots'] as Map<String, dynamic>? ?? {};
    final parsedSlots = <MealSlot, List<MealItem>>{};
    for (final slot in MealSlot.values) {
      final raw = rawSlots[slot.name];
      if (raw is List) {
        parsedSlots[slot] =
            raw.map((e) => MealItem.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        parsedSlots[slot] = [];
      }
    }
    return DailyMealPlan(
      date: DateTime.parse(map['date'] as String),
      slots: parsedSlots,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DailyMealPlan.fromJson(String source) =>
      DailyMealPlan.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

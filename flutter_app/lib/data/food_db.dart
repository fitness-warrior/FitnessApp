import '../models/meal_item.dart';

/// Static food catalogue grouped by collection/category.
///
/// Mirrors the structure from the Python meal_plan.py backend.
/// Replace with a real API/database call when the backend is connected.
class FoodDb {
  FoodDb._();

  static const List<Map<String, dynamic>> _foods = [
    // ── Protein ───────────────────────────────────────────────────────────────
    {
      'id': 1,
      'name': 'Chicken Breast (100 g)',
      'type': 'Protein',
      'calories': 165,
      'collection': 'High Protein',
      'diet': 'non-veg'
    },
    {
      'id': 2,
      'name': 'Egg (1 large)',
      'type': 'Protein',
      'calories': 72,
      'collection': 'High Protein',
      'diet': 'veg'
    },
    {
      'id': 3,
      'name': 'Greek Yogurt (150 g)',
      'type': 'Protein',
      'calories': 100,
      'collection': 'High Protein',
      'diet': 'veg'
    },
    {
      'id': 4,
      'name': 'Tuna (100 g)',
      'type': 'Protein',
      'calories': 130,
      'collection': 'High Protein',
      'diet': 'non-veg'
    },
    {
      'id': 5,
      'name': 'Cottage Cheese (100 g)',
      'type': 'Protein',
      'calories': 98,
      'collection': 'High Protein',
      'diet': 'veg'
    },
    {
      'id': 6,
      'name': 'Salmon Fillet (100 g)',
      'type': 'Protein',
      'calories': 208,
      'collection': 'High Protein',
      'diet': 'non-veg'
    },
    // ── Carbs ─────────────────────────────────────────────────────────────────
    {
      'id': 7,
      'name': 'Brown Rice (100 g cooked)',
      'type': 'Carb',
      'calories': 112,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 8,
      'name': 'Oats (40 g dry)',
      'type': 'Carb',
      'calories': 150,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 9,
      'name': 'Sweet Potato (100 g)',
      'type': 'Carb',
      'calories': 86,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 10,
      'name': 'Whole-Wheat Bread (1 slice)',
      'type': 'Carb',
      'calories': 80,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 11,
      'name': 'Quinoa (100 g cooked)',
      'type': 'Carb',
      'calories': 120,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    // ── Fats ──────────────────────────────────────────────────────────────────
    {
      'id': 12,
      'name': 'Avocado (half)',
      'type': 'Fat',
      'calories': 120,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 13,
      'name': 'Almonds (30 g)',
      'type': 'Fat',
      'calories': 170,
      'collection': 'High Protein',
      'diet': 'veg'
    },
    {
      'id': 14,
      'name': 'Olive Oil (1 tbsp)',
      'type': 'Fat',
      'calories': 119,
      'collection': 'Mediterranean',
      'diet': 'veg'
    },
    {
      'id': 15,
      'name': 'Peanut Butter (2 tbsp)',
      'type': 'Fat',
      'calories': 190,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    // ── Vegetables ────────────────────────────────────────────────────────────
    {
      'id': 16,
      'name': 'Broccoli (100 g)',
      'type': 'Vegetable',
      'calories': 34,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    {
      'id': 17,
      'name': 'Spinach (100 g)',
      'type': 'Vegetable',
      'calories': 23,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    {
      'id': 18,
      'name': 'Cherry Tomatoes (100 g)',
      'type': 'Vegetable',
      'calories': 18,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    {
      'id': 19,
      'name': 'Bell Pepper (1 medium)',
      'type': 'Vegetable',
      'calories': 31,
      'collection': 'Mediterranean',
      'diet': 'veg'
    },
    {
      'id': 20,
      'name': 'Cucumber (100 g)',
      'type': 'Vegetable',
      'calories': 16,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    // ── Fruit ─────────────────────────────────────────────────────────────────
    {
      'id': 21,
      'name': 'Banana (1 medium)',
      'type': 'Fruit',
      'calories': 105,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 22,
      'name': 'Apple (1 medium)',
      'type': 'Fruit',
      'calories': 95,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 23,
      'name': 'Blueberries (100 g)',
      'type': 'Fruit',
      'calories': 57,
      'collection': 'Vegan',
      'diet': 'veg'
    },
    {
      'id': 24,
      'name': 'Orange (1 medium)',
      'type': 'Fruit',
      'calories': 62,
      'collection': 'Mediterranean',
      'diet': 'veg'
    },
    // ── Dairy ─────────────────────────────────────────────────────────────────
    {
      'id': 25,
      'name': 'Whole Milk (200 ml)',
      'type': 'Dairy',
      'calories': 122,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    {
      'id': 26,
      'name': 'Cheddar Cheese (30 g)',
      'type': 'Dairy',
      'calories': 120,
      'collection': 'Balanced',
      'diet': 'veg'
    },
    // ── Drinks ────────────────────────────────────────────────────────────────
    {
      'id': 27,
      'name': 'Whey Protein Shake (1 scoop)',
      'type': 'Protein',
      'calories': 120,
      'collection': 'High Protein',
      'diet': 'veg'
    },
    {
      'id': 28,
      'name': 'Black Coffee',
      'type': 'Drink',
      'calories': 2,
      'collection': 'Balanced',
      'diet': 'veg'
    },
  ];

  static const List<String> collections = [
    'All',
    'High Protein',
    'Vegan',
    'Balanced',
    'Mediterranean',
  ];

  /// All foods as [MealItem]s.
  static List<MealItem> all({String? dietPreference}) => _foods
      .where((m) => _allowByDiet(m, dietPreference))
      .map((m) => MealItem(
            id: m['id'] as int,
            name: m['name'] as String,
            type: m['type'] as String,
            calories: (m['calories'] as num).toDouble(),
          ))
      .toList();

  static bool _allowByDiet(Map<String, dynamic> food, String? dietPreference) {
    final normalized = dietPreference?.trim().toLowerCase() ?? '';
    if (normalized != 'veg' && normalized != 'vegetarian') return true;
    return (food['diet'] ?? 'veg').toString().toLowerCase() != 'non-veg';
  }

  /// Foods filtered by [collection] and/or [query] and/or [maxCalories].
  static List<MealItem> filter({
    String collection = 'All',
    String query = '',
    double? maxCalories,
    String? dietPreference,
  }) {
    return _foods
        .where((m) {
          if (!_allowByDiet(m, dietPreference)) return false;
          if (collection != 'All' && m['collection'] != collection)
            return false;
          if (query.isNotEmpty &&
              !(m['name'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase())) {
            return false;
          }
          if (maxCalories != null && (m['calories'] as num) > maxCalories) {
            return false;
          }
          return true;
        })
        .map((m) => MealItem(
              id: m['id'] as int,
              name: m['name'] as String,
              type: m['type'] as String,
              calories: (m['calories'] as num).toDouble(),
            ))
        .toList();
  }
}

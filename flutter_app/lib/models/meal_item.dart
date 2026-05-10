/// Represents a single food item that can be added to a meal slot.
class MealItem {
  final int id;
  final String name;
  final String type; // e.g. Protein, Carb, Fat, Vegetable …
  final double caloriesPer100g;
  final double grams;

  double get calories => (caloriesPer100g * grams) / 100.0;

  const MealItem({
    required this.id,
    required this.name,
    required this.type,
    required double calories,
    this.grams = 100,
  }) : caloriesPer100g = calories;

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem(
        id: map['id'] as int,
        name: map['name'] as String,
        type: map['type'] as String? ?? '',
        calories:
            ((map['calories_per_100g'] ?? map['calories']) as num).toDouble(),
        grams: (map['grams'] as num?)?.toDouble() ?? 100,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'grams': grams,
        'calories_per_100g': caloriesPer100g,
        'calories': calories,
      };

  MealItem copyWithGrams(double nextGrams) {
    return MealItem(
      id: id,
      name: name,
      type: type,
      calories: caloriesPer100g,
      grams: nextGrams,
    );
  }

  @override
  String toString() => '$name (${grams.toInt()} g, ${calories.toInt()} kcal)';
}

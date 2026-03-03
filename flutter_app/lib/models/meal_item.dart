/// Represents a single food item that can be added to a meal slot.
class MealItem {
  final int id;
  final String name;
  final String type; // e.g. Protein, Carb, Fat, Vegetable …
  final double calories;

  const MealItem({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
  });

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem(
        id: map['id'] as int,
        name: map['name'] as String,
        type: map['type'] as String? ?? '',
        calories: (map['calories'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'calories': calories,
      };

  @override
  String toString() => '$name (${calories.toInt()} kcal)';
}

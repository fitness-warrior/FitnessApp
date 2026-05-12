/// Represents a single food item that can be added to a meal slot.
enum QuantityUnit { g, ml }

extension QuantityUnitLabel on QuantityUnit {
  String get symbol {
    switch (this) {
      case QuantityUnit.g:
        return 'g';
      case QuantityUnit.ml:
        return 'ml';
    }
  }
}

QuantityUnit _quantityUnitFromRaw(dynamic raw) {
  final normalized = raw?.toString().trim().toLowerCase() ?? 'g';
  if (normalized == 'ml' ||
      normalized == 'milliliter' ||
      normalized == 'millilitre') {
    return QuantityUnit.ml;
  }
  return QuantityUnit.g;
}

class MealItem {
  final int id;
  final String name;
  final String type; // e.g. Protein, Carb, Fat, Vegetable …
  final double caloriesPer100Unit;
  final double quantity;
  final QuantityUnit unit;

  // Backward-compatible aliases used by existing UI/state code.
  double get caloriesPer100g => caloriesPer100Unit;
  double get grams => quantity;

  double get calories => (caloriesPer100Unit * quantity) / 100.0;

  const MealItem({
    required this.id,
    required this.name,
    required this.type,
    required double calories,
    double? quantity,
    double? grams,
    this.unit = QuantityUnit.g,
  })  : quantity = quantity ?? grams ?? 100,
        caloriesPer100Unit = calories;

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem(
        id: map['id'] as int,
        name: map['name'] as String,
        type: map['type'] as String? ?? '',
        calories: ((map['calories_per_100_unit'] ??
                map['calories_per_100g'] ??
                map['calories']) as num)
            .toDouble(),
        quantity:
            ((map['quantity'] ?? map['grams']) as num?)?.toDouble() ?? 100,
        unit: _quantityUnitFromRaw(map['quantity_unit'] ?? map['unit']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'quantity': quantity,
        'quantity_unit': unit.symbol,
        // Keep legacy keys for backward compatibility.
        'grams': quantity,
        'calories_per_100_unit': caloriesPer100Unit,
        'calories_per_100g': caloriesPer100Unit,
        'calories': calories,
      };

  MealItem copyWithQuantity({
    required double nextQuantity,
    QuantityUnit? nextUnit,
  }) {
    return MealItem(
      id: id,
      name: name,
      type: type,
      calories: caloriesPer100Unit,
      quantity: nextQuantity,
      unit: nextUnit ?? unit,
    );
  }

  MealItem copyWithGrams(double nextGrams) {
    return copyWithQuantity(nextQuantity: nextGrams, nextUnit: QuantityUnit.g);
  }

  @override
  String toString() =>
      '$name (${quantity.toInt()} ${unit.symbol}, ${calories.toInt()} kcal)';
}

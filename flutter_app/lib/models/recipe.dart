class Recipe {
  final int id;
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final String allergyInfo;
  final double calories;
  final String dietType;
  final String imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.allergyInfo,
    required this.calories,
    required this.dietType,
    required this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final name = (json['recipe_meal_name'] ?? json['name'] ?? '').toString();
    final allergyInfo = (json['recipe_allergy_info'] ?? '').toString();
    final dietType = (json['recipe_diet_type'] ?? '').toString();
    final imageUrl = (json['recipe_image_url'] ?? '').toString();

    final ingredients = _parseList(
      json['recipe_ingredients'] ?? json['ingredients'],
      splitOnComma: true,
    );
    final steps = _parseList(
      json['recipe_instructions'] ?? json['steps'],
      splitOnComma: false,
    );

    final caloriesRaw = json['recipe_calories'] ?? json['calories'] ?? 0;
    final calories = caloriesRaw is num ? caloriesRaw.toDouble() : 0.0;

    final idRaw = json['recipe_id'] ?? json['id'] ?? 0;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    return Recipe(
      id: id,
      name: name,
      ingredients: ingredients,
      steps: steps,
      allergyInfo: allergyInfo,
      calories: calories,
      dietType: dietType,
      imageUrl: imageUrl,
    );
  }

  static List<String> _parseList(dynamic raw, {required bool splitOnComma}) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return [];

    if (splitOnComma) {
      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final steps = text
        .split(RegExp(r'\.\s+|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return steps.isEmpty ? [text] : steps;
  }
}

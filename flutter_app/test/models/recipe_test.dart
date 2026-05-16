import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/recipe.dart';

void main() {
  group('Recipe Model Tests', () {
    test('fromJson creates a valid Recipe object', () {
      final Map<String, dynamic> json = {
        'recipe_id': 1,
        'recipe_meal_name': 'Test Recipe',
        'recipe_ingredients': ['Tomato', 'Onion', 'Salt'],
        'recipe_instructions': 'Chop vegetables. Mix together.',
        'recipe_allergy_info': 'None',
        'recipe_calories': 250.5,
        'recipe_diet_type': 'Vegan',
        'recipe_image_url': 'http://example.com/image.jpg',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 1);
      expect(recipe.name, 'Test Recipe');
      expect(recipe.ingredients, ['Tomato', 'Onion', 'Salt']);
      expect(recipe.steps, ['Chop vegetables', 'Mix together.']);
      expect(recipe.allergyInfo, 'None');
      expect(recipe.calories, 250.5);
      expect(recipe.dietType, 'Vegan');
      expect(recipe.imageUrl, 'http://example.com/image.jpg');
    });

    test('fromJson handles missing values with defaults', () {
      final recipe = Recipe.fromJson({});

      expect(recipe.id, 0);
      expect(recipe.name, '');
      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
      expect(recipe.allergyInfo, '');
      expect(recipe.calories, 0.0);
      expect(recipe.dietType, '');
      expect(recipe.imageUrl, '');
    });

    test('fromJson handles alternative keys', () {
      final Map<String, dynamic> json = {
        'id': '2',
        'name': 'Alternative Name',
        'ingredients': 'Apple, Banana, Orange',
        'steps': 'Step 1\nStep 2',
        'calories': 300,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 2);
      expect(recipe.name, 'Alternative Name');
      expect(recipe.ingredients, ['Apple', 'Banana', 'Orange']);
      expect(recipe.steps, ['Step 1', 'Step 2']);
      expect(recipe.calories, 300.0);
    });

    test('fromJson parses ingredients with comma split', () {
      final Map<String, dynamic> json = {
        'ingredients': 'Eggs, Milk , , Flour',
      };
      final recipe = Recipe.fromJson(json);
      expect(recipe.ingredients, ['Eggs', 'Milk', 'Flour']);
    });

    test('fromJson parses steps with newline and period split', () {
      final Map<String, dynamic> json = {
        'steps': 'Do this. Then do that.\nFinally do this',
      };
      final recipe = Recipe.fromJson(json);
      expect(recipe.steps, ['Do this', 'Then do that', 'Finally do this']);
    });
  });
}

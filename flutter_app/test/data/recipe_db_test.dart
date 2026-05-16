import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/data/recipe_db.dart';
import 'package:fitness_app_flutter/models/recipe.dart';
import '../helpers/http_mock.dart';

void main() {
  group('RecipeDb Tests', () {
    late RecipeDb recipeDb;

    setUp(() {
      recipeDb = RecipeDb.instance;
    });

    test('listRecipes returns a list of recipes on success', () async {
      final mockData = [
        {
          'recipe_id': 1,
          'recipe_meal_name': 'Recipe 1',
          'recipe_calories': 100,
        },
        {
          'recipe_id': 2,
          'recipe_meal_name': 'Recipe 2',
          'recipe_calories': 200,
        }
      ];

      HttpOverrides.global = FakeHttpOverrides((request) async {
        if (request.uri.path.endsWith('/recipes')) {
          return FakeHttpClientResponse(200, json.encode(mockData));
        }
        return FakeHttpClientResponse(404, 'Not Found');
      });

      final recipes = await recipeDb.listRecipes();

      expect(recipes.length, 2);
      expect(recipes[0].id, 1);
      expect(recipes[0].name, 'Recipe 1');
      expect(recipes[1].id, 2);
      expect(recipes[1].name, 'Recipe 2');

      HttpOverrides.global = null;
    });

    test('listRecipes returns empty list on failure', () async {
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(500, 'Server Error');
      });

      final recipes = await recipeDb.listRecipes();

      expect(recipes, isEmpty);

      HttpOverrides.global = null;
    });

    test('listRecipes returns empty list on exception', () async {
      HttpOverrides.global = FakeHttpOverrides((request) async {
        throw Exception('Network error');
      });

      final recipes = await recipeDb.listRecipes();

      expect(recipes, isEmpty);

      HttpOverrides.global = null;
    });

    test('getRecipe returns a recipe on success', () async {
      final mockData = {
        'recipe_id': 5,
        'recipe_meal_name': 'Specific Recipe',
        'recipe_calories': 300,
      };

      HttpOverrides.global = FakeHttpOverrides((request) async {
        if (request.uri.path.endsWith('/recipes/5')) {
          return FakeHttpClientResponse(200, json.encode(mockData));
        }
        return FakeHttpClientResponse(404, 'Not Found');
      });

      final recipe = await recipeDb.getRecipe(5);

      expect(recipe, isNotNull);
      expect(recipe!.id, 5);
      expect(recipe.name, 'Specific Recipe');

      HttpOverrides.global = null;
    });

    test('getRecipe returns null on failure', () async {
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(404, 'Not Found');
      });

      final recipe = await recipeDb.getRecipe(99);

      expect(recipe, isNull);

      HttpOverrides.global = null;
    });

    test('getRecipe returns null on exception', () async {
      HttpOverrides.global = FakeHttpOverrides((request) async {
        throw Exception('Network error');
      });

      final recipe = await recipeDb.getRecipe(99);

      expect(recipe, isNull);

      HttpOverrides.global = null;
    });
  });
}

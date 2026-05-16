import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/recipe.dart';
import 'package:fitness_app_flutter/views/recipe_list_page.dart';
import 'package:fitness_app_flutter/views/recipe_detail_page.dart';
import '../helpers/http_mock.dart';

void main() {
  group('Recipe Views Tests', () {
    tearDown(() {
      HttpOverrides.global = null;
    });

    final dummyRecipe = Recipe(
      id: 1,
      name: 'Salad',
      ingredients: ['Lettuce', 'Tomato'],
      steps: ['Wash', 'Cut', 'Mix'],
      calories: 250,
      dietType: 'Vegan',
      allergyInfo: 'None',
      imageUrl: '', // empty to avoid network image calls during test
    );

    testWidgets('RecipeDetailPage renders recipe details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecipeDetailPage(recipe: dummyRecipe),
        ),
      );

      expect(find.text('Salad'), findsOneWidget);
      expect(find.text('250 kcal'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(find.text('Lettuce'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Wash'), findsOneWidget);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Mix'), findsOneWidget);
    });

    testWidgets('RecipeDetailPage handles empty ingredients and steps', (WidgetTester tester) async {
      final emptyRecipe = Recipe(
        id: 2,
        name: 'Empty Dish',
        ingredients: [],
        steps: [],
        calories: 0,
        dietType: '',
        allergyInfo: 'Nuts',
        imageUrl: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeDetailPage(recipe: emptyRecipe),
        ),
      );

      expect(find.text('Empty Dish'), findsOneWidget);
      expect(find.text('No ingredients listed.'), findsOneWidget);
      expect(find.text('No steps listed.'), findsOneWidget);
      expect(find.text('Allergies: Nuts'), findsOneWidget);
    });

    testWidgets('RecipeListPage renders waiting, loaded states, and navigates on tap', (WidgetTester tester) async {
      final fakeRecipeList = [
        {
          'recipe_id': 10,
          'name': 'Pasta Bowl',
          'ingredients': 'Pasta, Sauce',
          'steps': 'Boil. Mix',
          'calories': 500,
          'recipe_diet_type': 'Vegetarian',
          'recipe_image_url': '',
        }
      ];

      HttpOverrides.global = FakeHttpOverrides((request) async {
        if (request.uri.path.endsWith('/recipes')) {
          return FakeHttpClientResponse(200, jsonEncode(fakeRecipeList));
        }
        return FakeHttpClientResponse(404, 'Not Found');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RecipeListPage(),
        ),
      );

      // Initial waiting state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // List loaded
      expect(find.text('Pasta Bowl'), findsOneWidget);
      expect(find.text('500 kcal • Vegetarian • 2 ingredients'), findsOneWidget);

      // Fling to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Tap on recipe card
      await tester.tap(find.text('Pasta Bowl'));
      await tester.pumpAndSettle();

      // Verified navigation to RecipeDetailPage
      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.text('Boil'), findsOneWidget);
    });

    testWidgets('RecipeListPage renders empty state on server error or empty list', (WidgetTester tester) async {
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(500, 'Server Error');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RecipeListPage(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No recipes available.'), findsOneWidget);
    });
  });
}

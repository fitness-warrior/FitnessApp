import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recipe.dart';

class RecipeDb {
  static final RecipeDb instance = RecipeDb._();
  RecipeDb._();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<List<Recipe>> listRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      debugPrint('Failed to load recipes: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      return [];
    }
  }

  Future<Recipe?> getRecipe(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recipe.fromJson(Map<String, dynamic>.from(data));
      }

      debugPrint('Failed to load recipe $id: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching recipe $id: $e');
      return null;
    }
  }
}

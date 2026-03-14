import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../data/demo_recipes.dart';

class RecipeListPage extends StatelessWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: demoRecipes.length,
        itemBuilder: (context, index) {
          final recipe = demoRecipes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(recipe.name),
              subtitle: Text('${recipe.ingredients.length} ingredients • ${recipe.steps.length} steps'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
              },
            ),
          );
        },
      ),
    );
  }
}
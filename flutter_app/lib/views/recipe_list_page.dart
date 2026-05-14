import 'package:flutter/material.dart';
import '../data/recipe_db.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = RecipeDb.instance.listRecipes();
  }

  Future<void> _refresh() async {
    setState(() {
      _recipesFuture = RecipeDb.instance.listRecipes();
    });
    await _recipesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Recipe>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load recipes.'));
            }

            final recipes = snapshot.data ?? [];
            if (recipes.isEmpty) {
              return const Center(child: Text('No recipes available.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final subtitleParts = <String>[];
                if (recipe.calories > 0) {
                  subtitleParts
                      .add('${recipe.calories.toStringAsFixed(0)} kcal');
                }
                if (recipe.dietType.isNotEmpty) {
                  subtitleParts.add(recipe.dietType);
                }
                subtitleParts.add('${recipe.ingredients.length} ingredients');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: recipe.imageUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(recipe.imageUrl),
                          )
                        : const CircleAvatar(child: Icon(Icons.restaurant)),
                    title: Text(recipe.name),
                    subtitle: Text(subtitleParts.join(' • ')),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailPage(recipe: recipe),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

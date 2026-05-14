import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = recipe.imageUrl.isNotEmpty;
    final hasAllergyInfo = recipe.allergyInfo.isNotEmpty &&
        recipe.allergyInfo.toLowerCase() != 'none';

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipe.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            if (hasImage) const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (recipe.calories > 0)
                  Chip(
                      label:
                          Text('${recipe.calories.toStringAsFixed(0)} kcal')),
                if (recipe.dietType.isNotEmpty)
                  Chip(label: Text(recipe.dietType)),
                if (hasAllergyInfo)
                  Chip(label: Text('Allergies: ${recipe.allergyInfo}')),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recipe.ingredients.isEmpty)
              const Text('No ingredients listed.'),
            ...recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ingredient)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparation Steps',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recipe.steps.isEmpty) const Text('No steps listed.'),
            ...recipe.steps.asMap().entries.map((entry) {
              final stepNumber = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text('$stepNumber'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

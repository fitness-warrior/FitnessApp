import 'package:flutter/material.dart';
import '../models/meal_item.dart';
import '../data/food_db.dart';

class FoodBrowserPage extends StatelessWidget {
  final List<String> allergies;
  final String dietPreference;

  const FoodBrowserPage({
    Key? key,
    this.allergies = const [],
    this.dietPreference = 'non-veg',
  }) : super(key: key);

  Future<MealItem?> _promptForGrams(BuildContext context, MealItem food) async {
    final controller = TextEditingController(text: '100');
    String? errorText;

    final picked = await showDialog<MealItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Set quantity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${food.caloriesPer100g.toInt()} kcal per 100 g',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity (g)',
                      hintText: 'e.g. 100',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final grams = double.tryParse(controller.text.trim());
                    if (grams == null || grams <= 0 || grams > 2000) {
                      setDialogState(() {
                        errorText = 'Enter a value between 1 and 2000.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, food.copyWithGrams(grams));
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final allergyKeywords = _buildAllergyKeywords(allergies);
    final foods = FoodDb.all(dietPreference: dietPreference)
        .where((food) => !_containsAllergen(food, allergyKeywords))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
      ),
      body: ListView.builder(
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _typeColor(food.type).withValues(alpha: 0.2),
              child: Text(
                food.type.isNotEmpty ? food.type[0] : '?',
                style: TextStyle(
                  color: _typeColor(food.type),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(food.name),
            subtitle: Text(
                '${food.type} • ${food.caloriesPer100g.toInt()} kcal / 100g'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () async {
              final withQuantity = await _promptForGrams(context, food);
              if (withQuantity != null && context.mounted) {
                Navigator.pop(context, withQuantity);
              }
            },
          );
        },
      ),
    );
  }

  bool _containsAllergen(MealItem food, Set<String> keywords) {
    if (keywords.isEmpty) return false;
    final hay = food.name.toLowerCase();
    for (final keyword in keywords) {
      if (hay.contains(keyword)) return true;
    }
    return false;
  }

  Set<String> _buildAllergyKeywords(List<String> allergies) {
    final keywords = <String>{};
    for (final allergy in allergies) {
      final normalized = allergy.trim().toLowerCase();
      if (normalized.isEmpty || normalized == 'none') continue;
      switch (normalized) {
        case 'milk':
          keywords.addAll(['milk', 'dairy', 'cheese', 'yogurt', 'whey']);
          break;
        case 'nuts':
          keywords.addAll(['nut', 'nuts', 'almond', 'peanut']);
          break;
        case 'eggs':
          keywords.addAll(['egg', 'eggs']);
          break;
        case 'soy':
          keywords.add('soy');
          break;
        case 'wheat':
          keywords.addAll(['wheat', 'bread', 'flour', 'gluten']);
          break;
        case 'shellfish':
          keywords.addAll(['shellfish', 'shrimp', 'crab', 'lobster']);
          break;
        default:
          keywords.add(normalized);
      }
    }
    return keywords;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Protein':
        return Colors.red;
      case 'Carb':
        return Colors.amber.shade700;
      case 'Fat':
        return Colors.orange;
      case 'Vegetable':
        return Colors.green;
      case 'Fruit':
        return Colors.pink;
      case 'Dairy':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}

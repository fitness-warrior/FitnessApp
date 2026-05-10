import 'package:flutter/material.dart';
import '../models/meal_item.dart';
import '../data/food_db.dart';

class FoodBrowserPage extends StatelessWidget {
  final List<String> allergies;

  const FoodBrowserPage({Key? key, this.allergies = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allergyKeywords = _buildAllergyKeywords(allergies);
    final foods = FoodDb.all()
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
            subtitle: Text('${food.type} • ${food.calories.toInt()} kcal'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () {
              Navigator.pop(context, food);
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

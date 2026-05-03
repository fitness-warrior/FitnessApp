import 'package:flutter/material.dart';
// ignore: unused_import
import '../models/meal_item.dart';
import '../data/food_db.dart';

class FoodBrowserPage extends StatelessWidget {
  const FoodBrowserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foods = FoodDb.all();

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

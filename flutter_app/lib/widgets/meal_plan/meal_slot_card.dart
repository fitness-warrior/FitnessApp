import 'package:flutter/material.dart';
import '../../models/daily_meal_plan.dart';
import '../../models/meal_item.dart';

class MealSlotCard extends StatelessWidget {
  final MealSlot slot;
  final List<MealItem> items;
  final void Function(int index)? onDeleteFood;
  final VoidCallback? onAddFood;

  const MealSlotCard({
    Key? key,
    required this.slot,
    required this.items,
    this.onDeleteFood,
    this.onAddFood,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slotCalories = items.fold<double>(0, (s, i) => s + i.calories);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Icon(_slotIcon(slot), color: _slotColor(slot), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddFood,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Food'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No foods added yet.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            )
          else
            ...items.map(_buildFoodRow),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${slotCalories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(MealItem food) {
    final typeColor = _typeColor(food.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                food.type.isNotEmpty ? food.type[0] : '?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  food.type,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            food.calories.toInt().toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 2),
          Text(
            'kcal',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red[200],
            onPressed: onDeleteFood != null 
                ? () => onDeleteFood!(items.indexOf(food))
                : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Color _slotColor(MealSlot s) {
    switch (s) {
      case MealSlot.breakfast:
        return Colors.orange;
      case MealSlot.lunch:
        return Colors.green;
      case MealSlot.dinner:
        return Colors.indigo;
      case MealSlot.snack:
        return Colors.pink;
    }
  }

  IconData _slotIcon(MealSlot s) {
    switch (s) {
      case MealSlot.breakfast:
        return Icons.wb_sunny_outlined;
      case MealSlot.lunch:
        return Icons.lunch_dining;
      case MealSlot.dinner:
        return Icons.dinner_dining;
      case MealSlot.snack:
        return Icons.apple;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Protein':
        return Colors.red;
      case 'Carb':
        return Colors.amber[700]!;
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
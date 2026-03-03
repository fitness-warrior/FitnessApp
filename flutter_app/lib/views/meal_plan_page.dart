import 'package:flutter/material.dart';
import '../models/daily_meal_plan.dart';
import '../models/meal_item.dart';
import '../widgets/common/header.dart';

class MealPlanPage extends StatelessWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  // ── Static demo data ────────────────────────────────────────────────────
  static final Map<MealSlot, List<MealItem>> _demoSlots = {
    MealSlot.breakfast: [
      const MealItem(id: 8,  name: 'Oats (40 g dry)',          type: 'Carb',      calories: 150),
      const MealItem(id: 2,  name: 'Egg (1 large)',             type: 'Protein',   calories: 72),
      const MealItem(id: 23, name: 'Blueberries (100 g)',       type: 'Fruit',     calories: 57),
    ],
    MealSlot.lunch: [
      const MealItem(id: 1,  name: 'Chicken Breast (100 g)',    type: 'Protein',   calories: 165),
      const MealItem(id: 7,  name: 'Brown Rice (100 g cooked)', type: 'Carb',      calories: 112),
      const MealItem(id: 16, name: 'Broccoli (100 g)',          type: 'Vegetable', calories: 34),
    ],
    MealSlot.dinner: [
      const MealItem(id: 6,  name: 'Salmon Fillet (100 g)',     type: 'Protein',   calories: 208),
      const MealItem(id: 9,  name: 'Sweet Potato (100 g)',      type: 'Carb',      calories: 86),
      const MealItem(id: 17, name: 'Spinach (100 g)',           type: 'Vegetable', calories: 23),
    ],
    MealSlot.snack: [
      const MealItem(id: 13, name: 'Almonds (30 g)',            type: 'Fat',       calories: 170),
      const MealItem(id: 22, name: 'Apple (1 medium)',          type: 'Fruit',     calories: 95),
    ],
  };

  double get _totalCalories => _demoSlots.values
      .expand((items) => items)
      .fold(0, (s, i) => s + i.calories);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: HeaderWithDropdown(
          title: 'My Meal',
          onMenuSelected: (value) {
            final route = '/${value.toLowerCase().replaceAll(' ', '_')}';
            const routes = {'/my_workout', '/my_meal'};
            if (routes.contains(route)) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
        ),
        actions: const [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear day',
            onPressed: null,
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: null,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DateAndCalorieHeader(
              label: 'Today',
              totalCalories: _totalCalories,
            ),
          ),
          for (final slot in MealSlot.values)
            SliverToBoxAdapter(
              child: _MealSlotCard(
                slot: slot,
                items: _demoSlots[slot] ?? [],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _DateAndCalorieHeader extends StatelessWidget {
  final String label;
  final double totalCalories;

  const _DateAndCalorieHeader({
    required this.label,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    const dailyTarget = 2000.0;
    final progress = (totalCalories / dailyTarget).clamp(0.0, 1.0);
    final over = totalCalories > dailyTarget;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: null),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: null),
              ],
            ),
            const SizedBox(height: 6),
            // Calorie info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${totalCalories.toInt()} kcal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: over ? Colors.red : Colors.green[700],
                  ),
                ),
                Text(
                  '/ ${dailyTarget.toInt()} kcal goal',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    over ? Colors.red : Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  final MealSlot slot;
  final List<MealItem> items;

  const _MealSlotCard({
    required this.slot,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final slotCalories = items.fold<double>(0, (s, i) => s + i.calories);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Theme(
        // Remove the ExpansionTile top border
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: CircleAvatar(
            backgroundColor: _slotColor(slot).withValues(alpha: 0.15),
            child: Icon(_slotIcon(slot), color: _slotColor(slot), size: 20),
          ),
          title: Text(
            slot.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${slotCalories.toInt()} kcal',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('No foods added yet.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              )
            else
              ...items.map((food) => ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          _typeColor(food.type).withValues(alpha: 0.15),
                      child: Text(
                        food.type.isNotEmpty ? food.type[0] : '?',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _typeColor(food.type)),
                      ),
                    ),
                    title: Text(food.name,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(food.type,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${food.calories.toInt()} kcal',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        // Delete icon — UI only, disabled
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red[200],
                          onPressed: null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )),
            // "Add food" button — UI only, disabled
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add food'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ),
          ],
        ),
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

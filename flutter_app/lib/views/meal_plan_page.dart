import 'package:flutter/material.dart';
import '../models/daily_meal_plan.dart';
import '../models/meal_item.dart';
import '../widgets/common/header.dart';
import '../widgets/common/navbar.dart';
import 'sign_up.dart';
import 'recipe_list_page.dart';
import '../widgets/meal_plan/date_calorie_header.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {

  // ── Static demo data ────────────────────────────────────────────────────
  final Map<MealSlot, List<MealItem>> _demoSlots = {
    MealSlot.breakfast: [
      const MealItem(
          id: 8, name: 'Oats (40 g dry)', type: 'Carb', calories: 150),
      const MealItem(
          id: 2, name: 'Egg (1 large)', type: 'Protein', calories: 72),
      const MealItem(
          id: 23, name: 'Blueberries (100 g)', type: 'Fruit', calories: 57),
    ],
    MealSlot.lunch: [
      const MealItem(
          id: 1,
          name: 'Chicken Breast (100 g)',
          type: 'Protein',
          calories: 165),
      const MealItem(
          id: 7,
          name: 'Brown Rice (100 g cooked)',
          type: 'Carb',
          calories: 112),
      const MealItem(
          id: 16, name: 'Broccoli (100 g)', type: 'Vegetable', calories: 34),
    ],
    MealSlot.dinner: [
      const MealItem(
          id: 6, name: 'Salmon Fillet (100 g)', type: 'Protein', calories: 208),
      const MealItem(
          id: 9, name: 'Sweet Potato (100 g)', type: 'Carb', calories: 86),
      const MealItem(
          id: 17, name: 'Spinach (100 g)', type: 'Vegetable', calories: 23),
    ],
    MealSlot.snack: [
      const MealItem(
          id: 13, name: 'Almonds (30 g)', type: 'Fat', calories: 170),
      const MealItem(
          id: 22, name: 'Apple (1 medium)', type: 'Fruit', calories: 95),
    ],
  };

  double get _totalCalories => _demoSlots.values
      .expand((items) => items)
      .fold(0, (s, i) => s + i.calories);

  double _caloriesForType(String type) => _demoSlots.values
      .expand((items) => items)
      .where((item) => item.type == type)
      .fold(0, (sum, item) => sum + item.calories);

  double get _proteinCalories => _caloriesForType('Protein');
  double get _carbCalories => _caloriesForType('Carb');
  double get _fatCalories => _caloriesForType('Fat');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: HeaderWithDropdown(
          title: 'My Meal',
          onMenuSelected: (value) {
            final route = '/${value.toLowerCase().replaceAll(' ', '_')}';
            const routes = {'/my_workout', '/my_meal', '/shop'};
            if (routes.contains(route)) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Browse Recipes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeListPage(),
                ),
              );
            },
          ),
          const IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear day',
            onPressed: null,
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignUpPage()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DateAndCalorieHeader(
              label: 'Today',
              totalCalories: _totalCalories,
              proteinCalories: _proteinCalories,
              carbCalories: _carbCalories,
              fatCalories: _fatCalories,
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
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
                  onPressed: null,
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
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
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
            onPressed: null,
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
  
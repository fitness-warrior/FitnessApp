import 'package:flutter/material.dart';
import '../models/daily_meal_plan.dart';
import '../models/meal_item.dart';
import '../widgets/common/header.dart';
import '../widgets/common/navbar.dart';
import 'sign_up.dart';
import 'recipe_list_page.dart';
import '../widgets/meal_plan/date_calorie_header.dart';
import '../widgets/meal_plan/meal_slot_card.dart';

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
              child: MealSlotCard(
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
  
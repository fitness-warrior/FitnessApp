import 'package:flutter/material.dart';
import '../models/daily_meal_plan.dart';
import '../models/meal_item.dart';
import '../services/meal_storage.dart';
import '../widgets/common/header.dart';
import '../widgets/common/navbar.dart';
import 'recipe_list_page.dart';
import 'profile_page.dart';
import '../widgets/meal_plan/date_calorie_header.dart';
import '../widgets/meal_plan/meal_slot_card.dart';
import 'food_browser_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  DateTime _selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DailyMealPlan _currentPlan = DailyMealPlan(date: DateTime.now());
  bool _loadingPlan = true;

  Map<MealSlot, List<MealItem>> _demoSlotsFor(DateTime date) => {
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
              id: 16,
              name: 'Broccoli (100 g)',
              type: 'Vegetable',
              calories: 34),
        ],
        MealSlot.dinner: [
          const MealItem(
              id: 6,
              name: 'Salmon Fillet (100 g)',
              type: 'Protein',
              calories: 208),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  DailyMealPlan _planFor(DateTime date, {bool useDemoTemplate = false}) {
    return DailyMealPlan(
      date: date,
      slots: useDemoTemplate ? _demoSlotsFor(date) : null,
    );
  }

  double get _totalCalories => _currentPlan.totalCalories;

  double _caloriesForType(String type) => _currentPlan.slots.values
      .expand((items) => items)
      .where((item) => item.type == type)
      .fold(0, (sum, item) => sum + item.calories);

  double get _proteinCalories => _caloriesForType('Protein');
  double get _carbCalories => _caloriesForType('Carb');
  double get _fatCalories => _caloriesForType('Fat');

  @override
  void initState() {
    super.initState();
    _loadPlanForDate(_selectedDate);
  }

  Future<void> _loadPlanForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    setState(() {
      _selectedDate = normalizedDate;
      _loadingPlan = true;
    });

    final plan = await MealStorage.loadPlan(normalizedDate);

    if (!mounted) return;
    setState(() {
      _currentPlan = plan;
      _loadingPlan = false;
    });
  }

  Future<void> _saveCurrentPlan(DailyMealPlan plan) async {
    setState(() {
      _currentPlan = plan;
    });
    await MealStorage.savePlan(plan);
  }

  void _deleteFood(MealSlot slot, int index) {
    final updatedPlan = _currentPlan.copyWithoutItem(slot, index);
    _saveCurrentPlan(updatedPlan);
  }

  void _clearDay() {
    final clearedPlan = _planFor(_selectedDate);
    _saveCurrentPlan(clearedPlan);
  }

  Future<void> _addFood(MealSlot slot) async {
    final selectedFood = await Navigator.push<MealItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodBrowserPage(),
      ),
    );

    if (selectedFood != null) {
      final updatedPlan = _currentPlan.copyWithItem(slot, selectedFood);
      await _saveCurrentPlan(updatedPlan);
    }
  }

  void _previousDay() {
    _loadPlanForDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDay() {
    _loadPlanForDate(_selectedDate.add(const Duration(days: 1)));
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final difference = selected.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == -1) return 'Yesterday';
    if (difference == 1) return 'Tomorrow';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = days[_selectedDate.weekday - 1];
    final month = months[_selectedDate.month - 1];

    return '$weekday, $month ${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPlan) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear day',
            onPressed: _clearDay,
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
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
              label: _getDateLabel(),
              totalCalories: _totalCalories,
              proteinCalories: _proteinCalories,
              carbCalories: _carbCalories,
              fatCalories: _fatCalories,
              onPreviousDay: _previousDay,
              onNextDay: _nextDay,
            ),
          ),
          for (final slot in MealSlot.values)
            SliverToBoxAdapter(
              child: MealSlotCard(
                slot: slot,
                items: _currentPlan.itemsFor(slot),
                onDeleteFood: (index) => _deleteFood(slot, index),
                onAddFood: () => _addFood(slot),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

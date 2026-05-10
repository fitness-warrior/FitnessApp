import 'package:flutter/material.dart';
import '../models/daily_meal_plan.dart';
import '../models/meal_item.dart';
import '../services/meal_storage.dart';
import '../services/recommendation_storage.dart';
import '../services/user_service.dart';
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
  double _dailyGoal = 2000.0;
  List<String> _allergies = const [];

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

  // ignore: unused_element
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
    _loadDailyGoal();
  }

  Future<void> _loadDailyGoal() async {
    final profile = await _loadFitnessProfile();
    final goal = _calculateDailyGoal(profile);
    final allergies = _extractAllergies(profile);
    if (!mounted) return;
    setState(() {
      _dailyGoal = goal ?? 2000.0;
      _allergies = allergies;
    });
  }

  Future<Map<String, dynamic>?> _loadFitnessProfile() async {
    Map<String, dynamic>? fitness;

    final cached = await RecommendationStorage.loadProfile();
    if (cached != null) {
      fitness = {
        'goal': cached.goal,
        'experience': cached.experience,
        'age': cached.age > 0 ? cached.age : null,
      };
    }

    final cachedQuestionnaire =
        await RecommendationStorage.loadQuestionnaireResponse();
    if (cachedQuestionnaire != null && cachedQuestionnaire.isNotEmpty) {
      fitness = {
        ...?fitness,
        ...cachedQuestionnaire,
      };
    }

    try {
      final apiFitness = await UserService.getQuestionnaireResponse()
          .timeout(const Duration(seconds: 4));
      if (apiFitness != null && apiFitness.isNotEmpty) {
        fitness = {
          ...?fitness,
          ...apiFitness,
        };
      }
    } catch (_) {
      // Keep cached values if API is unavailable
    }

    return fitness;
  }

  double? _calculateDailyGoal(Map<String, dynamic>? profile) {
    if (profile == null) return null;

    final age = _toInt(profile['age']) ?? _toInt(profile['body_age']) ?? 0;
    final height =
        _toDouble(profile['height']) ?? _toDouble(profile['body_height']);
    final weight =
        _toDouble(profile['weight']) ?? _toDouble(profile['body_weight']);
    if (age <= 0 || height == null || weight == null) return null;

    final meters = height / 100.0;
    if (meters <= 0) return null;

    final bmi = weight / (meters * meters);
    final bmiClass = _bmiCategory(bmi);
    final bmr = (10 * weight) + (6.25 * height) - (5 * age);
    final exp = profile['experience']?.toString() ??
        profile['body_experience']?.toString();
    final tdee = bmr * _experienceMultiplier(exp);

    final goal = _goalKey(
        profile['goal']?.toString() ?? profile['body_goal']?.toString());

    if (goal == 'weight_loss') {
      double deficit = 400;
      if (bmiClass == 'Overweight') deficit = 600;
      if (bmiClass == 'Obese') deficit = 800;

      final mealReduction = deficit * 0.6;
      return tdee - mealReduction;
    }

    if (goal == 'weight_gain') return tdee + 400;
    if (goal == 'build_muscle') return tdee + 250;
    return tdee;
  }

  double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  int? _toInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString());
  }

  String _bmiCategory(double? bmi) {
    if (bmi == null) return '—';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  double _experienceMultiplier(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('beginner')) return 1.3;
    if (s.contains('intermediate')) return 1.5;
    if (s.contains('advanced')) return 1.7;
    return 1.3;
  }

  String _goalKey(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('lose') || s.contains('fat_loss')) return 'weight_loss';
    if (s.contains('gain') || s.contains('weight_gain')) return 'weight_gain';
    if (s.contains('build') || s.contains('strength')) return 'build_muscle';
    if (s.contains('stay') || s.contains('general_fitness')) return 'stay_fit';
    return 'stay_fit';
  }

  List<String> _extractAllergies(Map<String, dynamic>? profile) {
    if (profile == null) return const [];
    final raw = profile['allergies'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
          .toList();
    }
    return const [];
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
        builder: (context) => FoodBrowserPage(allergies: _allergies),
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
        backgroundColor: Color(0xFF0D0D14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        foregroundColor: Colors.white,
        elevation: 0,
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
              dailyGoal: _dailyGoal,
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

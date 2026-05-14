import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/meal_plan/date_calorie_header.dart';

void main() {
  group('DateCalorieHeader Tests', () {

    testWidgets('Test 1: Current date displays correctly', (WidgetTester tester) async {
      // DateCalorieHeader rendered for current date
      const dateLabel = 'Tuesday, 13 May';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DateAndCalorieHeader(
                label: dateLabel,
                totalCalories: 0,
                proteinCalories: 0,
                carbCalories: 0,
                fatCalories: 0,
                dailyGoal: 2000,
              ),
            ),
          ),
        ),
      );

      // Current date displayed in the header
      expect(find.text(dateLabel), findsOneWidget);
    });

    testWidgets('Test 2: Calorie goal and progress display correctly', (WidgetTester tester) async {
      // DateCalorieHeader with consumed: 1200, goal: 2200
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DateAndCalorieHeader(
                label: 'Today',
                totalCalories: 1200,
                proteinCalories: 0,
                carbCalories: 0,
                fatCalories: 0,
                dailyGoal: 2200,
              ),
            ),
          ),
        ),
      );

      // Header shows calories consumed vs goal: "1200 / 2200 kcal"
      expect(find.text('1200 / 2200 kcal'), findsOneWidget);

      // Goal box shows '2200'
      expect(find.text('2200'), findsOneWidget);

      // Food (consumed) box shows '1200'
      expect(find.text('1200'), findsOneWidget);
    });

  });
}

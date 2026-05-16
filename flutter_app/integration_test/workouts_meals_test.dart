import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_app_flutter/views/workout_day_view.dart';
import 'package:fitness_app_flutter/widgets/meal_plan/meal_slot_card.dart';
import 'package:fitness_app_flutter/services/streak_service.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_app_flutter/models/daily_meal_plan.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workouts & Meals Flow Integration Tests', () {
    setUp(() {
      StreakService.client = MockClient((req) async => http.Response('{}', 200));
      UserStatsService.client = MockClient((req) async => http.Response('{"xp": 100}', 200));
    });

    testWidgets('ITC-002: Workout tracking end-to-end (UI flow)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: WorkoutDayView(
          dayName: 'Monday',
          routines: [
            {
              'routine_name': 'Push Day',
              'exercises': [
                {'exer_name': 'Bench Press', 'sets': 1, 'reps': 10}
              ]
            }
          ],
        ),
      ));
      await tester.pumpAndSettle();

      // Verify exercise appears
      expect(find.text('Bench Press'), findsOneWidget);

      // Enter reps and weight to simulate tracking
      await tester.enterText(find.byType(TextField).at(0), '10');
      await tester.enterText(find.byType(TextField).at(1), '60');
      
      // Tap checkbox to mark set complete
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Since all sets are complete, Finish Workout button should appear
      expect(find.text('Finish Workout'), findsOneWidget);

      // Finish workout button
      await tester.tap(find.text('Finish Workout'));
      await tester.pumpAndSettle();

      // Should show summary screen
      expect(find.textContaining('Great job crushing'), findsOneWidget);
    });

    testWidgets('ITC-003, ITC-004: Recipe and meal flows', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MealSlotCard(
            slot: MealSlot.breakfast,
            items: const [
              MealItem(id: 1, name: 'Oatmeal', type: 'Carbs', calories: 350)
            ],
            onDeleteFood: (index) {},
            onAddFood: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify meal info
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('350 kcal'), findsOneWidget);
    });
  });
}

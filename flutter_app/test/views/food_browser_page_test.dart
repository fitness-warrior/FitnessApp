import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/views/food_browser_page.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

class MockPopWrapper extends StatelessWidget {
  final Widget child;
  final ValueChanged<Object?> onPop;

  const MockPopWrapper({super.key, required this.child, required this.onPop});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (result != null) {
              onPop(result);
            }
          },
          child: child,
        ),
      ),
    );
  }
}

void main() {
  group('FoodBrowserPage Widget Tests', () {
    testWidgets('Renders food items and filters out allergens correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FoodBrowserPage(
            allergies: ['milk', 'nuts', 'eggs', 'soy', 'wheat', 'shellfish', 'custom_allergy'],
            dietPreference: 'non-veg',
          ),
        ),
      );

      expect(find.text('Add Food'), findsOneWidget);

      // Verify allergen filtering worked (e.g. Whole Milk should be filtered out)
      expect(find.text('Whole Milk (200 ml)'), findsNothing);
      expect(find.text('Almonds (30 g)'), findsNothing); // nuts
      expect(find.text('Egg (1 large)'), findsNothing); // eggs
      expect(find.text('Whole-Wheat Bread (1 slice)'), findsNothing); // wheat
    });

    testWidgets('Tapping food item opens quantity dialog and adding returns updated MealItem', (WidgetTester tester) async {
      MealItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: MockPopWrapper(
            onPop: (res) => returnedItem = res as MealItem?,
            child: const FoodBrowserPage(dietPreference: 'non-veg'),
          ),
        ),
      );

      // Tap on Chicken Breast (solid food, grams)
      await tester.tap(find.text('Chicken Breast (100 g)'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Set quantity'), findsOneWidget);

      // Enter invalid quantity to trigger validation error
      await tester.enterText(find.byType(TextField), '-50');
      await tester.tap(find.text('Add'));
      await tester.pump(); // stateful builder rebuild
      expect(find.text('Enter a value between 1 and 2000.'), findsOneWidget);

      // Enter valid quantity
      await tester.enterText(find.byType(TextField), '250');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verified returned item
      expect(returnedItem, isNotNull);
      expect(returnedItem!.name, 'Chicken Breast (100 g)');
      expect(returnedItem!.quantity, 250.0);
      expect(returnedItem!.unit, QuantityUnit.g);
    });

    testWidgets('Tapping drink item shows ml dropdown and returns item with ml unit', (WidgetTester tester) async {
      MealItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: MockPopWrapper(
            onPop: (res) => returnedItem = res as MealItem?,
            child: const FoodBrowserPage(
              dietPreference: 'non-veg',
              allergies: [
                'chicken', 'egg', 'yogurt', 'tuna', 'cheese', 'salmon',
                'rice', 'oats', 'potato', 'bread', 'quinoa', 'avocado',
                'almond', 'olive', 'peanut', 'broccoli', 'spinach',
                'tomato', 'pepper', 'cucumber', 'banana', 'apple',
                'blueberries', 'orange'
              ],
            ),
          ),
        ),
      );

      // Whole Milk (200 ml) is now at the top of the list
      expect(find.text('Whole Milk (200 ml)'), findsOneWidget);
      await tester.tap(find.text('Whole Milk (200 ml)'));
      await tester.pumpAndSettle();

      // Dialog opens with ml Dropdown displaying 'millilitres (ml)'
      expect(find.text('millilitres (ml)'), findsOneWidget);

      // Enter quantity 300
      await tester.enterText(find.byType(TextField), '300');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(returnedItem, isNotNull);
      expect(returnedItem!.name, 'Whole Milk (200 ml)');
      expect(returnedItem!.quantity, 300.0);
      expect(returnedItem!.unit, QuantityUnit.ml);
    });

    testWidgets('Cancel button dismisses quantity dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: const FoodBrowserPage(dietPreference: 'non-veg'),
        ),
      );

      await tester.tap(find.text('Chicken Breast (100 g)'));
      await tester.pumpAndSettle();

      expect(find.text('Set quantity'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Set quantity'), findsNothing);
    });
  });
}

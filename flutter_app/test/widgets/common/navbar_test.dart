import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/navbar.dart';

void main() {
  group('AppBottomNavBar Widget Tests', () {
    testWidgets('WTC-001: Renders all 4 navigation items with correct icons and labels', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
          ),
        ),
      );

      // Verify labels are visible
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify icons are visible
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });
}

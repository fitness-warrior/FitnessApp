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

    testWidgets('WTC-002: Active tab is highlighted', (WidgetTester tester) async {
      const activeColor = Color(0xFF4A9FFF);
      const inactiveColor = Color(0xFF6B6B80);

      // Build the widget with index 0 (Workout)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
          ),
        ),
      );

      // Find the 'Workout' text widget
      final workoutText = tester.widget<Text>(find.text('Workout'));
      
      // Verify color is active
      expect(workoutText.style?.color, equals(activeColor));

      // Find the 'Home' text widget
      final homeText = tester.widget<Text>(find.text('Home'));

      // Verify color is inactive
      expect(homeText.style?.color, equals(inactiveColor));
    });

    testWidgets('WTC-003: Tap triggers correct navigation', (WidgetTester tester) async {
      // Build the widget with routes to test navigation
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/my_workout',
          routes: {
            '/my_workout': (_) => const Scaffold(
                  bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
                ),
            '/dashboard': (_) => const Scaffold(
                  body: Text('Dashboard Page'),
                  bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
                ),
          },
        ),
      );

      // Verify we are on the workout page
      expect(find.text('Workout'), findsOneWidget);

      // Tap on 'Home' (index 1)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard happened
      expect(find.text('Dashboard Page'), findsOneWidget);
    });
  });
}

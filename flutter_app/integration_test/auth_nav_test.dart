import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_app_flutter/main.dart' as app;
import 'package:fitness_app_flutter/widgets/common/navbar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation & Auth Flow Integration Tests', () {
    testWidgets('ITC-001: Full onboarding end-to-end (Auth UI validation)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure we are at the auth screen
      expect(find.text('Log in to your account'), findsOneWidget);

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      
      // Tap sign up with empty data
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.text('Please fill all fields'), findsOneWidget);

      // Attempt with invalid email
      await tester.enterText(find.byType(TextField).at(0), 'bademail');
      await tester.enterText(find.byType(TextField).at(1), 'TestUser');
      await tester.enterText(find.byType(TextField).at(2), 'Password123!');
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('ITC-007 to ITC-011: Navigation components routing', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const Scaffold(
          body: Text('Initial Page'),
          bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
        ),
        routes: {
          '/my_workout': (_) => const Scaffold(
            body: Text('Workout View'),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
          ),
          '/dashboard': (_) => const Scaffold(
            body: Text('Dashboard View'),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
          ),
          '/my_meal': (_) => const Scaffold(
            body: Text('Meal View'),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
          ),
          '/profile': (_) => const Scaffold(
            body: Text('Profile View'),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
          ),
        },
      ));

      await tester.pumpAndSettle();

      // We are at initial page. Let's tap 'Home' (dashboard)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard View'), findsOneWidget);

      // Tap 'Nutrition' (meal plan)
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('Meal View'), findsOneWidget);

      // Tap 'Profile'
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile View'), findsOneWidget);

      // Tap 'Workout'
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Workout View'), findsOneWidget);
    });
  });
}

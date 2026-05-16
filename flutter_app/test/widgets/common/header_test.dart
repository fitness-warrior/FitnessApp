import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/header.dart';

void main() {
  group('HeaderWithDropdown Widget Tests', () {
    testWidgets('Renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderWithDropdown(
              title: 'Test Title',
              showMenu: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets('Renders menu icon when showMenu is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderWithDropdown(
              title: 'Dashboard',
              showMenu: true,
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('Opens menu and triggers callback on selection', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderWithDropdown(
              title: 'Dashboard',
              showMenu: true,
              onMenuSelected: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Tap the menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify menu items appear
      expect(find.text('My Workout'), findsOneWidget);
      expect(find.text('My Meal'), findsOneWidget);

      // Tap an item
      await tester.tap(find.text('My Workout'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'My Workout');
    });
  });
}

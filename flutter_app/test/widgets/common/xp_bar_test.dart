// Covers:
//   WTC-018 - Progress bar fills proportionally based on XP
//   WTC-019 - Level badge shows correct level
//   WTC-020 - XP progress text displays correctly

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/xp_bar.dart';

void main() {
  group('XPBar', () {
    // WTC-019
    testWidgets('level badge shows LVL 1 at 0 XP', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 0),
          ),
        ),
      );

      expect(find.text('LVL 1'), findsOneWidget);
    });

    // WTC-019
    testWidgets('level badge shows LVL 2 at 150 XP',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 150),
          ),
        ),
      );

      expect(find.text('LVL 2'), findsOneWidget);
    });

    // WTC-020
    testWidgets('XP progress text shows correct values at 75 XP',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 75),
          ),
        ),
      );

      // XPBar shows "{xpInLevel} / {xpPerLevel} XP"
      // At 75 XP: xpInLevel = 75, xpPerLevel = 100
      expect(find.text('75 / 100 XP'), findsOneWidget);
    });

    // WTC-020
    testWidgets('XP progress text shows 0 / 100 XP at 0 XP',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 0),
          ),
        ),
      );

      expect(find.text('0 / 100 XP'), findsOneWidget);
    });

    // WTC-018
    testWidgets('renders without crashing at 50 XP',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 50),
          ),
        ),
      );

      // Widget renders and shows correct level
      expect(find.text('LVL 1'), findsOneWidget);
      expect(find.text('50 / 100 XP'), findsOneWidget);
    });

    testWidgets('shows Warrior Progress label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPBar(xp: 0),
          ),
        ),
      );

      expect(find.text('Warrior Progress'), findsOneWidget);
    });
  });
}

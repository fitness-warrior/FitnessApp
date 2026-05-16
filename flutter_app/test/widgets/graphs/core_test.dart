import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/graphs/core.dart';
import 'package:fitness_app_flutter/graphs/bar_graph.dart';
import 'package:fitness_app_flutter/graphs/pie_chart.dart';
import 'package:fitness_app_flutter/graphs/line_chart.dart';

void main() {
  group('Core Graph Widget Tests', () {
    testWidgets('Core.pie renders a pie chart correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Core.pie(
              name: 'My Pie Chart',
              dataValues: const <double>[10.0, 20.0, 30.0, 40.0],
              labels: const ['A', 'B', 'C', 'D'],
            ),
          ),
        ),
      );

      expect(find.text('My Pie Chart'), findsOneWidget);
      expect(find.byType(MyPieChart), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Core.bar renders a bar chart correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Core.bar(
              name: 'My Bar Chart',
              dataValues: const <double>[5.0, 10.0, 15.0],
              start: 0.0,
              range: 20.0,
              x: 'X Axis',
              y: 'Y Axis',
            ),
          ),
        ),
      );

      expect(find.text('My Bar Chart'), findsOneWidget);
      expect(find.byType(MyBarGraph), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Core.line renders a line chart correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Core.line(
              name: 'My Line Chart',
              dataValues: const <double>[2.0, 4.0, 6.0],
              x: 'Days',
              y: 'Values',
            ),
          ),
        ),
      );

      expect(find.text('My Line Chart'), findsOneWidget);
      expect(find.byType(MyLineChart), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Dismissible feature works if onDismissed is provided', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Core.pie(
              name: 'Dismissible Pie',
              dataValues: const <double>[10.0, 0.0, 0.0, 0.0],
              labels: const ['Only', '', '', ''],
              onDismissed: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Dismissible Pie'), findsOneWidget);
      
      // Swipe to dismiss (end to start)
      await tester.drag(find.byType(Dismissible), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}

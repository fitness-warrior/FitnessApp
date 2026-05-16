import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitness_app_flutter/graphs/line_chart.dart';

void main() {
  group('MyLineChart Widget Tests', () {
    testWidgets('Renders empty state when dataPoints is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: MyLineChart(
                dataPoints: [],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('Renders LineChart when dataPoints are provided', (WidgetTester tester) async {
      final data = [10.0, 20.0, 15.0, 30.0];
      final dates = ['2025-01-01', '2025-01-02', '2025-01-03', '2025-01-04'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: MyLineChart(
                dataPoints: data,
                dates: dates,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      
      // Verify dates are visible. (The widget cuts off the first 5 chars '2025-')
      expect(find.text('01-01'), findsWidgets);
      expect(find.text('01-04'), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('Handles single data point without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: MyLineChart(
                dataPoints: [50.0],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Handles flat data (minY == maxY) without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: MyLineChart(
                dataPoints: [100.0, 100.0, 100.0],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}

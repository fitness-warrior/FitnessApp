import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitness_app_flutter/graphs/bar_graph.dart';

void main() {
  group('BarGraph Widget Tests', () {
    testWidgets('WTC-042 BarGraph bars render with correct data', (WidgetTester tester) async {
      final List<double> testData = [10.0, 15.0, 12.0, 20.0, 18.0, 25.0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: MyBarGraph(
                dataInt: testData,
                start: 15.0,
                range: 15.0,
                x: 'X Axis Label',
                y: 'Y Axis Label',
              ),
            ),
          ),
        ),
      );

      // Verify the BarChart widget is present
      expect(find.byType(BarChart), findsOneWidget);

      // Verify the data was passed correctly to the BarChart
      final barChartWidget = tester.widget<BarChart>(find.byType(BarChart));
      expect(barChartWidget.data.barGroups.length, equals(testData.length));
      
      // Verify specific data points
      for (int i = 0; i < testData.length; i++) {
        expect(barChartWidget.data.barGroups[i].barRods.first.toY, equals(testData[i]));
      }
    });

    testWidgets('WTC-043 BarGraph X & Y axis labels are displayed', (WidgetTester tester) async {
      const String xAxisLabel = 'Days';
      const String yAxisLabel = 'Weight (kg)';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: MyBarGraph(
                dataInt: [10.0, 20.0],
                start: 10.0,
                range: 20.0,
                x: xAxisLabel,
                y: yAxisLabel,
              ),
            ),
          ),
        ),
      );

      // Allow the layout and rendering to finish
      await tester.pumpAndSettle();

      // Find axis labels using exact text matches
      expect(find.text(xAxisLabel), findsOneWidget);
      expect(find.text(yAxisLabel), findsOneWidget);
    });
  });
}

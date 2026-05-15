import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitness_app_flutter/graphs/pie_chart.dart';

void main() {
  group('PieChart Widget Tests', () {
    testWidgets('WTC-044 PieChart renders segments with correct colors', (WidgetTester tester) async {
      final List<double> data = [10.0, 20.0, 30.0, 40.0];
      final List<String> labels = ['Cardio', 'Strength', 'Flexibility', 'Balance'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyPieChart(
              num: data,
              order: labels,
            ),
          ),
        ),
      );

      // Verify the PieChart widget is present
      expect(find.byType(PieChart), findsOneWidget);

      // Verify the PieChart has the correct number of sections
      final pieChartWidget = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChartWidget.data.sections.length, equals(4));

      // Verify the colors
      final expectedColors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
      for (int i = 0; i < 4; i++) {
        expect(pieChartWidget.data.sections[i].color, equals(expectedColors[i]));
        expect(pieChartWidget.data.sections[i].value, equals(data[i]));
      }
    });

    testWidgets('WTC-045 PieChart center text is displayed', (WidgetTester tester) async {
      final List<double> data = [10.0, 20.0, 30.0, 40.0];
      final List<String> labels = ['Cardio', 'Strength', 'Flexibility', 'Balance'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyPieChart(
              num: data,
              order: labels,
            ),
          ),
        ),
      );

      // Allow the layout and rendering to finish
      await tester.pumpAndSettle();

      // Find text labels from the legend
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}

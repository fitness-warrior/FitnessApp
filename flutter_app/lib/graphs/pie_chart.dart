import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyPieChart extends StatelessWidget {
  final List<double> num;
  final List<String> order;

  const MyPieChart({
    super.key,
    required this.num,
    required this.order,
  })  : assert(num.length >= 4, 'num must contain at least 4 values'),
        assert(order.length >= 4, 'order must contain at least 4 labels');

  @override
  Widget build(BuildContext context) {
    const sectionColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PieChart(
            swapAnimationDuration: const Duration(milliseconds: 500),
            PieChartData(
              sections: [
                PieChartSectionData(value: num[0], color: sectionColors[0]),
                PieChartSectionData(value: num[1], color: sectionColors[1]),
                PieChartSectionData(value: num[2], color: sectionColors[2]),
                PieChartSectionData(value: num[3], color: sectionColors[3]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: List.generate(4, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: sectionColors[index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(order[index]),
              ],
            );
          }),
        ),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyPieChart extends StatelessWidget {
  final List<double> num;
  final List<String> order;

  const MyPieChart({
    super.key,
    required this.num,
    required this.order,
  });
//if this does not work make all cardio leg
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
            duration: const Duration(milliseconds: 500),
            PieChartData(
              sections: [
                if (num[0] > 0) PieChartSectionData(value: num[0], color: sectionColors[0]),
                if (num[1] > 0) PieChartSectionData(value: num[1], color: sectionColors[1]),
                if (num[2] > 0) PieChartSectionData(value: num[2], color: sectionColors[2]),
                if (num[3] > 0) PieChartSectionData(value: num[3], color: sectionColors[3]),
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
            final label = order[index];
            if (label.isEmpty) {
              return const SizedBox.shrink();
            }
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
                Text(label),
              ],
            );
          }),
        ),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final List<String>? dates;
  final String yLabel;
  final String xLabel;

  const MyLineChart({
    Key? key,
    required this.dataPoints,
    this.dates,
    this.yLabel = '',
    this.xLabel = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (dates == null || value.toInt() >= dates!.length || value.toInt() < 0) {
                  return const Text('');
                }
                if (dates!.length > 5 && value.toInt() % (dates!.length ~/ 5) != 0) {
                  return const Text('');
                }
                
                final dateStr = dates![value.toInt()];
                String displayDate = dateStr;
                if (dateStr.length >= 10) {
                  displayDate = dateStr.substring(5); // MM-DD
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    displayDate,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4A9FFF),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4A9FFF).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

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
    double minY = double.maxFinite;
    double maxY = -double.maxFinite;

    for (int i = 0; i < dataPoints.length; i++) {
      final val = dataPoints[i];
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    if (minY == maxY) {
      minY = 0; // Always start at 0
      maxY = maxY + (maxY.abs() * 0.1) + 5.0;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY = 0; // Always start at 0
      maxY += padding;
    }

    return LineChart(
      LineChartData(
        minY: 0, // Ensure Y axis starts at 0
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
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
                  return const SizedBox.shrink();
                }
                
                final dateStr = dates![value.toInt()];
                String displayDate = dateStr;
                if (dateStr.length >= 10) {
                  displayDate = dateStr.substring(5);
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    displayDate,
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == minY || value == maxY) return const SizedBox.shrink();
                
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value > 1000 ? '${(value/1000).toStringAsFixed(1)}k' : value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: dataPoints.length > 2,
            color: const Color(0xFF4A9FFF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A9FFF).withValues(alpha: 0.3),
                  const Color(0xFF4A9FFF).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fitness_app_flutter/graphs/graph_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyBarGraph extends StatelessWidget{
  final List<double> dataInt;
  final double start;
  final double range;
  final String y;
  final String x;
  final List<String>? dates;

  const MyBarGraph({super.key,
  required this.dataInt,
  required this.start,
  required this.range,
  required this.y,
  required this.x,
    this.dates,
  });

  // i want to have control with having how many bars
  
  @override
  Widget build(BuildContext context) {
    // Create default dates if not provided
    final List<String> displayDates = dates ?? List.generate(dataInt.length, (i) => 'Day ${i + 1}');
    
    final BarData myBarData = BarData(
      values: dataInt,
      dates: displayDates,
    );

    // Populate the list used by barGroups.
    myBarData.singleDataData();

    return BarChart(
      BarChartData(
        maxY: (start + range).ceilToDouble(),
        minY: (start - range).ceilToDouble(),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            axisNameWidget: Text(x),
            axisNameSize: 24,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 4,
               getTitlesWidget: (value, meta) {
                 final index = value.toInt();
                 if (index >= 0 && index < displayDates.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       displayDates[index],
                       style: const TextStyle(fontSize: 9),
                       textAlign: TextAlign.center,
                     ),
                   );
                 }
                 return const SizedBox.shrink();
               },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(y),
            axisNameSize: 24,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if ((value - value.roundToDouble()).abs() > 0.001) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: start,
              color: const Color.fromARGB(255, 46, 64, 83),
              strokeWidth: 2,
              dashArray: [6, 4],
              
            ),
          ],
        ),
        barGroups: myBarData.barData.map(
          (data) => BarChartGroupData(
            x: data.x,
            barRods: [
              BarChartRodData(
                toY: data.y,
                color: const Color.fromARGB(255, 142, 202, 132),
                width: 20,
                borderRadius: BorderRadius.circular(4),
                
                ),
            ],
          )
        ).toList()
      )
    );
  }
  
}
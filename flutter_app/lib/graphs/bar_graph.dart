import 'package:fitness_app_flutter/graphs/graph_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyBarGraph extends StatelessWidget{
  final List<double> dataInt;
  final double start;
  final double range;

  const MyBarGraph({super.key,
  required this.dataInt,
  required this.start,
  required this.range,
  });
  
  @override
  Widget build(BuildContext context) {
    final BarData myBarData = BarData(
      data7: dataInt[0], 
      data6: dataInt[1], 
      data5: dataInt[2], 
      data4: dataInt[3], 
      data3: dataInt[4], 
      data2: dataInt[5], 
      data1: dataInt[6], 
      data0: dataInt[7]
    );

    // Populate the list used by barGroups.
    myBarData.singleDataData();

    return BarChart(
      BarChartData(
        maxY: (start + range).ceilToDouble(),
        minY: (start - range).ceilToDouble(),
        gridData: const FlGridData(show: false),
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
                borderRadius: BorderRadius.circular(4)
                ),
            ],
          )
        ).toList()
      )
    );
  }
  
}
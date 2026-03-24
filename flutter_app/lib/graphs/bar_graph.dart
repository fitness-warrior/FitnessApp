import 'package:fitness_app_flutter/graphs/bar_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyBarGraph extends StatelessWidget{
  final List<double> dataInt;
  final double start;

  const MyBarGraph({super.key,
  required this.dataInt,
  required this.start
  });
  
  @override
  Widget build(BuildContext context) {
    final BarData myBarData = BarData(
      week7amount: dataInt[0], 
      week6amount: dataInt[1], 
      week5amount: dataInt[2], 
      week4amount: dataInt[3], 
      week3amount: dataInt[4], 
      week2amount: dataInt[5], 
      week1amount: dataInt[6], 
      week0amount: dataInt[7]
    );

    // Populate the list used by barGroups.
    myBarData.singleDataData();

    return BarChart(
      BarChartData(
        maxY: start + 10,
        minY: start - 10,
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
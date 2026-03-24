import 'package:fitness_app_flutter/graphs/bar_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyBarGraph extends StatelessWidget{
  final List<double> dataInt;
  const MyBarGraph({super.key,
  required this.dataInt
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
        maxY: 100,
        minY: 80,
        gridData: const FlGridData(show: false),
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
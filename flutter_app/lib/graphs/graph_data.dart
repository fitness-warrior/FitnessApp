import 'package:fitness_app_flutter/graphs/single_data_point.dart';

class BarData {
  final List<double> values;
  final List<String> dates;

  BarData({
    required this.values,
    required this.dates,
  });

  List<SingleData> barData = [];

  void singleDataData() {
    barData = [];
    for (int i = 0; i < values.length; i++) {
      barData.add(SingleData(x: i, y: values[i]));
    }
  }
}
import 'package:fitness_app_flutter/graphs/single_data_point.dart';

class BarData {
  final double data7;
  final double data6;
  final double data5;
  final double data4;
  final double data3;
  final double data2;
  final double data1;
  final double data0;

  BarData({
    required this.data7,
    required this.data6,
    required this.data5,
    required this.data4,
    required this.data3,
    required this.data2,
    required this.data1,
    required this.data0,
  });

  List<SingleData> barData = [];

  void singleDataData() {
    barData = [
      SingleData(x: 0, y: data7),
      SingleData(x: 1, y: data6),
      SingleData(x: 2, y: data5),
      SingleData(x: 3, y: data4),
      SingleData(x: 4, y: data3),
      SingleData(x: 5, y: data2),
      SingleData(x: 6, y: data1),
      SingleData(x: 7, y: data0)
    ];
  }


}
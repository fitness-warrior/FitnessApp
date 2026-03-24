import 'package:fitness_app_flutter/graphs/single_data_point.dart';

class BarData {
  final double week7amount;
  final double week6amount;
  final double week5amount;
  final double week4amount;
  final double week3amount;
  final double week2amount;
  final double week1amount;
  final double week0amount;

  BarData({
    required this.week7amount,
    required this.week6amount,
    required this.week5amount,
    required this.week4amount,
    required this.week3amount,
    required this.week2amount,
    required this.week1amount,
    required this.week0amount,
  });

  List<SingleData> barData = [];

  void singleDataData() {
    barData = [
      SingleData(x: 0, y: week7amount),
      SingleData(x: 1, y: week6amount),
      SingleData(x: 2, y: week5amount),
      SingleData(x: 3, y: week4amount),
      SingleData(x: 4, y: week3amount),
      SingleData(x: 5, y: week2amount),
      SingleData(x: 6, y: week1amount),
      SingleData(x: 7, y: week0amount)
    ];
  }

}
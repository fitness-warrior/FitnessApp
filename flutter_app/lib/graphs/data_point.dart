import 'package:collection/collection.dart';

class DataPoint {
    final int x;
    final double y;

    DataPoint({
        required this.x,
        required this.y
    });
}


List<DataPoint> get dataPoint{
  final data = <double> [2,3,7,9,10,4];
  return data
  .mapIndexed(
    ((index,element)=> DataPoint(x: index, y: element)))
  .toList();
}
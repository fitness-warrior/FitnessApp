import 'package:flutter/material.dart';

class Core extends StatefulWidget {
  final String name;
  final String tableType;

  // pie-specific fields
  final List<int>? dataInt;
  final DateTime? start;
  final int? range;

  // bar-specific fields
  final int? numItems;
  final int? order;

  const Core.pie({
    super.key,
    required this.name,
    required this.dataInt,
    required this.start,
    required this.range,
  })  : numItems = null,
        order = null,
        tableType = 'pie';

  const Core.bar({
    super.key,
    required this.name,
    required this.numItems,
    required this.order,
  })  : dataInt = null,
        start = null,
        range = null,
        tableType = 'bar';
  
  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    )
  }
}


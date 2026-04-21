import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/graphs/bar_graph.dart';
import 'package:fitness_app_flutter/graphs/pie_chart.dart';

class Core extends StatefulWidget {
  final String name;
  final String tableType;
  final double? height;

  // common data used by either chart type
  final List<double>? dataValues;
  final double? start;
  final double? range;
  final List<String>? labels;

  /// Create a pie chart core card.
  ///
  /// `dataValues` are the slice values and `labels` are the corresponding labels.
  const Core.pie({
    super.key,
    required this.name,
    required List<double> dataValues,
    required List<String> labels,
    this.height,
  })  : dataValues = dataValues,
        labels = labels,
        start = null,
        range = null,
        tableType = 'pie';

  /// Create a bar chart core card.
  ///
  /// `dataValues` are the bar heights, `start` is the baseline, and `range` is
  /// the display range (max deviation) used by `MyBarGraph`.
  const Core.bar({
    super.key,
    required this.name,
    required List<double> dataValues,
    required this.start,
    required this.range,
    this.height,
  })  : dataValues = dataValues,
        labels = null,
        tableType = 'bar';
  
  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  @override
  Widget build(BuildContext context) {
    // Choose a sensible default height per chart type, but allow the caller to
    // override by passing `height` or constraining the widget with a
    // `SizedBox`/`Expanded`.
    final defaultHeight = widget.tableType == 'bar' ? 220.0 : 340.0;
    final containerHeight = widget.height ?? defaultHeight;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color.fromARGB(255, 76, 175, 80), width: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(builder: (ctx) {
              if (widget.tableType == 'bar') {
                return MyBarGraph(
                  dataInt: widget.dataValues ?? <double>[],
                  start: widget.start ?? 0.0,
                  range: widget.range ?? 0.0,
                );
              }

              // default to pie
              return MyPieChart(
                num: widget.dataValues ?? <double>[0.0, 0.0, 0.0, 0.0],
                order: widget.labels ?? <String>['A', 'B', 'C', 'D'],
              );
            }),
          ),
        ],
      ),
    );
  }
}


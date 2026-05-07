import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/graphs/bar_graph.dart';
import 'package:fitness_app_flutter/graphs/pie_chart.dart';

class Core extends StatefulWidget {
  final String name;
  final String tableType;
  final double? height;
  final VoidCallback? onDismissed;

  // common data used by either chart type
  final List<double>? dataValues;
  final double? start;
  final double? range;
  final String y;
  final String x;
  final List<String>? labels;

  /// Create a pie chart core card.
  ///
  /// `dataValues` are the slice values and `labels` are the corresponding labels.
  const Core.pie({
    super.key,
    required this.name,
    required this.dataValues,
    required this.labels,
    this.height,
    this.onDismissed,
  })  : start = null,
        range = null,
        y = "",
        x = "",
        tableType = 'pie';

  /// Create a bar chart core card.
  ///
  /// `dataValues` are the bar heights, `start` is the baseline, and `range` is
  /// the display range (max deviation) used by `MyBarGraph`.
  const Core.bar({
    super.key,
    required this.name,
    required this.dataValues,
    required this.start,
    required this.range,
    required this.y,
    required this.x,
    this.height,
    this.onDismissed,
  })  : labels = null,
        tableType = 'bar';
  
  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  @override
  Widget build(BuildContext context) {
    final defaultHeight = widget.tableType == 'bar' ? 220.0 : 340.0;
    final containerHeight = widget.height ?? defaultHeight;

    return Dismissible(
      key: widget.key ?? ValueKey('${widget.tableType}-${widget.name}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDismissed?.call(),
      child: Container(
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
            Text(
              widget.name, 
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 142, 202, 132)
              ),
              textAlign: TextAlign.left,
              ),

            const SizedBox(height: 20),
            Expanded(
              child: Builder(builder: (ctx) {

                if (widget.tableType == 'bar') {
                  return MyBarGraph(
                    dataInt: widget.dataValues ?? <double>[],
                    start: widget.start ?? 0.0,
                    range: widget.range ?? 0.0,
                    y: widget.y,
                    x: widget.x,
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
      ),
    );
  }
}
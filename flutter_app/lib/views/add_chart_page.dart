import 'package:flutter/material.dart';
import '../data/possible_chart.dart';


class AddChart extends StatefulWidget {
  const AddChart({Key? key}) : super(key: key);

  @override
  State<AddChart> createState() => _AddChartState();
}

class _AddChartState extends State<AddChart> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Chart'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: chartSelection.length,
        itemBuilder: (context, index) {
          final chart = chartSelection[index];
          final isExpanded = _expandedIndex == index;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(chart.name),
                  subtitle: Text('${chart.measure.length} options'),
                  trailing: Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right ,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                ),
                if (isExpanded) const Divider(height: 1),
                if (isExpanded)
                  ...chart.measure.map(
                    (option) => ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 32,
                        right: 16,
                      ),
                      title: Text(option),
                      onTap: () {
                        
                      },
                    ),
                  ),
              ],
            ),
          );

        },
      ),
    );
  }
}
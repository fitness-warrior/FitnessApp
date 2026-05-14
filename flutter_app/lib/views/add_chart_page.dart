import 'package:flutter/material.dart';
import '../models/chart_model.dart';
import '../services/chart_service.dart';


class AddChart extends StatefulWidget {
  final int bodyId;

  const AddChart({Key? key, required this.bodyId}) : super(key: key);

  @override
  State<AddChart> createState() => _AddChartState();
}

class _AddChartState extends State<AddChart> {
  int? _expandedIndex;
  List<Chart> _charts = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadChartOptions();
  }

  Future<void> _loadChartOptions() async {
    try {
      final options = await ChartService.getChartOptions(widget.bodyId);
      if (mounted) {
        setState(() {
          _charts = options;
          _isLoading = false;
          _loadError = options.isEmpty ? 'No completed exercises found yet.' : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading chart options: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Could not load chart options.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Chart'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: (_isLoading || _loadError != null) ? 1 : _charts.length,
        itemBuilder: (context, index) {
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (_loadError != null && _charts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
            );
          }

          final chart = _charts[index];
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
                        Navigator.pop(context, {
                          'chartName': chart.name,
                          'option': option,
                        });
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
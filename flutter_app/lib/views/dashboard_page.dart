import 'package:fitness_app_flutter/graphs/core.dart';
import 'package:fitness_app_flutter/views/add_chart_page.dart';
import 'package:fitness_app_flutter/widgets/common/streak_display.dart';
import 'package:flutter/material.dart';
import '../services/chart_service.dart';
import '../services/user_service.dart';
import '../widgets/questionnaire/questionnaire_widget.dart';
import '../widgets/common/navbar.dart';

class _ChartCard {
  final String id;
  final Widget Function(VoidCallback onDismissed) builder;

  const _ChartCard({required this.id, required this.builder});
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPage();
}

class _DashboardPage extends State<DashboardPage> {
  final double start = 92.1;
  final double range = 10;
  List<double> weight = [
    92.8,
    92.3,
    93.4,
    91.9,
    91.7,
    92.3,
    94.2,
    93.4,
  ];

  final double calStart = 0;
  List<double> cal = [
    240.1,
    110.54,
    -170.3,
    -220.5,
    91.7,
    -70.8,
    -330.2,
    -230.1,
  ];
  late double maxCalDeviation;

  List<double> target = [20.5, 28.9, 17.4, 24.1];

  List<String> order = [
    "legs",
    "back",
    "core",
    "arms",
  ];

  late List<_ChartCard> _charts;

  Future<int?> _resolveBodyId() async {
    try {
      final profile = await UserService.getUserProfile();
      return profile?['body_id'] as int?;
    } catch (e) {
      debugPrint('Failed to resolve body_id: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    maxCalDeviation = cal.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    _charts = [];
  }

  void _removeChart(String id) {
    setState(() {
      _charts.removeWhere((chart) => chart.id == id);
    });
  }

  Future<void> _addChartFromSelection(
      String chartName, String option, int bodyId) async {
    try {
      final chartId =
          '${chartName}_${option}'.replaceAll(' ', '_').toLowerCase();
      List<double> chartData = [];
      List<String> dates = [];
      String yLabel = '';

      if (chartName == 'track calories') {
        try {
          final data = await ChartService.getDailyCardioCalories(bodyId);
          chartData = ChartService.extractValues(data);
          dates = data.map((item) => item[0].toString()).toList();
          yLabel = 'calories';
        } catch (e) {
          debugPrint('Error loading cardio calories: $e');
          chartData = [100, 150, 200, 175, 225, 250, 180, 200];
          dates = List.generate(chartData.length, (i) => 'Day ${i + 1}');
          yLabel = 'calories';
        }
      } else if (chartName == 'cardio speed') {
        try {
          final data = await ChartService.getCardioSpeed(option, bodyId);
          chartData = ChartService.extractValues(data);
          dates = data.map((item) => item[0].toString()).toList();
          yLabel = 'speed (m/min)';
        } catch (e) {
          debugPrint('Error loading cardio speed: $e');
          chartData = [100, 120, 110, 130, 125, 140, 135, 150];
          dates = List.generate(chartData.length, (i) => 'Day ${i + 1}');
          yLabel = 'speed (m/min)';
        }
      } else if (chartName == 'cardio enduance') {
        try {
          final data = await ChartService.getCardioEndurance(option, bodyId);
          chartData = ChartService.extractValues(data);
          dates = data.map((item) => item[0].toString()).toList();
          yLabel = 'distance (km)';
        } catch (e) {
          debugPrint('Error loading cardio endurance: $e');
          chartData = [5.2, 5.5, 5.1, 6.0, 5.8, 6.2, 5.9, 6.5];
          dates = List.generate(chartData.length, (i) => 'Day ${i + 1}');
          yLabel = 'distance (km)';
        }
      } else if (chartName == 'total weight lifted' ||
          chartName == 'weight personal bests') {
        try {
          final data = await ChartService.getStrengthTotal(option, bodyId);
          chartData = ChartService.extractValues(data);
          dates = data.map((item) => item[0].toString()).toList();
          yLabel = 'weight (kg)';
        } catch (e) {
          debugPrint('Error loading strength total: $e');
          chartData = [80, 85, 82, 90, 88, 95, 92, 100];
          dates = List.generate(chartData.length, (i) => 'Day ${i + 1}');
          yLabel = 'weight (kg)';
        }
      } else if (chartName == 'weight') {
        try {
          final data = await ChartService.getWeight(bodyId);
          chartData = ChartService.extractValues(data);
          dates = data.map((item) => item[0].toString()).toList();
          yLabel = 'weight (kg)';
        } catch (e) {
          debugPrint('Error loading weight: $e');
          chartData = [0.0, 0.0];
          dates = ['current', 'past'];
          yLabel = 'weight (kg)';
        }
      } else if (chartName == 'body type') {
        try {
          final data = await ChartService.getBodyType(bodyId);
          chartData = ChartService.extractValues(data);
          // labels come from data first column
          final labels = data.map((item) => item[0].toString()).toList();

          final newChart = _ChartCard(
            id: '${chartId}-pie',
            builder: (onDismissed) => SizedBox(
              height: 320,
              child: Core.pie(
                key: ValueKey('$chartId-pie'),
                name: '$chartName',
                dataValues: chartData,
                labels: labels,
                onDismissed: onDismissed,
              ),
            ),
          );

          if (mounted) {
            setState(() {
              _charts.add(newChart);
            });
          }
          return;
        } catch (e) {
          debugPrint('Error loading body type: $e');
          chartData = [0, 0, 0, 0];
          dates = [];
        }
      }

      if (chartData.isEmpty) {
        chartData = [10, 12, 11, 13, 12, 14, 13, 15];
        dates = List.generate(chartData.length, (i) => 'Day ${i + 1}');
        yLabel = 'value';
      }

      final minVal = chartData.reduce((a, b) => a < b ? a : b);
      final maxVal = chartData.reduce((a, b) => a > b ? a : b);

      final isHistory = chartName.contains('cardio') || chartName.contains('weight') || chartName.contains('strength');

      final newChart = _ChartCard(
        id: chartId,
        builder: (onDismissed) => SizedBox(
          height: 300,
          child: isHistory 
            ? Core.line(
                key: ValueKey('$chartId-chart'),
                name: '$chartName - $option',
                dataValues: chartData,
                y: yLabel,
                x: 'days',
                dates: dates,
                onDismissed: onDismissed,
              )
            : Core.bar(
                key: ValueKey('$chartId-chart'),
                name: '$chartName - $option',
                dataValues: chartData,
                start: minVal * 0.9,
                range: maxVal * 1.1,
                y: yLabel,
                x: 'days',
                dates: dates,
                onDismissed: onDismissed,
              ),
        ),
      );

      if (mounted) {
        setState(() {
          _charts.add(newChart);
        });
      }
    } catch (e) {
      debugPrint('Error adding chart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding chart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('My Chart'),
            SizedBox(height: 2),
            Text(
              '<---- Swipe left to delete chart',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          const StreakDisplay(compact: true),
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add Chart',
            onPressed: () async {
              final bodyId = await _resolveBodyId();
              if (!mounted) return;
              if (bodyId == null) {
                final completed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const QuestionnairePage(isOnboarding: false),
                  ),
                );
                if (!mounted || completed != true) return;

                final refreshedBodyId = await _resolveBodyId();
                if (!mounted) return;
                if (refreshedBodyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Complete your profile first so chart options can load.',
                      ),
                    ),
                  );
                  return;
                }

                final refreshedResult =
                    await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddChart(bodyId: refreshedBodyId),
                  ),
                );
                if (refreshedResult != null) {
                  await _addChartFromSelection(
                    refreshedResult['chartName'] as String,
                    refreshedResult['option'] as String,
                    refreshedBodyId,
                  );
                }
                return;
              }

              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddChart(bodyId: bodyId),
                ),
              );
              if (result != null) {
                await _addChartFromSelection(
                  result['chartName'] as String,
                  result['option'] as String,
                  bodyId,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            if (_charts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Text(
                  'No charts yet. Use the Add Chart button to create a new chart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            for (final chart in _charts) ...[
              chart.builder(() => _removeChart(chart.id)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

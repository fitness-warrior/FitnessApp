import 'dart:async';
import 'package:fitness_app_flutter/graphs/core.dart';
import 'package:fitness_app_flutter/views/add_chart_page.dart';
import 'package:fitness_app_flutter/widgets/common/streak_display.dart';
import 'package:flutter/material.dart';
import '../services/chart_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/questionnaire/questionnaire_widget.dart';
import '../widgets/common/navbar.dart';

class _ChartCard {
  final String id;
  final String name;
  final String option;
  final Widget Function(VoidCallback onDismissed) builder;

  const _ChartCard({
    required this.id,
    required this.name,
    required this.option,
    required this.builder,
  });
}

class _ChartConfig {
  final String id;
  final String name;
  final String option;

  _ChartConfig({required this.id, required this.name, required this.option});
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
  List<_ChartCard> _todayCharts = [];
  final List<_ChartConfig> _manualConfigs = [];
  StreamSubscription? _chartSubscription;

  Future<int?> _resolveBodyId() async {
    final bodyId = await ChartService.getBodyId();
    return bodyId > 0 ? bodyId : 0;
  }

  @override
  void initState() {
    super.initState();
    maxCalDeviation = cal.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    _charts = [];
    _refreshAllCharts();

    _chartSubscription = ChartService.onChartsChanged.listen((_) {
      _refreshAllCharts();
    });
  }

  Future<void> _refreshAllCharts() async {
    await _loadTodayCharts();
    await _loadManualCharts();
  }

  Future<void> _loadManualCharts() async {
    final bodyId = await _resolveBodyId() ?? 0;
    
    // 1. Fetch saved configurations from persistent storage
    final currentUser = await AuthService.getCurrentUser();
    final userEmail = currentUser?['email'] ?? 'unknown';
    final saved = await ChartService.getSavedCharts(userEmail);
    
    // 2. Sync _manualConfigs state
    _manualConfigs.clear();
    for (final s in saved) {
      final name = s['name'] ?? '';
      final option = s['measure'] ?? '';
      final id = '${name}_${option}'.replaceAll(' ', '_').toLowerCase();
      _manualConfigs.add(_ChartConfig(id: id, name: name, option: option));
    }

    final List<_ChartCard> updatedManual = [];
    for (final config in _manualConfigs) {
      final card = await _createChartCard(config.name, config.option, bodyId, config.id);
      if (card != null) updatedManual.add(card);
    }

    if (mounted) {
      setState(() {
        _charts = updatedManual;
      });
    }
  }

  Future<void> _loadTodayCharts() async {
    try {
      final bodyId = await _resolveBodyId() ?? 0;
      
      final currentUser = await AuthService.getCurrentUser();
      final userEmail = currentUser?['email'] ?? 'unknown';
      
      final todayExers = await ChartService.getTodayExercises();
      final List<_ChartCard> cards = [];
      
      for (final exer in todayExers) {
        final name = exer['exer_name'] as String;
        final type = exer['exer_type'] as String;
        final chartName = type == 'cardio' ? 'cardio speed' : 'total weight lifted';
        
        // Check if user has hidden this specific today chart
        if (await ChartService.isChartHidden(userEmail, chartName, name)) {
          continue;
        }

        final chartId = 'today_${name}'.replaceAll(' ', '_').toLowerCase();
        
        final card = await _createChartCard(chartName, name, bodyId, chartId);
        if (card != null) cards.add(card);
      }
      
      if (mounted) {
        setState(() {
          _todayCharts = cards;
        });
      }
    } catch (e) {
      debugPrint('Error loading today charts: $e');
    }
  }

  Future<_ChartCard?> _createChartCard(String chartName, String option, int bodyId, String chartId) async {
    List<double> chartData = [];
    List<String> dates = [];
    String yLabel = '';
    
    try {
      if (chartName == 'cardio speed') {
        final data = await ChartService.getCardioSpeed(option, bodyId);
        chartData = ChartService.extractValues(data);
        dates = data.map((item) => item[0].toString()).toList();
        yLabel = 'speed (m/min)';
      } else if (chartName == 'total weight lifted' || chartName == 'weight personal bests') {
        final data = await ChartService.getStrengthTotal(option, bodyId);
        chartData = ChartService.extractValues(data);
        dates = data.map((item) => item[0].toString()).toList();
        yLabel = 'weight (kg)';
      } else if (chartName == 'track calories') {
        final data = await ChartService.getDailyCardioCalories(bodyId);
        chartData = ChartService.extractValues(data);
        dates = data.map((item) => item[0].toString()).toList();
        yLabel = 'calories';
      } else if (chartName == 'overall effort') {
        final data = await ChartService.getTotalVolume(bodyId);
        chartData = ChartService.extractValues(data);
        dates = data.map((item) => item[0].toString()).toList();
        yLabel = 'volume (kg*reps)';
      }

        if (chartData.isEmpty) return null;

        return _ChartCard(
          id: chartId,
          name: chartName,
          option: option,
          builder: (onDismissed) => Core.line(
            key: ValueKey(chartId),
            name: '$chartName - $option',
            dataValues: chartData,
            y: yLabel,
            x: 'days',
            dates: dates,
            onDismissed: onDismissed,
          ),
        );
      } catch (e) {
        return null;
      }
  }

  Future<void> _addChartFromSelection(
      String chartName, String option, int bodyId) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      final userEmail = currentUser?['email'] ?? 'unknown';
      
      await ChartService.saveChart(userEmail, bodyId, chartName, option);
      await _loadManualCharts();
    } catch (e) {
      debugPrint('Error adding chart: $e');
    }
  }

  Future<void> _removeChart(String chartName, String option) async {
    final currentUser = await AuthService.getCurrentUser();
    final userEmail = currentUser?['email'] ?? 'unknown';
    await ChartService.deleteChart(userEmail, chartName, option);
    await _loadManualCharts();
  }

  Future<void> _dismissTodayChart(String chartName, String option) async {
    final currentUser = await AuthService.getCurrentUser();
    final userEmail = currentUser?['email'] ?? 'unknown';
    await ChartService.hideChart(userEmail, chartName, option);
    await _loadTodayCharts();
  }

  Future<void> _triggerAddChart() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddChart(bodyId: 0),
      ),
    );
    if (result != null) {
      await _addChartFromSelection(
        result['chartName'] as String,
        result['option'] as String,
        0,
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
            onPressed: _triggerAddChart,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshAllCharts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              if (_todayCharts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Today's Progress",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                for (final chart in _todayCharts) ...[
                  chart.builder(() => _dismissTodayChart(chart.name, chart.option)),
                  const SizedBox(height: 12),
                ],
                const Divider(color: Colors.white10, height: 32),
              ],
              if (_charts.isEmpty && _todayCharts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Text(
                    'No charts yet. Use the Add Chart button to create a new chart or finish a workout to see today\'s progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

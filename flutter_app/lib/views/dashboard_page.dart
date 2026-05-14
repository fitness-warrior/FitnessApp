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
  late List<_ChartCard> _charts;
  List<_ChartCard> _allExerciseCharts = [];
  StreamSubscription? _chartSubscription;

  @override
  void initState() {
    super.initState();
    _charts = [];
    _refreshAllCharts();

    _chartSubscription = ChartService.onChartsChanged.listen((_) {
      _refreshAllCharts();
    });
  }

  @override
  void dispose() {
    _chartSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshAllCharts() async {
    await _loadAllExerciseCharts();
    await _loadManualCharts();
  }

  Future<int?> _resolveBodyId() async {
    try {
      final profile = await UserService.getUserProfile();
      return profile?['body_id'] as int?;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadManualCharts() async {
    final bodyId = await _resolveBodyId() ?? 0;
    final currentUser = await AuthService.getCurrentUser();
    final userEmail = currentUser?['email'] ?? 'unknown';
    final saved = await ChartService.getSavedCharts(userEmail);
    
    final List<_ChartCard> updatedManual = [];
    for (final s in saved) {
      final name = s['name'] ?? '';
      final option = s['measure'] ?? '';
      final id = '${name}_${option}'.replaceAll(' ', '_').toLowerCase();
      final card = await _createChartCard(name, option, bodyId, id);
      if (card != null) updatedManual.add(card);
    }

    if (mounted) {
      setState(() {
        _charts = updatedManual;
      });
    }
  }

  Future<void> _loadAllExerciseCharts() async {
    try {
      final bodyId = await _resolveBodyId() ?? 0;
      final allProgress = await ChartService.getAllExercisesProgress();
      final List<_ChartCard> cards = [];
      
      allProgress.forEach((exName, history) {
        final chartId = 'auto_${exName}'.replaceAll(' ', '_').toLowerCase();
        final values = history.map((e) => (e[1] as num).toDouble()).toList();
        final dates = history.map((e) => e[0].toString()).toList();

        if (values.isEmpty) return;

        double minVal = values.reduce((a, b) => a < b ? a : b);
        double maxVal = values.reduce((a, b) => a > b ? a : b);
        if (minVal == maxVal) {
          minVal *= 0.9;
          maxVal *= 1.1;
        }

        cards.add(_ChartCard(
          id: chartId,
          name: 'Progress',
          option: exName,
          builder: (onDismissed) => Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 250,
              child: Core.bar(
                key: ValueKey(chartId),
                name: exName,
                dataValues: values,
                start: (minVal + maxVal) / 2,
                range: (maxVal - minVal) / 2 + (maxVal * 0.1 + 1),
                y: 'kg',
                x: 'date',
                dates: dates,
                onDismissed: onDismissed,
              ),
            ),
          ),
        ));
      });
      
      if (mounted) {
        setState(() {
          _allExerciseCharts = cards;
        });
      }
    } catch (e) {
      debugPrint('Error loading auto charts: $e');
    }
  }

  Future<_ChartCard?> _createChartCard(String chartName, String option, int bodyId, String chartId) async {
    try {
      List<double> chartData = [];
      List<String> dates = [];
      String yLabel = 'kg';

      if (chartName == 'total weight lifted' || chartName == 'weight personal bests') {
        final data = await ChartService.getStrengthTotal(option, bodyId);
        chartData = data.map((e) => (e[1] as num).toDouble()).toList();
        dates = data.map((item) => item[0].toString()).toList();
      }

      if (chartData.isEmpty) return null;

      final minVal = chartData.reduce((a, b) => a < b ? a : b);
      final maxVal = chartData.reduce((a, b) => a > b ? a : b);

      return _ChartCard(
        id: chartId,
        name: chartName,
        option: option,
        builder: (onDismissed) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 250,
            child: Core.bar(
              key: ValueKey(chartId),
              name: '$chartName - $option',
              dataValues: chartData,
              start: (minVal + maxVal) / 2,
              range: (maxVal - minVal) / 2 + (maxVal * 0.1 + 1),
              y: yLabel,
              x: 'date',
              dates: dates,
              onDismissed: onDismissed,
            ),
          ),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void _removeChart(String id) {
    setState(() {
      _charts.removeWhere((c) => c.id == id);
      _allExerciseCharts.removeWhere((c) => c.id == id);
    });
  }

  Future<void> _triggerAddChart() async {
    final bodyId = await _resolveBodyId() ?? 0;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddChart(bodyId: bodyId),
      ),
    );
    if (result != null) {
      final currentUser = await AuthService.getCurrentUser();
      final userEmail = currentUser?['email'] ?? 'unknown';
      await ChartService.saveChart(userEmail, bodyId, result['chartName'], result['option']);
      _refreshAllCharts();
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
        title: const Text('Exercise Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const StreakDisplay(compact: true),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _triggerAddChart,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllCharts,
        backgroundColor: const Color(0xFF1C1C2E),
        color: Colors.greenAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_allExerciseCharts.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Automatic Exercise Charts",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                for (final chart in _allExerciseCharts) ...[
                  chart.builder(() => _removeChart(chart.id)),
                  const SizedBox(height: 16),
                ],
              ],
              if (_charts.isNotEmpty) ...[
                const Divider(color: Colors.white10, height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manual Charts",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                for (final chart in _charts) ...[
                  chart.builder(() => _removeChart(chart.id)),
                  const SizedBox(height: 16),
                ],
              ],
              if (_charts.isEmpty && _allExerciseCharts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center, size: 80, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        const Text('No charts found', style: TextStyle(color: Colors.white54, fontSize: 18)),
                        const Text('Finish an exercise to see your progress here!', style: TextStyle(color: Colors.white24)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

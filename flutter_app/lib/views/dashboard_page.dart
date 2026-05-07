import 'package:fitness_app_flutter/graphs/core.dart';
import 'package:fitness_app_flutter/views/recipe_list_page.dart';
import 'package:fitness_app_flutter/views/profile_page.dart';
import 'package:fitness_app_flutter/widgets/common/header.dart';
import 'package:fitness_app_flutter/widgets/common/streak_display.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    maxCalDeviation = cal.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    _charts = [
      _ChartCard(
        id: 'weight',
        builder: (onDismissed) => SizedBox(
          height: 200,
          child: Core.bar(
            key: const ValueKey('weight-chart'),
            name: 'Weight',
            dataValues: weight,
            start: start,
            range: range,
            y: 'weight (kg)',
            x: 'days',
            onDismissed: onDismissed,
          ),
        ),
      ),
      _ChartCard(
        id: 'calories',
        builder: (onDismissed) => SizedBox(
          height: 300,
          child: Core.bar(
            key: const ValueKey('calories-chart'),
            name: 'Calories',
            dataValues: cal,
            start: calStart,
            range: maxCalDeviation,
            y: 'calorie intake/defist',
            x: 'days',
            onDismissed: onDismissed,
          ),
        ),
      ),
      _ChartCard(
        id: 'targets',
        builder: (onDismissed) => SizedBox(
          height: 300,
          child: Core.pie(
            key: const ValueKey('targets-chart'),
            name: 'Targets',
            dataValues: target,
            labels: order,
            onDismissed: onDismissed,
          ),
        ),
      ),
    ];
  }

  void _removeChart(String id) {
    setState(() {
      _charts.removeWhere((chart) => chart.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        
        title: const Text('My Chart'),

        actions: [
          const StreakDisplay(compact: true),
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add Chart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeListPage(), //temp area
                ),
              );
            },
          ),

        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
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
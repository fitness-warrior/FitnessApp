import 'package:fitness_app_flutter/graphs/bar_graph.dart';
import 'package:fitness_app_flutter/graphs/pie_chart.dart';
import 'package:fitness_app_flutter/views/recipe_list_page.dart';
import 'package:fitness_app_flutter/widgets/common/header.dart';
import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';

/*
for weight
inputs type (week/month)

gets last 8 weeks or months of data 

line grath of weight +-10 of current 
if above 7 of the start, 5 in the direction of the graph headed 

*/

class DashboardPage extends StatefulWidget{
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPage();
}
class _DashboardPage extends State<DashboardPage> {
  //examples 
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

  final String title = "target";
  List<double> target = [
    20.5,
    28.9,
    17.4,
    24.1
  ];

  List<String> order = [
    "legs",
    "back",
    "core",
    "arms",
  ];

  @override
  void initState() {
    super.initState();
    maxCalDeviation = cal.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: HeaderWithDropdown(
          title: 'My Chart',
          onMenuSelected: (value) {
            final route = '/${value.toLowerCase().replaceAll(' ', '_')}';
            const routes = {'/my_workout', '/my_meal', '/shop'};
            if (routes.contains(route)) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
        ),
        actions: [
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
          const IconButton(
            icon: CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: null,
            tooltip: 'Profile',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: MyBarGraph(
                dataInt: weight,
                start: start,
                range: range,
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: MyBarGraph(
                dataInt: cal,
                start: calStart,
                range: maxCalDeviation,
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: MyPieChart(
                num: target,
                title: title,
                order: order,
              ),
            ),
          ],
        ),
      ),
      


      
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

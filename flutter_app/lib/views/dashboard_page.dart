import 'package:fitness_app_flutter/graphs/bar_graph.dart';
import 'package:fitness_app_flutter/views/recipe_list_page.dart';
import 'package:fitness_app_flutter/views/sign_up.dart';
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
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignUpPage()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),
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
        ],
      ),
      


      
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

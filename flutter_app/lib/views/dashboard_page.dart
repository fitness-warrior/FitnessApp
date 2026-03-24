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
  
  //example 
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



      body: const Center(
        child: Text(
          'Dashboard screen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        
      ),
      


      
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

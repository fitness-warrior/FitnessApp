import 'package:fitness_app_flutter/views/recipe_list_page.dart';
import 'package:fitness_app_flutter/views/sign_up.dart';
import 'package:fitness_app_flutter/widgets/common/header.dart';
import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

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

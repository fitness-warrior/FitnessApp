import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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

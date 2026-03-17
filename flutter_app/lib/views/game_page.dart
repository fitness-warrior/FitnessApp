import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';

class GamePage extends StatelessWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: const Center(
        child: Text(
          'Game screen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

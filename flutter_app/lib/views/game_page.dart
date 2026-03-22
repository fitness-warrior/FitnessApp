// lib/views/game_page.dart
//
// This is the main screen for the boss clicker game.
// Step 6.1: Setting up the barebones structure with an empty Scaffold.

import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';
import '../data/demo_bosses.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Hardcoded for now just to build the UI
  final int _bossIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Grab the current boss from our demo list
    final boss = demoBosses[_bossIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Dark fallback color
      body: Center(
        child: Text(
          'Fighting ${boss.name}...',
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      // Keeping the standard app bottom nav bar
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

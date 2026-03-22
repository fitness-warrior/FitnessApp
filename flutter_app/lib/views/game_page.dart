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
      body: Stack(
        children: [
          // 1. Full-screen background for the current boss
          Positioned.fill(
            child: Image.asset(
              boss.background,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
          
          // 2. A dark gradient overlay so the white text/HUD is readable 
          // against busy backgrounds, especially at the top and bottom.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000), // Darker at top for HUD
                    Color(0x44000000), // Mostly clear in the middle
                    Color(0x99000000), // Darker at bottom for player
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. The actual UI layout
          SafeArea(
            child: Column(
              children: [
                // Top HUD: Coins placeholder
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      // Hardcoded coin value for now
                      const Text('0', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Boost badges will go here later
                    ],
                  ),
                ),

                // Boss Name
                const SizedBox(height: 10),
                Text(
                  '⚔️ ${boss.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                
                // HP Bar Placeholder
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('HP', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      // Note: using hardcoded 100 for current HP for now
                      Text('100 / ${boss.maxHealth}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: LinearProgressIndicator(
                    value: 100 / boss.maxHealth, // hardcoded value for the UI skeleton
                    color: Colors.greenAccent,
                    backgroundColor: Colors.white24,
                    minHeight: 12,
                  ),
                ),

                // Timer Placeholder
                const SizedBox(height: 10),
                const Text(
                  '⏱️ 120 seconds left', // hardcoded to 120
                  style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                ),

                // The Battle Scene (Player and Boss) will go below here
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
      // Keeping the standard app bottom nav bar
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

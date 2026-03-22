// lib/views/game_page.dart
//
// This is the main screen for the boss clicker game.
// Step 6.1: Setting up the barebones structure with an empty Scaffold.

import 'package:flutter/material.dart';
import 'dart:async'; // Need this for the Timer
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
  
  // Default idle frame for the player
  final String _playerFrame = 'images/game_costume/game_chars/player_stances/character_idle.png';

  // --- Step 7.1: Timer Variables ---
  int _timeLeft = 120; // 2 minutes (120 seconds) default
  bool _isRoundRunning = false;
  Timer? _roundTimer;

  // Cleanup: Important to cancel timers when leaving the page!
  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  // Starts the countdown
  void _startRound() {
    setState(() {
      _timeLeft = 120;
      _isRoundRunning = true;
    });

    _roundTimer?.cancel(); // cancel any old timer just in case
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Time ran out!
          _isRoundRunning = false;
          _roundTimer?.cancel();
          // TODO: Game Over Logic
          print("Time's up!");
        }
      });
    });
  }

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

                // Timer text (now wired to state!)
                const SizedBox(height: 10),
                Text(
                  '⏱️ $_timeLeft seconds left',
                  style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                ),

                // Main Battle Scene (Boss and Player standing side-by-side)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Make characters take up a good chunk of the screen height
                      final charSize = (constraints.maxHeight * 0.45).clamp(120.0, 250.0);
                      
                      return Stack(
                        children: [
                          // Player (bottom left)
                          Positioned(
                            left: 20,
                            bottom: 60, // floating a bit above the start button
                            child: Image.asset(
                              _playerFrame,
                              width: charSize,
                              height: charSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none, // keeps pixel art crisp!
                            ),
                          ),

                          // Boss (bottom right)
                          Positioned(
                            right: 20,
                            bottom: 60, // same bottom value = same ground level!
                            child: Image.asset(
                              boss.imagePath,
                              width: charSize,
                              height: charSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              // If we don't have the boss image yet, show a fallback icon
                              errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: charSize, color: Colors.redAccent),
                            ),
                          ),

                          // Start Button
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 10,
                            child: ElevatedButton(
                              // Only allow starting if the round isn't already running
                              onPressed: _isRoundRunning ? null : _startRound,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRoundRunning ? Colors.grey : Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isRoundRunning ? 'Round in progress...' : 'Start Round',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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

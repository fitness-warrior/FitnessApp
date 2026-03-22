// lib/views/game_page.dart
//
// This is the main screen for the boss clicker game.
// Step 6.1: Setting up the barebones structure with an empty Scaffold.

import 'package:flutter/material.dart';
import 'dart:async'; // Need this for the Timer
import 'dart:math';  // Step 8.2: Need this for the sine wave shake math
import '../widgets/common/navbar.dart';
import '../data/demo_bosses.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  // Hardcoded for now just to build the UI
  final int _bossIndex = 0;
  
  // --- Step 8.1: Health tracking ---
  int _bossHp = 0; // Will be set to max health when round starts
  
  // Default idle frame for the player
  final String _playerFrame = 'images/game_costume/game_chars/player_stances/character_idle.png';

  // --- Step 7.1: Timer Variables ---
  int _timeLeft = 120; // 2 minutes (120 seconds) default
  bool _isRoundRunning = false;
  Timer? _roundTimer;

  // --- Step 8.2: Boss Shake Animation ---
  // Using 'late' because we need 'this' (the TickerProvider) to initialize them in initState.
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    
    // The controller runs for a split second (150ms)
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
        
    // A simple 0 -> 1 curve we'll use to drive a sine wave offset
    _shake = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  // Cleanup: Important to cancel timers when leaving the page!
  @override
  void dispose() {
    _roundTimer?.cancel();
    _shakeCtrl.dispose(); // Don't forget to clean up controllers too!
    super.dispose();
  }

  // Starts the countdown
  void _startRound() {
    setState(() {
      _timeLeft = 120;
      _isRoundRunning = true;
      _bossHp = demoBosses[_bossIndex].maxHealth; // Reset HP to full!
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

  // --- Step 8.1: Tap logic ---
  void _onTap() {
    // Only deal damage if the round is actually running and boss is alive
    if (!_isRoundRunning || _bossHp <= 0) return;

    setState(() {
      _bossHp -= 10; // 10 damage per tap for now
      
      // Step 8.2: Trigger the shake animation from the beginning whenever hit
      _shakeCtrl.forward(from: 0.0);
      
      if (_bossHp <= 0) {
        _bossHp = 0;
        _isRoundRunning = false;
        _roundTimer?.cancel();
        // TODO: Victory Logic
        print("Boss Defeated!");
      }
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
                
                // HP Bar Placeholder (now wired to state!)
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('HP', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text('$_bossHp / ${boss.maxHealth}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: LinearProgressIndicator(
                    // Protect against division by zero just in case
                    value: boss.maxHealth > 0 ? (_bossHp / boss.maxHealth).clamp(0.0, 1.0) : 0.0, 
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

                // Main Battle Scene
                Expanded(
                  child: GestureDetector(
                    onTap: _onTap, // Tapping anywhere in here damages the boss!
                    behavior: HitTestBehavior.opaque, // Ensures taps register anywhere in the box
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
                            // Step 8.2: Wrap the image in an AnimatedBuilder
                            child: AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) {
                                // Translate pushes the widget left/right using a sine wave
                                // Notice the dart:math pi import at the top!
                                return Transform.translate(
                                  // Shake gets smaller as the animation reaches 1.0
                                  offset: Offset((1 - _shake.value) * 15 * sin(_shake.value * pi * 4), 0),
                                  child: child,
                                );
                              },
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
                ), // Close GestureDetector
              ), // Close Expanded
            ],
          ), // Close Column
        ), // Close SafeArea
      ],
      ),
      // Keeping the standard app bottom nav bar
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

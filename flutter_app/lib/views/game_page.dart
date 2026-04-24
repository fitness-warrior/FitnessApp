// lib/views/game_page.dart
//
// This is the main screen for the boss clicker game.
// Step 6.1: Setting up the barebones structure with an empty Scaffold.

import 'package:flutter/material.dart';
import 'dart:async'; // Need this for the Timer
import 'dart:math';  // Step 8.2: Need this for the sine wave shake math
import '../widgets/common/navbar.dart';
import '../data/demo_bosses.dart';
import '../models/game_state.dart';      // Step 11
import '../services/game_storage.dart';  // Step 11

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  // --- Step 11 & 12: Game State & Progression ---
  GameState _state = GameState(); // Player's inventory/coins
  int _bossIndex = 0;             // Which boss we're fighting
  bool _showVictory = false;      // Should we show the "You Win" overlay?
  bool _showGameOver = false;     // Step 12: Time ran out!
  bool _allDefeated = false;      // Did they beat the final boss?
  
  // --- Step 8.1: Health tracking ---
  int _bossHp = 0; // Will be set to max health when round starts
  
  // --- Step 9 & 16: Player Animation & Costumes ---
  String _playerFrame = ''; // Set dynamically in _loadState
  bool _isAnimating = false; // prevents animation from glitching if clicked too fast

  // --- Step 10: Floating Damage Numbers ---
  final List<Map<String, dynamic>> _damages = [];
  int _dmgCounter = 0; // used to give each damage text a unique Key

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
    _loadState(); // Step 11: Load player save data
    
    // The controller runs for a split second (150ms)
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
        
    // A simple 0 -> 1 curve we'll use to drive a sine wave offset
    _shake = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  // --- Step 11 & 16: Loading Save Data ---
  Future<void> _loadState() async {
    final state = await GameStorage.load();
    if (!mounted) return;
    setState(() {
      _state = state;
      _playerFrame = _getFramePath('idle'); // Set their equipped costume on load!
    });
  }

  // --- Step 16: Dynamic Costume Path Generator ---
  String _getFramePath(String action) {
    // If they have nothing equipped (or ""), use the default 'character' prefix.
    // Otherwise, use the costume key (e.g. 'earth', 'water').
    final prefix = (_state.equippedCostume?.isNotEmpty == true) 
        ? _state.equippedCostume! 
        : 'character';
    return 'images/game_costume/game_chars/player_stances/${prefix}_$action.png';
  }

  // Cleanup: Important to cancel timers when leaving the page!
  @override
  void dispose() {
    _roundTimer?.cancel();
    _shakeCtrl.dispose(); // Don't forget to clean up controllers too!
    super.dispose();
  }

  // Starts a completely fresh 120-second arcade run
  void _startRun() {
    setState(() {
      // Step 18: Timer only resets when explicitly starting a new run
      _timeLeft = 120 + _state.timeBonus;
      _bossIndex = 0;
      _allDefeated = false;
    });
    _startBoss();
  }

  // Starts/Resumes the timer for the current boss without resetting the clock
  void _startBoss() {
    setState(() {
      _isRoundRunning = true;
      _bossHp = demoBosses[_bossIndex].maxHealth; // Reset HP to full!
    });

    _roundTimer?.cancel(); // cancel any old timer just in case
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          
          // --- Step 14: Auto Clicker Logic ---
          if (_state.hasAutoClick && _bossHp > 0) {
            final autoDmg = 5; // As defined in the shop
            _bossHp -= autoDmg;
            
            // Trigger animation & damage popup just like a real tap
            _triggerAttackAnimation();
            _shakeCtrl.forward(from: 0.0);
            
            final rnd = Random();
            _damages.add({
              'id': ValueKey(_dmgCounter++),
              'pos': Offset(220.0 + rnd.nextInt(60), 350.0 + rnd.nextInt(40)),
              'dmg': autoDmg,
            });
            
            _checkVictory(); // check if the auto clicker killed the boss
          }
          
        } else {
          // --- Step 12: Time ran out, Game Over ---
          _isRoundRunning = false;
          _showGameOver = true;
          _roundTimer?.cancel();
        }
      });
    });
  }

  // --- Step 9 & 16: Stop Motion Animation ---
  Future<void> _triggerAttackAnimation() async {
    // Don't interrupt an animation that's already playing
    if (_isAnimating) return;
    _isAnimating = true;
    
    // Frame 1: Wind up
    setState(() => _playerFrame = _getFramePath('3'));
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Frame 2: Swing
    setState(() => _playerFrame = _getFramePath('2'));
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Frame 3: Follow through
    setState(() => _playerFrame = _getFramePath('1'));
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Back to Idle
    setState(() {
      _playerFrame = _getFramePath('idle');
      _isAnimating = false;
    });
  }

  // --- Step 8.1 & 9: Tap logic ---
  void _onTap() {
    // Only deal damage if the round is actually running and boss is alive
    if (!_isRoundRunning || _bossHp <= 0) return;

    _triggerAttackAnimation(); // Play the player swing animation!

    setState(() {
      // Step 14: Use the player's true tapped damage
      final dmg = _state.tapDamage; 
      _bossHp -= dmg; 
      
      // Step 8.2: Trigger the shake animation from the beginning whenever hit
      _shakeCtrl.forward(from: 0.0);

      // Step 10: Spawn a floating damage number
      // Generate some light randomness so they don't all stack perfectly on top of each other
      final rnd = Random();
      // Roughly placing it on the right side of the screen over the boss
      final startPos = Offset(
        220.0 + rnd.nextInt(60), // X coordinate
        350.0 + rnd.nextInt(40), // Y coordinate
      );
      
      _damages.add({
        'id': ValueKey(_dmgCounter++),
        'pos': startPos,
        'dmg': dmg,
      });
      
      _checkVictory();
    });
  }

  // Extracted this into a helper method because we need to call it from
  // both _onTap and the AutoClicker timer.
  void _checkVictory() {
    if (_bossHp <= 0) {
      _bossHp = 0;
      _isRoundRunning = false;
      _roundTimer?.cancel();
      
      // --- Step 11: Boss Defeated Reward Logic ---
      _showVictory = true;
      final boss = demoBosses[_bossIndex];
      _state.coins += boss.coinReward;
      _state.ownedCostumes.add(boss.rewardCostume);

      // Check if they just beat the final boss (Index 2 is Fry King)
      if (_bossIndex == demoBosses.length - 1) {
        _allDefeated = true;
        _state.ownedCostumes.add(windCostumeKey); // Bonus reward!
      }
      
      // Save the game so they don't lose that hard-earned unlock
      GameStorage.save(_state);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grab the current boss from our demo list
    // (If they beat all bosses, just keep showing the last one)
    final boss = demoBosses[_bossIndex.clamp(0, demoBosses.length - 1)];

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
                // Top HUD: Coins and Boosts (wired to state!)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      // Hardcoded coin value for now
                      Text('${_state.coins}', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
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
                            child: _playerFrame.isEmpty 
                              ? const SizedBox.shrink() // Hide until state loads
                              : Image.asset(
                                  _playerFrame,
                                  width: charSize,
                                  height: charSize,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none, // keeps pixel art crisp!
                                  // Step 16: Add fallback if the player hasn't added the sprite files yet
                                  errorBuilder: (_, __, ___) => Icon(Icons.person_outline, size: charSize, color: Colors.white54),
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
                              // Start a completely fresh run if not running
                              onPressed: _isRoundRunning ? null : _startRun,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRoundRunning ? Colors.grey : Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isRoundRunning ? 'Run in progress...' : 'Start Run',
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

        // --- Step 10: Draw all active damage numbers on top ---
        ..._damages.map((d) => _FloatingDamage(
              key: d['id'] as Key,
              position: d['pos'] as Offset,
              damage: d['dmg'] as int,
              onDone: () => setState(() => _damages.remove(d)),
            )),
            
        // --- Step 11: Victory Screen Overlay ---
        if (_showVictory) _buildVictoryOverlay(),

        // --- Step 12: Game Over Overlay ---
        if (_showGameOver) _buildGameOverOverlay(),
      ],
      ),
      // Keeping the standard app bottom nav bar
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  // --- Step 12: Game Over UI Widget ---
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87, // Dim the background
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TIME IS UP', style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              const Text('The boss was too strong this time...', style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Buy upgrades in the Shop and try again!', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGameOver = false;
                    _damages.clear(); // cleanup the floating damage numbers
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 11: Victory UI Widget ---
  Widget _buildVictoryOverlay() {
    final boss = demoBosses[_bossIndex.clamp(0, demoBosses.length - 1)];

    return Container(
      color: Colors.black87, // Dim the background
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 BOSS DEFEATED! 🎉', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              
              Text('+${boss.coinReward} Coins', style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              const Text('Unlocked Costume:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Image.asset(boss.rewardImagePath, height: 60, width: 60),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showVictory = false;
                    _damages.clear(); // clean up any leftover floating text
                    
                    if (!_allDefeated) {
                      _bossIndex++; // Move to next boss
                    } else {
                      _bossIndex = 0; // Reset loop if they won everything
                      _allDefeated = false;
                    }
                    // Step 18: Resume the timer instead of completely resetting it
                    _startBoss();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(_allDefeated ? 'Play Again 🏆' : 'Next Boss ➔', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Step 10: Floating Damage Number Widget ---
// A small widget that animates floating upwards and fading out, then
// calls a callback (onDone) so we can remove it from the list.
class _FloatingDamage extends StatefulWidget {
  final Offset position;
  final int damage;
  final VoidCallback onDone;

  const _FloatingDamage({
    Key? key,
    required this.position,
    required this.damage,
    required this.onDone,
  }) : super(key: key);

  @override
  State<_FloatingDamage> createState() => _FloatingDamageState();
}

class _FloatingDamageState extends State<_FloatingDamage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    // It exists for 600 milliseconds
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // Fades out from 1.0 to 0.0
    _opacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    // Floats upward by 60 pixels
    _dy = Tween<double>(begin: 0.0, end: -60.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Tell the parent to delete this when it's done animating
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _dy.value),
              child: child,
            ),
          );
        },
        child: Text(
          '-${widget.damage}',
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
          ),
        ),
      ),
    );
  }
}

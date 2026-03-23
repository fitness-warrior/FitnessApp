import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/common/navbar.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int _roundDurationSeconds = 20;
  static const String _bossImagePath = 'images/game_costume/game_chars/boss1.png';
  static const String _playerImagePath = 'images/game_costume/game_chars/player.png';

  int _timeLeft = _roundDurationSeconds;
  int _score = 0;
  int _bestScore = 0;
  bool _isRoundRunning = false;
  Timer? _roundTimer;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _roundTimer?.cancel();
    setState(() {
      _timeLeft = _roundDurationSeconds;
      _score = 0;
      _isRoundRunning = true;
    });

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        setState(() {
          _timeLeft = 0;
          _isRoundRunning = false;
          if (_score > _bestScore) {
            _bestScore = _score;
          }
        });
        return;
      }

      setState(() {
        _timeLeft -= 1;
      });
    });
  }

  void _onEnemyTap() {
    if (!_isRoundRunning) return;

    setState(() {
      _score += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double timeProgress = _timeLeft / _roundDurationSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Tap Sprint')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              _isRoundRunning ? 'Tap Fast For High Score' : 'Round Finished',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 16,
                value: timeProgress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isRoundRunning ? Colors.orange : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time Left: ${_timeLeft}s',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $_score    Best: $_bestScore',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _onEnemyTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: _isRoundRunning ? 210 : 190,
                      height: _isRoundRunning ? 210 : 190,
                      decoration: BoxDecoration(
                        color: _isRoundRunning
                            ? const Color(0xFFE3F2FD)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            _bossImagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_martial_arts,
                              size: 84,
                              color: Colors.black45,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isRoundRunning ? 'TAP BOSS' : 'ROUND OVER',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      _playerImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fitness_center,
                        size: 72,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isRoundRunning
                  ? 'Each tap gives +1 point. Keep tapping until time runs out.'
                  : 'Tap restart to run a new timed score challenge.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startRound,
              child: Text(_isRoundRunning ? 'Restart Round' : 'Play Again'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

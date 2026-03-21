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
              child: Center(
                child: GestureDetector(
                  onTap: _onEnemyTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: _isRoundRunning ? 220 : 190,
                    height: _isRoundRunning ? 220 : 190,
                    decoration: BoxDecoration(
                      color: _isRoundRunning
                          ? const Color(0xFF90CAF9)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isRoundRunning ? 'TAP' : 'DONE',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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

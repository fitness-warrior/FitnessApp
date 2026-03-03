import 'package:flutter/material.dart';

/// A centered "Finish Workout" button fixed to the bottom of the screen.
/// Pass [onPressed] to wire up the action when ready.
class FinishButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FinishButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Center(
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(220, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 10),
                Text(
                  'Finish Workout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

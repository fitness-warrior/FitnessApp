import 'package:flutter/material.dart';

/// A full-width "Finish Workout" button fixed to the bottom of the screen.
/// Place this inside [Scaffold.bottomNavigationBar].
class FinishButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FinishButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text(
            'Finish Workout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ),
    );
  }
}

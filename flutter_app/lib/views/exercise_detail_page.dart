import 'package:flutter/material.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailPage({Key? key, required this.exercise}) : super(key: key);

  static const Map<String, Color> _areaColors = {
    'Chest':     Color(0xFFEF5350),
    'Back':      Color(0xFFAB47BC),
    'Shoulders': Color(0xFF42A5F5),
    'Arms':      Color(0xFF26C6DA),
    'Legs':      Color(0xFF66BB6A),
    'Core':      Color(0xFFFFA726),
    'Cardio':    Color(0xFFEC407A),
  };

  @override
  Widget build(BuildContext context) {
    final name = exercise['exer_name']?.toString() ?? 'Unknown';
    final area = exercise['exer_body_area']?.toString() ?? '';
    final color = _areaColors[area] ?? const Color(0xFF4A9FFF);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            backgroundColor: const Color(0xFF0D0D14),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for content
                  const Center(child: Text('Content coming...', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

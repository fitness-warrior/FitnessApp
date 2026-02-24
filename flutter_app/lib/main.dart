import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'views/workout_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Onboarding',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WorkoutPage(),
    );
  }
}


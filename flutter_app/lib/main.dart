import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/services/recommendation_storage.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';
import 'package:fitness_app_flutter/views/meal_plan_page.dart';
import 'package:fitness_app_flutter/views/game_page.dart';
import 'package:fitness_app_flutter/views/edit_avatar_page.dart';
import 'package:fitness_app_flutter/views/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QuestionnaireLauncher(),
      routes: {
        '/my_workout': (_) => const WorkoutPage(),
        '/my_meal': (_) => const MealPlanPage(),
        '/game': (_) => const GamePage(),
        '/edit_avatar': (_) => const EditAvatarPage(),
        '/dashboard': (_) => const DashboardPage(),
      },
    );
  }
}

class QuestionnaireLauncher extends StatefulWidget {
  const QuestionnaireLauncher({Key? key}) : super(key: key);

  @override
  State<QuestionnaireLauncher> createState() => _QuestionnaireLauncherState();
}

class _QuestionnaireLauncherState extends State<QuestionnaireLauncher> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Delay navigation until after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  Future<void> _startFlow() async {
    if (_started) return;
    _started = true;

    // Check if a recommendation profile already exists in local storage.
    final existingProfile = await RecommendationStorage.loadProfile();

    List<String>? tags;

    if (existingProfile != null) {
      // Profile found — skip questionnaire and derive tags from saved profile.
      tags = [
        existingProfile.goal,
        existingProfile.experience,
        ...existingProfile.equipment,
      ];
    } else {
      // No profile yet — show the questionnaire so the user can set one up.
      final dynamic recResult =
          await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (_) => const QuestionnairePage()),
      );

      // Expect recResult to be a Map with 'tags' (List<String>) or null.
      try {
        if (recResult is Map && recResult['tags'] is List) {
          tags = (recResult['tags'] as List).cast<String>();
        }
      } catch (_) {
        tags = null;
      }
    }

    // Replace launcher with the main workout page, passing recommendation tags.
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutPage(initialRecommendationTags: tags),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simple splash while pushing questionnaire
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

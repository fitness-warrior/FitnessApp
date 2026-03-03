import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/services/recommendation_storage.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QuestionnaireLauncher(),
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

    // Always show questionnaire first. If you want to skip when profile exists,
    // load RecommendationStorage.loadProfile() and conditionally navigate.
    final dynamic recResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const QuestionnaireWidget()),
    );

    // Expect recResult to be a Map with 'tags' (List<String>) or null.
    List<String>? tags;
    try {
      if (recResult is Map && recResult['tags'] is List) {
        tags = (recResult['tags'] as List).cast<String>();
      }
    } catch (_) {
      tags = null;
    }

    // Replace launcher with the main workout page, passing recommendation tags.
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

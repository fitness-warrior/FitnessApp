import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/services/auth_service.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';
import 'package:fitness_app_flutter/views/meal_plan_page.dart';
import 'package:fitness_app_flutter/views/dashboard_page.dart';
import 'package:fitness_app_flutter/views/auth_page.dart';
import 'package:fitness_app_flutter/views/profile_page.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';

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
      home: const AuthLauncher(),
      routes: {
        '/auth': (_) => const AuthPage(),
        '/questionnaire': (_) => const QuestionnairePage(isOnboarding: false),
        '/my_workout': (_) => const WorkoutPage(),
        '/my_meal': (_) => const MealPlanPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/profile': (_) => const ProfilePage(),
      },
    );
  }
}

/// Checks login state on cold start and routes accordingly.
/// - Logged in  → WorkoutPage (questionnaire already completed at sign-up)
/// - Not logged in → AuthPage
class AuthLauncher extends StatefulWidget {
  const AuthLauncher({Key? key}) : super(key: key);

  @override
  State<AuthLauncher> createState() => _AuthLauncherState();
}

class _AuthLauncherState extends State<AuthLauncher> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async { 
    if (_started) return;
    _started = true;

    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Already authenticated — go straight to the app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WorkoutPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

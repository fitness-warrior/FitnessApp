import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/main.dart';
import 'package:fitness_app_flutter/views/workout_page.dart';
import 'package:fitness_app_flutter/views/meal_plan_page.dart';
import 'package:fitness_app_flutter/views/dashboard_page.dart';
import 'package:fitness_app_flutter/views/auth_page.dart';
import 'package:fitness_app_flutter/views/profile_page.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../helpers/http_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStorage = <String, String?>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          secureStorage[call.arguments['key'] as String] = call.arguments['value'] as String?;
          return null;
        case 'read':
          return secureStorage[call.arguments['key'] as String];
        case 'delete':
          secureStorage.remove(call.arguments['key'] as String);
          return null;
        default:
          return null;
      }
    });
  });

  setUp(() {
    secureStorage.clear();
    SharedPreferences.setMockInitialValues({});
  });

  Future<HttpClientResponse> _intelligentMock(HttpClientRequest req) async {
    final uri = (req as FakeHttpClientRequest).uri;
    
    if (uri.path.contains('/api/auth/signup')) {
      return FakeHttpClientResponse(201, jsonEncode({
        'access_token': 'test_token',
        'user': {'id': 1, 'email': 'test@test.com', 'username': 'testuser'}
      }));
    }
    if (uri.path.contains('/api/auth/login')) {
      return FakeHttpClientResponse(200, jsonEncode({
        'access_token': 'test_token',
        'user': {'id': 1, 'email': 'test@test.com', 'username': 'testuser'}
      }));
    }
    
    if (uri.path.contains('questionnaire')) {
      if (req.method == 'GET') return FakeHttpClientResponse(200, jsonEncode({'age': 25}));
      return FakeHttpClientResponse(200, jsonEncode({}));
    }
    if (uri.path.contains('profile')) {
      return FakeHttpClientResponse(200, jsonEncode({'body_id': 1, 'email': 'test@test.com', 'username': 'testuser'}));
    }
    if (uri.path.contains('weekly-plan')) {
      return FakeHttpClientResponse(200, jsonEncode({'plan': {}}));
    }
    if (uri.path.contains('hidden-charts')) {
      return FakeHttpClientResponse(200, jsonEncode([]));
    }
    if (uri.path.contains('exercises-progress')) {
      return FakeHttpClientResponse(200, jsonEncode({}));
    }
    if (uri.path.contains('workout-volume')) {
      return FakeHttpClientResponse(200, jsonEncode([]));
    }
    if (uri.path.contains('/api/charts/options')) {
      return FakeHttpClientResponse(200, jsonEncode([]));
    }
    return FakeHttpClientResponse(200, jsonEncode([]));
  }

  group('Authentication & Onboarding', () {
    testWidgets('ITC-001: Full onboarding end-to-end', (WidgetTester tester) async {
      secureStorage.clear();
      HttpOverrides.global = FakeHttpOverrides((req) async {
        final uri = (req as FakeHttpClientRequest).uri;
        if (uri.path.contains('questionnaire') && req.method == 'GET') {
          return FakeHttpClientResponse(404, jsonEncode({'detail': 'Not found'}));
        }
        return _intelligentMock(req);
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'testuser');
      await tester.enterText(find.byType(TextField).at(2), 'Password123!');
      await tester.pump();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(QuestionnairePage), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '25');
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final bmiFields = find.byType(TextField);
      await tester.enterText(bmiFields.at(0), '180');
      await tester.enterText(bmiFields.at(1), '75');
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build muscle'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Beginner'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gym'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('60 mins'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next')); // Injuries
      await tester.pumpAndSettle();

      await tester.tap(find.text('Veg'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutPage), findsOneWidget);
    });

    testWidgets('ITC-004 & ITC-005: Login and Logout flow', (WidgetTester tester) async {
      secureStorage.clear();
      HttpOverrides.global = FakeHttpOverrides(_intelligentMock);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password123!');
      await tester.pump();
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutPage), findsOneWidget);

      // Logout
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      
      expect(find.byType(ProfilePage), findsOneWidget);

      // Scroll to find Logout button
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      final logoutBtn = find.text('Log Out');
      await tester.tap(logoutBtn.first);
      await tester.pumpAndSettle();
      
      // Tap Log Out in the confirmation dialog (index 1 is the button, 0 is the title)
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Log Out')).last);
      await tester.pumpAndSettle();

      expect(find.byType(AuthPage), findsOneWidget);
    });
  });

  group('Navigation & UI Integrity', () {
    testWidgets('ITC-007 to ITC-010: Navigation Access and Clarity', (WidgetTester tester) async {
      secureStorage['auth_token'] = 'fake_token';
      HttpOverrides.global = FakeHttpOverrides(_intelligentMock);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutPage), findsOneWidget);

      expect(find.text('Workout').last, findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.byType(MealPlanPage), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Exercise Progress'), findsOneWidget);

      await tester.tap(find.text('Workout').last);
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutPage), findsOneWidget);
    });

    testWidgets('ITC-011: Back navigation works correctly', (WidgetTester tester) async {
      secureStorage['auth_token'] = 'fake_token';
      HttpOverrides.global = FakeHttpOverrides(_intelligentMock);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Empty Workout'));
      await tester.pumpAndSettle();
      
      expect(find.text('Search Exercises'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Search Exercises'), findsNothing);
      expect(find.byType(WorkoutPage), findsOneWidget);
    });
  });
}

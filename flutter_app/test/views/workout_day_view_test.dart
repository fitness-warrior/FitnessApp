import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/views/workout_day_view.dart';
import 'package:fitness_app_flutter/services/streak_service.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return jsonEncode({'user_id': 123});
      return null;
    });
    
    // Set up mocked clients for services
    StreakService.client = MockClient((req) async => http.Response('{}', 200));
    UserStatsService.client = MockClient((req) async => http.Response('{"xp": 100}', 200));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
  });

  final mockRoutines = [
    {
      'name': 'Push Day',
      'exercises': [
        {
          'exer_id': 1,
          'exer_name': 'Bench Press',
          'exer_type': 'strength',
          'sets': [
            {'kg': '60', 'reps': '10'},
          ]
        },
        {
          'exer_id': 2,
          'exer_name': 'Pushups',
          'exer_type': 'strength',
          'sets': [
            {'kg': '0', 'reps': '20'},
          ]
        }
      ]
    }
  ];

  testWidgets('WorkoutDayView renders routines and exercises', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    expect(find.text('Monday Workout'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('0 / 1 sets completed'), findsNWidgets(2));
  });

  testWidgets('Toggling a set updates completion and shows rest timer', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    // Tap the first set checkbox (Bench Press)
    final checkbox = find.byType(GestureDetector).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Check if rest timer dialog appears
    expect(find.text('Rest Time'), findsOneWidget);
    
    // Skip rest
    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1 sets completed'), findsOneWidget);
  });

  testWidgets('Finish workout becomes visible and works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    // Complete all sets
    final checkboxes = find.byType(GestureDetector);
    
    // Bench Press set
    await tester.tap(checkboxes.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    // Pushups set
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    // Finish button should be visible now
    expect(find.text('Finish Workout'), findsOneWidget);
    
    await tester.tap(find.text('Finish Workout'));
    await tester.pumpAndSettle();

    // Success screen should be visible
    expect(find.text('Workout Complete!'), findsOneWidget);
  });

  testWidgets('Back press during workout shows quit screen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    // Simulate back press
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Really? Giving up?'), findsOneWidget);
    
    // Keep going
    await tester.tap(find.text('Keep Going! \ud83d\udcaa'));
    await tester.pumpAndSettle();
    
    expect(find.text('Really? Giving up?'), findsNothing);
  });

  testWidgets('Untoggling a set works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    final checkbox = find.byType(GestureDetector).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1 sets completed'), findsOneWidget);

    // Untoggle
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    // Use findsAtLeast(1) or check the first one
    expect(find.text('0 / 1 sets completed'), findsAtLeast(1));
  });

  testWidgets('Confirm quit works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes, I give up'));
    await tester.pumpAndSettle();
    // In real app it pops, here we just check it doesn't crash
  });

  testWidgets('Cardio exercises render and validate', (WidgetTester tester) async {
    final cardioRoutines = [
      {
        'name': 'Cardio Day',
        'exercises': [
          {
            'exer_id': 3,
            'exer_name': 'Running',
            'exer_type': 'cardio',
            'sets': [{'time': '10', 'distance': '2'}]
          }
        ]
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Cardio', routines: cardioRoutines),
    ));

    expect(find.text('min'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);

    // Complete set
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    expect(find.text('Finish Workout'), findsOneWidget);
  });

  testWidgets('Validation prevents completing cardio with empty inputs', (WidgetTester tester) async {
    final emptyCardio = [
      {
        'name': 'Test',
        'exercises': [
          {
            'exer_id': 3,
            'exer_name': 'Running',
            'exer_type': 'cardio',
            'sets': [{'time': '', 'distance': ''}]
          }
        ]
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'TestDay', routines: emptyCardio),
    ));

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(); 
    expect(find.text('Please enter valid time or distance.'), findsOneWidget);
  });

  testWidgets('Validation prevents completing set with empty weight/reps', (WidgetTester tester) async {
    final emptyRoutines = [
      {
        'name': 'Test',
        'exercises': [
          {
            'exer_id': 1,
            'exer_name': 'Bench',
            'exer_type': 'strength',
            'sets': [{'kg': '', 'reps': ''}]
          }
        ]
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'TestDay', routines: emptyRoutines),
    ));

    // Tap checkbox
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(); // SnackBar needs a frame

    expect(find.text('Please enter valid weight and reps (>0).'), findsOneWidget);
  });

  testWidgets('Rest timer auto-closes after 120 seconds', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Monday', routines: mockRoutines),
    ));

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(); // Show dialog
    expect(find.text('Rest Time'), findsOneWidget);

    // Fast forward 121 seconds
    await tester.pump(const Duration(seconds: 121));
    await tester.pumpAndSettle();

    expect(find.text('Rest Time'), findsNothing);
  });

  testWidgets('WTC-053: Empty state renders when no workouts are provided', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(      home: WorkoutDayView(dayName: 'Empty', routines: []),
    ));

    expect(find.text('No routines for this day.'), findsOneWidget);
  });

  testWidgets('WTC-052: Exercise List renders with sets and reps correctly', (WidgetTester tester) async {
    final workoutWithThreeSets = [
      {
        'name': 'Power Workout',
        'exercises': [
          {
            'exer_id': 101,
            'exer_name': 'Deadlift',
            'exer_type': 'strength',
            'sets': [
              {'kg': '100', 'reps': '5'},
              {'kg': '100', 'reps': '5'},
              {'kg': '100', 'reps': '5'},
            ]
          },
          {
            'exer_id': 102,
            'exer_name': 'Overhead Press',
            'exer_type': 'strength',
            'sets': [
              {'kg': '40', 'reps': '8'},
              {'kg': '40', 'reps': '8'},
              {'kg': '40', 'reps': '8'},
            ]
          }
        ]
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: WorkoutDayView(dayName: 'Legs', routines: workoutWithThreeSets),
    ));

    expect(find.text('Legs Workout'), findsOneWidget);
    expect(find.text('Deadlift'), findsOneWidget);
    expect(find.text('Overhead Press'), findsOneWidget);
    
    expect(find.text('kg'), findsNWidgets(6));
    expect(find.text('reps'), findsNWidgets(6));
    
    expect(find.text('0 / 3 sets completed'), findsNWidgets(2));
  });
}

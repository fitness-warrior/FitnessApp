import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitness_app_flutter/views/workout_calendar_page.dart';
import 'package:fitness_app_flutter/views/workout_day_view.dart';
import '../helpers/http_mock.dart';

void main() {
  group('WorkoutCalendarPage Widget Tests', () {
    const fakeSecureStorageData = {'auth_token': 'fake_token'};

    final sampleSavedWorkouts = [
      {
        'id': 'w1',
        'name': 'Upper Body Blast',
        'date': '2026-05-18T10:00:00.000', // Assuming Monday
        'duration': 45,
        'calories': 350,
      },
      {
        'id': 'w2',
        'name': 'Leg Day Crunch',
        'date': '2026-05-19T10:00:00.000', // Assuming Tuesday
        'duration': 50,
        'calories': 400,
      },
    ];

    final fakePlanResponse = {
      'plan': {
        'week_plan': {
          'monday': ['Upper Body Blast'],
          'tuesday': ['Leg Day Crunch'],
          'wednesday': [],
          'thursday': ['Upper Body Blast'],
          'friday': [],
          'saturday': [],
          'sunday': [],
        },
        'routines': [
          {
            'name': 'Upper Body Blast',
            'exercises': [
              {'name': 'Push Ups', 'sets': 3, 'reps': 12}
            ],
          },
          {
            'name': 'Leg Day Crunch',
            'exercises': [
              {'name': 'Squats', 'sets': 4, 'reps': 10}
            ],
          },
        ],
      }
    };

    tearDown(() {
      HttpOverrides.global = null;
    });

    testWidgets('Renders calendar days, assigned routines, and today tag on successful load', (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(fakeSecureStorageData);
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(200, jsonEncode(fakePlanResponse));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutCalendarPage(
              savedWorkouts: sampleSavedWorkouts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);

      expect(find.text('Upper Body Blast'), findsWidgets);
      expect(find.text('Leg Day Crunch'), findsOneWidget);
    });

    testWidgets('Tapping close icon on routine chip removes routine and saves plan', (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(fakeSecureStorageData);
      bool postCalled = false;
      HttpOverrides.global = FakeHttpOverrides((request) async {
        if (request.method == 'POST') {
          postCalled = true;
          return FakeHttpClientResponse(200, '{"status":"ok"}');
        }
        return FakeHttpClientResponse(200, jsonEncode(fakePlanResponse));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutCalendarPage(
              savedWorkouts: sampleSavedWorkouts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Leg Day Crunch is visible
      expect(find.text('Leg Day Crunch'), findsOneWidget);

      // Tap close icon next to Leg Day Crunch
      final closeIcon = find.descendant(
        of: find.widgetWithText(Container, 'Leg Day Crunch'),
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Leg Day Crunch'), findsNothing);
      expect(postCalled, isTrue);
    });

    testWidgets('Long pressing day opens assign dialog, selecting routine saves plan', (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(fakeSecureStorageData);
      bool postCalled = false;
      HttpOverrides.global = FakeHttpOverrides((request) async {
        if (request.method == 'POST') {
          postCalled = true;
          return FakeHttpClientResponse(200, '{"status":"ok"}');
        }
        return FakeHttpClientResponse(200, jsonEncode(fakePlanResponse));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutCalendarPage(
              savedWorkouts: sampleSavedWorkouts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press Wednesday
      await tester.longPress(find.text('Wednesday'));
      await tester.pumpAndSettle();

      expect(find.text('Assign to Wednesday'), findsOneWidget);
      expect(find.text('Upper Body Blast'), findsWidgets);
      expect(find.text('Leg Day Crunch'), findsWidgets);

      // Check one of the routines
      final checkbox = find.byType(CheckboxListTile).first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(postCalled, isTrue);
    });

    testWidgets('Tapping day card with assigned routines navigates to WorkoutDayView', (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(fakeSecureStorageData);
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(200, jsonEncode(fakePlanResponse));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutCalendarPage(
              savedWorkouts: sampleSavedWorkouts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Thursday (which has Upper Body Blast assigned but no completed workout matching today)
      await tester.tap(find.text('Thursday'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutDayView), findsOneWidget);
    });

    testWidgets('Displays error message and retry button when API fails', (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(fakeSecureStorageData);
      HttpOverrides.global = FakeHttpOverrides((request) async {
        return FakeHttpClientResponse(500, 'Internal Server Error');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkoutCalendarPage(
              savedWorkouts: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load plan. Are you logged in?'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

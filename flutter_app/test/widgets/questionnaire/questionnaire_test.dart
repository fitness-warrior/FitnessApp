import 'package:fitness_app_flutter/models/recommendation_profile.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Questionnaire onboarding tests', () {
    Future<void> pumpQuestionnaire(
      WidgetTester tester, {
      Future<Map<String, dynamic>?> Function()? loadLocalQuestionnaire,
      Future<Map<String, dynamic>?> Function()? loadBackendQuestionnaire,
      Future<dynamic> Function(Map<String, dynamic> payload)?
          saveLocalQuestionnaire,
      Future<dynamic> Function(Map<String, dynamic> payload)?
          saveBackendQuestionnaire,
      Future<bool> Function(RecommendationProfile profile)? saveProfile,
      Future<Map<String, dynamic>> Function(RecommendationProfile profile)?
          fetchRecommendations,
      Future<void> Function(List<String> tags)? onCompleted,
      bool isOnboarding = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionnairePage(
            isOnboarding: isOnboarding,
            loadLocalQuestionnaire: loadLocalQuestionnaire,
            loadBackendQuestionnaire: loadBackendQuestionnaire,
            saveLocalQuestionnaire: saveLocalQuestionnaire,
            saveBackendQuestionnaire: saveBackendQuestionnaire,
            saveProfile: saveProfile,
            fetchRecommendations: fetchRecommendations,
            onCompleted: onCompleted,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> goNext(WidgetTester tester) async {
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    Future<void> advanceToSubmit(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        final submitFinder = find.widgetWithText(ElevatedButton, 'Submit');
        if (submitFinder.evaluate().isNotEmpty) {
          return;
        }
        await goNext(tester);
      }
    }

    Future<void> completeValidQuestionnaire(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'What is your age?'),
        '25',
      );
      await tester.pump();
      await goNext(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Height (cm)'), '180');
      await tester.enterText(
          find.widgetWithText(TextField, 'Weight (kg)'), '72');
      await tester.pump();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gain weight'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Intermediate'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gym'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '4'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '60 mins'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Knee'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Veg'));
      await tester.pumpAndSettle();
      await goNext(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Nuts'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'valid onboarding submission saves questionnaire and completes with recommendations',
      (tester) async {
        Map<String, dynamic>? localPayload;
        Map<String, dynamic>? backendPayload;
        RecommendationProfile? savedProfile;
        List<String>? completionTags;

        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => null,
          loadBackendQuestionnaire: () async => null,
          saveLocalQuestionnaire: (payload) async {
            localPayload = Map<String, dynamic>.from(payload);
            return true;
          },
          saveBackendQuestionnaire: (payload) async {
            backendPayload = Map<String, dynamic>.from(payload);
            return {'ok': true};
          },
          saveProfile: (profile) async {
            savedProfile = profile;
            return true;
          },
          fetchRecommendations: (_) async => {
            'tags': ['weight_gain', 'gym_machines'],
          },
          onCompleted: (tags) async {
            completionTags = tags;
          },
        );

        await completeValidQuestionnaire(tester);

        expect(localPayload, isNotNull);
        expect(backendPayload, isNotNull);
        expect(localPayload!['age'], equals(25));
        expect(localPayload!['goal'], equals('Gain weight'));
        expect(localPayload!['weight'], equals(72.0));
        expect(backendPayload, equals(localPayload));
        expect(savedProfile, isNotNull);
        expect(savedProfile!.goal, equals('weight_gain'));
        expect(savedProfile!.equipment, equals(['gym_machines']));
        expect(completionTags, containsAll(['weight_gain', 'gym_machines']));
      },
    );

    testWidgets(
      'existing questionnaire data is loaded and updated on resubmission',
      (tester) async {
        Map<String, dynamic>? localPayload;

        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => {
            'age': 25,
            'height': 180,
            'weight': 70,
            'goal': 'Gain weight',
            'experience': 'Intermediate',
            'location': 'Gym',
            'days_per_week': 4,
            'session_length': 60,
            'injuries': ['Knee'],
            'diet_preference': 'Veg',
            'allergies': ['Nuts'],
          },
          loadBackendQuestionnaire: () async => null,
          saveLocalQuestionnaire: (payload) async {
            localPayload = Map<String, dynamic>.from(payload);
            return true;
          },
          saveBackendQuestionnaire: (_) async => {'ok': true},
          saveProfile: (_) async => true,
          fetchRecommendations: (_) async => {'tags': <String>[]},
          onCompleted: (_) async {},
        );

        expect(
          find.widgetWithText(TextField, 'What is your age?'),
          findsOneWidget,
        );
        final ageField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'What is your age?'),
        );
        expect(ageField.controller?.text, equals('25'));

        await goNext(tester);
        expect(find.widgetWithText(TextField, 'Weight (kg)'), findsOneWidget);
        await tester.enterText(
            find.widgetWithText(TextField, 'Weight (kg)'), '72');
        await tester.pump();

        await goNext(tester);
        await advanceToSubmit(tester);
        await tester
            .ensureVisible(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.pumpAndSettle();

        expect(localPayload, isNotNull);
        expect(localPayload!['weight'], equals(72.0));
        expect(localPayload!['goal'], equals('Gain weight'));
      },
    );

    testWidgets(
      'required goal selection blocks progress until a valid option is chosen',
      (tester) async {
        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => null,
          loadBackendQuestionnaire: () async => null,
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'What is your age?'),
          '25',
        );
        await tester.pump();
        await goNext(tester);

        await tester.enterText(
            find.widgetWithText(TextField, 'Height (cm)'), '180');
        await tester.enterText(
            find.widgetWithText(TextField, 'Weight (kg)'), '70');
        await tester.pump();
        await goNext(tester);

        expect(find.text('What is your fitness goal?'), findsOneWidget);
        final nextButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);

        await tester.tap(find.widgetWithText(ChoiceChip, 'Lose weight'));
        await tester.pumpAndSettle();

        final enabledNextButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Next'),
        );
        expect(enabledNextButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'questionnaire continues onboarding when backend save fails',
      (tester) async {
        List<String>? completionTags;

        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => null,
          loadBackendQuestionnaire: () async => null,
          saveLocalQuestionnaire: (_) async => true,
          saveBackendQuestionnaire: (_) async {
            throw Exception('Missing Authorization header');
          },
          saveProfile: (_) async => true,
          fetchRecommendations: (_) async => {
            'tags': ['general_fitness']
          },
          onCompleted: (tags) async {
            completionTags = tags;
          },
        );

        await completeValidQuestionnaire(tester);

        expect(completionTags, equals(['general_fitness']));
      },
    );

    testWidgets(
      'saved questionnaire data is loaded at startup when present',
      (tester) async {
        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => {
            'age': 31,
          },
          loadBackendQuestionnaire: () async => null,
        );

        final ageField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'What is your age?'),
        );
        expect(ageField.controller?.text, equals('31'));
      },
    );

    testWidgets(
      'questionnaire starts cleanly when no saved record exists',
      (tester) async {
        await pumpQuestionnaire(
          tester,
          loadLocalQuestionnaire: () async => null,
          loadBackendQuestionnaire: () async => null,
        );

        expect(find.text('Onboarding Questionnaire'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'What is your age?'),
          findsOneWidget,
        );
        expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
      },
    );
  });
}

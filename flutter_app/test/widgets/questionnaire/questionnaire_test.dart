import 'dart:convert';

import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuestionnaireHost extends StatefulWidget {
  final bool isOnboarding;

  const _QuestionnaireHost({required this.isOnboarding});

  @override
  State<_QuestionnaireHost> createState() => _QuestionnaireHostState();
}

class _QuestionnaireHostState extends State<_QuestionnaireHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionnairePage(isOnboarding: widget.isOnboarding),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Host Page')),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    secureStorageChannel.setMockMethodCallHandler((call) async {
      return null;
    });
  });

  tearDownAll(() {
    secureStorageChannel.setMockMethodCallHandler(null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Questionnaire widget tests', () {
    Future<void> pumpQuestionnaire(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _QuestionnaireHost(isOnboarding: false),
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
        if (find
            .widgetWithText(ElevatedButton, 'Submit')
            .evaluate()
            .isNotEmpty) {
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
        find.widgetWithText(TextField, 'Height (cm)'),
        '180',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Weight (kg)'),
        '72',
      );
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
      'valid submission saves questionnaire data and returns from the flow',
      (tester) async {
        await pumpQuestionnaire(tester);

        await completeValidQuestionnaire(tester);

        final prefs = await SharedPreferences.getInstance();
        final savedQuestionnaireJson =
            prefs.getString('questionnaire_response_anonymous');
        final savedProfileJson =
            prefs.getString('recommendation_profile_anonymous');

        expect(find.text('Host Page'), findsOneWidget);
        expect(savedQuestionnaireJson, isNotNull);
        expect(savedProfileJson, isNotNull);

        final savedQuestionnaire = Map<String, dynamic>.from(
            jsonDecode(savedQuestionnaireJson!) as Map);
        expect(savedQuestionnaire['age'], equals(25));
        expect(savedQuestionnaire['weight'], equals(72.0));
        expect(savedQuestionnaire['goal'], equals('Gain weight'));

        final savedProfile =
            Map<String, dynamic>.from(jsonDecode(savedProfileJson!) as Map);
        expect(savedProfile['goal'], equals('weight_gain'));
      },
    );

    testWidgets(
      'existing questionnaire data is loaded and updated on resubmission',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'questionnaire_response_anonymous': jsonEncode({
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
          }),
        });

        await pumpQuestionnaire(tester);

        final ageField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'What is your age?'),
        );
        expect(ageField.controller?.text, equals('25'));

        await goNext(tester);
        await tester.enterText(
          find.widgetWithText(TextField, 'Weight (kg)'),
          '72',
        );
        await tester.pump();

        await goNext(tester);
        await advanceToSubmit(tester);
        await tester
            .ensureVisible(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final savedQuestionnaireJson =
            prefs.getString('questionnaire_response_anonymous');
        final savedQuestionnaire = Map<String, dynamic>.from(
            jsonDecode(savedQuestionnaireJson!) as Map);

        expect(savedQuestionnaire['weight'], equals(72.0));
        expect(savedQuestionnaire['goal'], equals('Gain weight'));
      },
    );

    testWidgets(
      'required goal selection blocks progress until a valid option is chosen',
      (tester) async {
        await pumpQuestionnaire(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'What is your age?'),
          '25',
        );
        await tester.pump();
        await goNext(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'Height (cm)'),
          '180',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Weight (kg)'),
          '70',
        );
        await tester.pump();
        await goNext(tester);

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
      'saved questionnaire data is loaded at startup when present',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'questionnaire_response_anonymous': jsonEncode({'age': 31}),
        });

        await pumpQuestionnaire(tester);

        final ageField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'What is your age?'),
        );
        expect(ageField.controller?.text, equals('31'));
      },
    );

    testWidgets(
      'questionnaire starts cleanly when no saved record exists',
      (tester) async {
        await pumpQuestionnaire(tester);

        expect(find.text('Onboarding Questionnaire'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'What is your age?'),
            findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
      },
    );

    testWidgets(
      'age below minimum shows validation feedback and keeps next disabled',
      (tester) async {
        await pumpQuestionnaire(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'What is your age?'),
          '5',
        );
        await tester.pumpAndSettle();

        expect(find.text('Minimum value is 13.'), findsOneWidget);

        final nextButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Next'),
        );
        expect(nextButton.onPressed, isNull);
      },
    );
  });
}

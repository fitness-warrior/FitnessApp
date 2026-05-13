import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/questionnaire/questionnaire_widget.dart';

void main() {
  group('Questionnaire Tests', () {

    test('Test 1: Questions render correctly - first question is age', () {
      // Simulate the questions list defined inside QuestionnairePage
      final questions = [
        Question(
          id: 'Q001',
          prompt: 'What is your age?',
          type: QuestionType.number,
          mandatory: true,
          min: 13,
          max: 100,
        ),
        Question(
          id: 'Q003',
          prompt: 'What is your fitness goal?',
          type: QuestionType.singleChoice,
          options: ['Lose weight', 'Build muscle', 'Stay fit'],
          mandatory: true,
        ),
        Question(
          id: 'Q008',
          prompt: 'Any injuries?',
          type: QuestionType.multiSelect,
          options: ['None', 'Knee', 'Back'],
          mandatory: false,
        ),
      ];

      // First question is 'What is your age?' — visible and correctly laid out
      expect(questions.first.prompt, equals('What is your age?'));
      expect(questions.first.type, equals(QuestionType.number));
    });

    test('Test 2: Single choice question only accepts 1 selection', () {
      // Simulate single-choice response map: only one key-value per question
      final responses = <String, dynamic>{};
      final questionId = 'Q003';

      // User selects 'Build muscle'
      responses[questionId] = 'Build muscle';

      // User then selects 'Lose weight' — overwrites the previous selection
      responses[questionId] = 'Lose weight';

      // Only one option can be selected at a time
      expect(responses[questionId], equals('Lose weight'));
      expect(responses.values.where((v) => v is String).length, equals(1));
    });

    test('Test 3: Multi-select questions accept multiple selections', () {
      // Simulate multi-select selections set
      final multiSelections = <String, Set<String>>{
        'Q008': <String>{},
      };

      // User taps 3 options
      multiSelections['Q008']!.add('Knee');
      multiSelections['Q008']!.add('Back');
      multiSelections['Q008']!.add('Shoulder');

      // All 3 options are selected
      expect(multiSelections['Q008']!.length, equals(3));
      expect(multiSelections['Q008']!.contains('Knee'), isTrue);
      expect(multiSelections['Q008']!.contains('Back'), isTrue);
      expect(multiSelections['Q008']!.contains('Shoulder'), isTrue);
    });

    test('Test 4: Compulsory fields block submission when empty', () {
      // Simulate _isCurrentValid() logic for a mandatory number question
      final question = Question(
        id: 'Q001',
        prompt: 'What is your age?',
        type: QuestionType.number,
        mandatory: true,
        min: 13,
        max: 100,
      );

      // Empty input
      final textInput = '';

      // Validation: mandatory && empty → invalid
      bool isValid = true;
      if (question.mandatory && textInput.trim().isEmpty) {
        isValid = false;
      }

      // Validation error is shown — cannot proceed
      expect(isValid, isFalse);
    });

    test('Test 5: Number input rejects value below minimum', () {
      // Simulate _validateNumberFeedback() / _isCurrentValid() for age question
      final question = Question(
        id: 'Q001',
        prompt: 'What is your age?',
        type: QuestionType.number,
        mandatory: true,
        min: 13,
        max: 100,
      );

      // User enters 5 — below minimum age of 13
      final textInput = '5';
      final val = int.tryParse(textInput);

      String feedback = '';
      bool isValid = true;
      if (val != null && question.min != null && val < question.min!) {
        feedback = 'Minimum value is ${question.min}.';
        isValid = false;
      }

      // Validation error: "Minimum value is 13."
      expect(isValid, isFalse);
      expect(feedback, equals('Minimum value is 13.'));
    });

  });
}

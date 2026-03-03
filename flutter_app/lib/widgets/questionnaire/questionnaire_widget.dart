import 'dart:convert';
import '../../models/recommendation_profile.dart';
import '../../services/recommendation_service.dart';
import '../../services/recommendation_storage.dart';

import '../../views/workout_page.dart';

import 'package:flutter/material.dart';

enum QuestionType { singleChoice, multiSelect, number, text }

class Question {
  final String id;
  final String prompt;
  final QuestionType type;
  final List<String> options;
  final bool mandatory;
  final int? min;
  final int? max;

  Question({
    required this.id,
    required this.prompt,
    required this.type,
    this.options = const [],
    this.mandatory = false,
    this.min,
    this.max,
  });
}

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({Key? key}) : super(key: key);

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final List<Question> _questions = [
    Question(
      id: 'Q001',
      prompt: 'What is your age?',
      type: QuestionType.number,
      mandatory: true,
      min: 13,
      max: 100,
    ),
    Question(
      id: 'Q002',
      prompt: 'What is your main fitness goal?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: [
        'Fat Loss',
        'Muscle Gain',
        'Endurance Improvement',
        'General Fitness',
        'Athletic Performance',
        'Injury Rehabilitation',
      ],
    ),
    Question(
      id: 'Q003',
      prompt: 'How would you describe your current fitness level?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['Beginner', 'Intermediate', 'Advanced'],
    ),
    Question(
      id: 'Q004',
      prompt: 'How many days per week can you commit to working out?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['1-2 Days', '3 Days', '4 Days', '5 Days', '6+ Days'],
    ),
    Question(
      id: 'Q005',
      prompt: 'How long do you prefer your workouts to be?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: [
        '20-30 Minutes',
        '30-45 Minutes',
        '45-60 Minutes',
        '60+ Minutes',
      ],
    ),
    Question(
      id: 'Q006',
      prompt: 'What equipment do you have access to?',
      type: QuestionType.multiSelect,
      mandatory: true,
      options: [
        'Bodyweight Only',
        'Dumbbells',
        'Barbells',
        'Resistance Bands',
        'Gym Machines',
        'Cardio Machines',
      ],
    ),
    Question(
      id: 'Q007',
      prompt: 'Which type of training do you enjoy most?',
      type: QuestionType.multiSelect,
      mandatory: true,
      options: [
        'Strength Training',
        'Cardio Training',
        'High Intensity Interval Training (HIIT)',
        'Flexibility / Mobility',
        'Mixed Training',
      ],
    ),
    Question(
      id: 'Q008',
      prompt:
          'Do you have any injuries or physical limitations we should consider?',
      type: QuestionType.multiSelect,
      mandatory: false,
      options: [
        'None',
        'Knee Issues',
        'Back Issues',
        'Shoulder Issues',
        'Joint Pain',
        'Other',
      ],
    ),
  ];

  int _index = 0;

  // Responses storage
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Set<String>> _multiSelections = {};

  @override
  void initState() {
    super.initState();
    for (var q in _questions) {
      if (q.type == QuestionType.multiSelect) {
        _multiSelections[q.id] = <String>{};
      }
      _textControllers[q.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isCurrentValid() {
    final q = _questions[_index];
    if (q.type == QuestionType.number) {
      final txt = _textControllers[q.id]!.text;
      if (q.mandatory && txt.trim().isEmpty) return false;
      if (txt.trim().isEmpty) return !q.mandatory;
      final val = int.tryParse(txt);
      if (val == null) return false;
      if (q.min != null && val < q.min!) return false;
      if (q.max != null && val > q.max!) return false;
      return true;
    }

    if (q.type == QuestionType.singleChoice) {
      return _responses.containsKey(q.id) && _responses[q.id] != null;
    }

    if (q.type == QuestionType.multiSelect) {
      final sel = _multiSelections[q.id]!;
      if (!q.mandatory) return true; // optional
      return sel.isNotEmpty;
    }

    if (q.type == QuestionType.text) {
      final txt = _textControllers[q.id]!.text;
      return !q.mandatory || txt.trim().isNotEmpty;
    }

    return true;
  }

  void _next() {
    final q = _questions[_index];
    // persist current
    if (q.type == QuestionType.number || q.type == QuestionType.text) {
      _responses[q.id] = _textControllers[q.id]!.text.trim();
    }
    if (q.type == QuestionType.multiSelect) {
      _responses[q.id] = _multiSelections[q.id]!.toList();
    }

    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }

    // finalise
    _buildAndShowResult();
  }

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  void _buildAndShowResult() {
    // Ensure final question persisted
    final last = _questions[_index];
    if (last.type == QuestionType.number || last.type == QuestionType.text) {
      _responses[last.id] = _textControllers[last.id]!.text.trim();
    }
    if (last.type == QuestionType.multiSelect) {
      _responses[last.id] = _multiSelections[last.id]!.toList();
    }

    // Map to canonical output schema
    final age = int.tryParse(_responses['Q001'] ?? '0') ?? 0;
    final fitnessGoalRaw = (_responses['Q002'] ?? '').toString();
    final fitnessLevelRaw = (_responses['Q003'] ?? '').toString();
    final durationRaw = (_responses['Q005'] ?? '').toString();
    final equipmentRaw =
        (_responses['Q006'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final injuriesRaw =
        (_responses['Q008'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    // Normalize mappings
    String mapGoal(String g) {
      final s = g.toLowerCase();
      if (s.contains('fat')) return 'fat_loss';
      if (s.contains('muscle') || s.contains('gain')) return 'strength';
      if (s.contains('endurance')) return 'endurance';
      if (s.contains('rehab') || s.contains('injury')) return 'rehab';
      return 'general_fitness';
    }

    String mapExperience(String e) {
      final s = e.toLowerCase();
      if (s.contains('beginner')) return 'beginner';
      if (s.contains('intermediate')) return 'intermediate';
      if (s.contains('advanced')) return 'advanced';
      return 'beginner';
    }

    int mapDuration(String d) {
      if (d.contains('20')) return 25;
      if (d.contains('30-45')) return 35;
      if (d.contains('45')) return 50;
      if (d.contains('60')) return 75;
      if (d.contains('30')) return 35;
      return 30;
    }

    List<String> mapEquipment(List<String> eq) {
      return eq.map((e) {
        final s = e.toLowerCase();
        if (s.contains('bodyweight')) return 'bodyweight';
        if (s.contains('dumbbell')) return 'dumbbells';
        if (s.contains('barbell')) return 'barbells';
        if (s.contains('resistance')) return 'resistance_bands';
        if (s.contains('gym machine')) return 'gym_machines';
        if (s.contains('cardio')) return 'cardio_machines';
        return s.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      }).toList();
    }

    List<String> mapInjuries(List<String> inj) {
      final res = <String>[];
      for (final i in inj) {
        final s = i.toLowerCase();
        if (s.contains('knee'))
          res.add('knee');
        else if (s.contains('back'))
          res.add('back');
        else if (s.contains('shoulder'))
          res.add('shoulder');
        else if (s.contains('joint'))
          res.add('joint');
        else if (s.contains('none'))
          continue;
        else
          res.add('other');
      }
      return res;
    }

    final profile = RecommendationProfile(
      goal: mapGoal(fitnessGoalRaw),
      experience: mapExperience(fitnessLevelRaw),
      equipment: mapEquipment(equipmentRaw),
      workoutLengthMinutes: mapDuration(durationRaw),
      injuredAreas: mapInjuries(injuriesRaw),
    );

    // Persist profile locally
    RecommendationStorage.saveProfile(profile);

    // Call recommendation service
    RecommendationService.getRecommendations(profile).then((rec) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'profile': profile.toJson(),
        'recommendation': rec,
      });

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recommendations Ready'),
          content: SingleChildScrollView(child: Text(jsonStr)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to WorkoutPage and open search dialog with tags
                Navigator.of(context).pop();
                final tags = (rec['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => WorkoutPage(initialRecommendationTags: tags),
                  ),
                );
              },
              child: const Text('Apply Recommendations'),
            ),
          ],
        ),
      );
      // ignore: avoid_print
      print(jsonStr);
    });
  }

  Widget _buildCurrent() {
    final q = _questions[_index];
    switch (q.type) {
      case QuestionType.number:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textControllers[q.id],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: q.prompt,
                hintText: '${q.min ?? 0} - ${q.max ?? ''}',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_textControllers[q.id]!.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _validateNumberFeedback(q),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        );

      case QuestionType.singleChoice:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: q.options.map((opt) {
            final selected = _responses[q.id] == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: selected,
              onSelected: (v) {
                if (v) {
                  setState(() => _responses[q.id] = opt);
                }
              },
            );
          }).toList(),
        );

      case QuestionType.multiSelect:
        return Column(
          children: q.options.map((opt) {
            final selected = _multiSelections[q.id]!.contains(opt);
            return Column(
              children: [
                CheckboxListTile(
                  title: Text(opt),
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _multiSelections[q.id]!.add(opt);
                      } else {
                        _multiSelections[q.id]!.remove(opt);
                      }
                    });
                  },
                ),
                if (opt == 'Other' && selected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _textControllers[q.id],
                      decoration: const InputDecoration(
                        labelText: 'Please describe',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            );
          }).toList(),
        );

      case QuestionType.text:
        return TextField(
          controller: _textControllers[q.id],
          decoration: InputDecoration(labelText: q.prompt),
          onChanged: (_) => setState(() {}),
        );
    }
  }

  String _validateNumberFeedback(Question q) {
    final txt = _textControllers[q.id]!.text.trim();
    if (txt.isEmpty) return '';
    final val = int.tryParse(txt);
    if (val == null) return 'Enter a valid number.';
    if (q.min != null && val < q.min!) return 'Minimum value is ${q.min}.';
    if (q.max != null && val > q.max!) return 'Maximum value is ${q.max}.';
    return 'Looks good.';
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final isLast = _index == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Questionnaire')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Text(
              'Question ${_index + 1} of ${_questions.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: _buildCurrent())),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _index == 0 ? null : _previous,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _isCurrentValid() ? _next : null,
                  child: Text(isLast ? 'Submit' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

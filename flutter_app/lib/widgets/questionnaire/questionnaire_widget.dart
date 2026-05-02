import 'dart:convert';
import '../../models/recommendation_profile.dart';
import '../../services/recommendation_service.dart';
import '../../services/recommendation_storage.dart';

import '../../views/workout_page.dart';

import 'package:flutter/material.dart';

enum QuestionType { singleChoice, multiSelect, number, text, bmi }

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
      prompt: 'Height and weight',
      type: QuestionType.bmi,
      mandatory: true,
    ),
    Question(
      id: 'Q003',
      prompt: 'What is your fitness goal?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: [
        'Lose weight',
        'Build muscle',
        'Stay fit',
        'Gain weight',
      ],
    ),
    Question(
      id: 'Q004',
      prompt: 'What is your experience level?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['Beginner', 'Intermediate', 'Advanced'],
    ),
    Question(
      id: 'Q005',
      prompt:
          'Where do you want to work out? (Home assumes no equipment; select Gym if you have equipment)',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['Home', 'Gym'],
    ),
    Question(
      id: 'Q006',
      prompt: 'How many days per week?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['1', '2', '3', '4', '5', '6', '7'],
    ),
    Question(
      id: 'Q007',
      prompt: 'How long per session?',
      type: QuestionType.singleChoice,
      mandatory: true,
      options: ['20 mins', '30 mins', '60 mins'],
    ),
    Question(
      id: 'Q008',
      prompt: 'Any injuries?',
      type: QuestionType.multiSelect,
      mandatory: false,
      options: [
        'None',
        'Knee',
        'Back',
        'Shoulder',
        'Elbow',
        'Wrist',
        'Hip',
        'Ankle',
      ],
    ),
    Question(
      id: 'Q010',
      prompt: 'Diet preference',
      type: QuestionType.singleChoice,
      mandatory: true,
          options: ['Veg', 'Non-veg'],
    ),
    Question(
      id: 'Q011',
      prompt: 'Any allergies?',
      type: QuestionType.multiSelect,
      mandatory: false,
      options: [
        'None',
        'Milk',
        'Nuts',
        'Eggs',
        'Soy',
        'Wheat',
        'Shellfish',
      ],
    ),
  ];

  int _index = 0;

  // Responses storage
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Set<String>> _multiSelections = {};
  bool _useMetricBmi = true;

  @override
  void initState() {
    super.initState();
    for (var q in _questions) {
      if (q.type == QuestionType.multiSelect) {
        _multiSelections[q.id] = <String>{};
      }
      if (q.type == QuestionType.bmi) {
        _textControllers['${q.id}_height'] = TextEditingController();
        _textControllers['${q.id}_weight'] = TextEditingController();
      } else {
        _textControllers[q.id] = TextEditingController();
      }
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

    if (q.type == QuestionType.bmi) {
      final hTxt = _textControllers['${q.id}_height']!.text.trim();
      final wTxt = _textControllers['${q.id}_weight']!.text.trim();
      if (!q.mandatory && hTxt.isEmpty && wTxt.isEmpty) return true;
      final hVal = double.tryParse(hTxt);
      final wVal = double.tryParse(wTxt);
      if (hVal == null || wVal == null) return false;
      if (hVal <= 0 || wVal <= 0) return false;
      return true;
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
    if (q.type == QuestionType.bmi) {
      final hTxt = _textControllers['${q.id}_height']!.text.trim();
      final wTxt = _textControllers['${q.id}_weight']!.text.trim();
      final hVal = double.tryParse(hTxt) ?? 0;
      final wVal = double.tryParse(wTxt) ?? 0;
      _responses[q.id] = {
        'unit': _useMetricBmi ? 'metric' : 'imperial',
        'height': hVal,
        'weight': wVal,
        'bmi': _calculateBmi(hVal, wVal, _useMetricBmi),
      };
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
    if (last.type == QuestionType.bmi) {
      final hTxt = _textControllers['${last.id}_height']!.text.trim();
      final wTxt = _textControllers['${last.id}_weight']!.text.trim();
      final hVal = double.tryParse(hTxt) ?? 0;
      final wVal = double.tryParse(wTxt) ?? 0;
      _responses[last.id] = {
        'unit': _useMetricBmi ? 'metric' : 'imperial',
        'height': hVal,
        'weight': wVal,
        'bmi': _calculateBmi(hVal, wVal, _useMetricBmi),
      };
    }

    // Map to canonical output schema
    final age = int.tryParse(_responses['Q001'] ?? '0') ?? 0;
    final fitnessGoalRaw = (_responses['Q003'] ?? '').toString();
    final fitnessLevelRaw = (_responses['Q004'] ?? '').toString();
    final locationRaw = (_responses['Q005'] ?? '').toString();
    final durationRaw = (_responses['Q007'] ?? '').toString();
    final injuriesRaw =
      (_responses['Q008'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    // Normalize mappings
    String mapGoal(String g) {
      final s = g.toLowerCase();
      if (s.contains('lose')) return 'fat_loss';
      if (s.contains('build')) return 'strength';
      if (s.contains('stay')) return 'general_fitness';
      if (s.contains('gain')) return 'weight_gain';
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
      if (d.contains('20')) return 20;
      if (d.contains('30')) return 30;
      if (d.contains('60')) return 60;
      return 30;
    }

    List<String> mapEquipmentFromLocation(String loc) {
      final s = loc.toLowerCase();
      if (s.contains('home')) return ['bodyweight'];
      if (s.contains('gym')) return ['gym_machines'];
      return <String>[];
    }

    List<String> mapInjuries(List<String> inj) {
      final res = <String>[];
      for (final i in inj) {
        final s = i.toLowerCase();
        if (s.contains('none')) continue;
        if (s.contains('knee')) res.add('knee');
        if (s.contains('back')) res.add('back');
        if (s.contains('shoulder')) res.add('shoulder');
        if (s.contains('elbow')) res.add('elbow');
        if (s.contains('wrist')) res.add('wrist');
        if (s.contains('hip')) res.add('hip');
        if (s.contains('ankle')) res.add('ankle');
        if (s.contains('other')) res.add('other');
      }
      return res;
    }

    final profile = RecommendationProfile(
      age: age,
      goal: mapGoal(fitnessGoalRaw),
      experience: mapExperience(fitnessLevelRaw),
      equipment: mapEquipmentFromLocation(locationRaw),
      workoutLengthMinutes: mapDuration(durationRaw),
      injuredAreas: mapInjuries(injuriesRaw),
    );

    // Persist profile locally
    RecommendationStorage.saveProfile(profile);

    // Call recommendation service
    RecommendationService.getRecommendations(profile).then((rec) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_responses);

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
                final tags = (rec['tags'] as List<dynamic>?)?.cast<String>() ??
                    <String>[];
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutPage(initialRecommendationTags: tags),
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
                        if (opt == 'None') {
                          _multiSelections[q.id]!.clear();
                          _multiSelections[q.id]!.add(opt);
                        } else {
                          _multiSelections[q.id]!.remove('None');
                          _multiSelections[q.id]!.add(opt);
                        }
                      } else {
                        _multiSelections[q.id]!.remove(opt);
                      }
                    });
                  },
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

      case QuestionType.bmi:
        final heightCtrl = _textControllers['${q.id}_height']!;
        final weightCtrl = _textControllers['${q.id}_weight']!;
        final hVal = double.tryParse(heightCtrl.text.trim()) ?? 0;
        final wVal = double.tryParse(weightCtrl.text.trim()) ?? 0;
        final bmi = _calculateBmi(hVal, wVal, _useMetricBmi);
        final bmiLabel =
            bmi == null ? 'BMI: --' : 'BMI: ${bmi.toStringAsFixed(1)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: true, label: Text('Metric')),
                      ButtonSegment<bool>(
                          value: false, label: Text('Imperial')),
                    ],
                    selected: {_useMetricBmi},
                    onSelectionChanged: (v) => setState(() {
                      _useMetricBmi = v.first;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _useMetricBmi ? 'Height (cm)' : 'Height (inches)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _useMetricBmi ? 'Weight (kg)' : 'Weight (lb)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(bmiLabel),
          ],
        );
    }
  }

  double? _calculateBmi(double height, double weight, bool metric) {
    if (height <= 0 || weight <= 0) return null;
    if (metric) {
      final meters = height / 100.0;
      if (meters <= 0) return null;
      return weight / (meters * meters);
    }
    return (703 * weight) / (height * height);
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

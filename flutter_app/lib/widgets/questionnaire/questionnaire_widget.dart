import '../../models/recommendation_profile.dart';
import '../../services/recommendation_service.dart';
import '../../services/recommendation_storage.dart';
import '../../services/user_service.dart';
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
  /// [isOnboarding] = true  → shown after sign-up; navigates to WorkoutPage on submit.
  /// [isOnboarding] = false → shown from Edit Profile; pops back on submit.
  final bool isOnboarding;

  const QuestionnairePage({Key? key, this.isOnboarding = true})
      : super(key: key);

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
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    bool _isLoadingData;
    setState(() => _isLoadingData = true);
    try {
      // 1. Try local cache
      final local = await RecommendationStorage.loadQuestionnaireResponse();

      // 2. Try backend
      Map<String, dynamic>? backend;
      try {
        backend = await UserService.getQuestionnaireResponse();
      } catch (e) {
        debugPrint('[Questionnaire] Backend fetch failed: $e');
      }

      final data = backend ?? local;

      if (data != null && mounted) {
        setState(() {
          // Q001: Age
          if (data.containsKey('age')) {
            final age = data['age'].toString();
            _responses['Q001'] = age;
            _textControllers['Q001']?.text = age;
          }

          // Q002: BMI (Height/Weight)
          if (data.containsKey('height') && data.containsKey('weight')) {
            _textControllers['Q002_height']?.text = data['height'].toString();
            _textControllers['Q002_weight']?.text = data['weight'].toString();
            // Re-calculate BMI for response storage
            final hVal = double.tryParse(data['height'].toString()) ?? 0;
            final wVal = double.tryParse(data['weight'].toString()) ?? 0;
            final bmi = _calculateBmi(hVal, wVal, true);
            _responses['Q002'] = {
              'unit': 'metric',
              'height': hVal,
              'weight': wVal,
              'bmi': bmi,
              'bmiClass': _bmiClassification(bmi),
            };
          }

          // Q003: Goal (with mapping back to UI options)
          if (data.containsKey('goal')) {
            final backendGoal = data['goal'].toString();
            String uiGoal = backendGoal;
            if (backendGoal == 'Fat Loss') uiGoal = 'Lose weight';
            else if (backendGoal == 'Muscle Gain') uiGoal = 'Build muscle';
            else if (backendGoal == 'General Fitness') uiGoal = 'Stay fit';
            else if (backendGoal == 'Endurance Improvement') uiGoal = 'Improve endurance';
            else if (backendGoal == 'Injury Rehabilitation') uiGoal = 'Recover from injury';

            // Special case for 'Gain weight' which maps to 'Muscle Gain' in backend
            if (backendGoal == 'Muscle Gain' && local?['goal'] == 'Gain weight') {
              uiGoal = 'Gain weight';
            }

            _responses['Q003'] = uiGoal;
          }

          // Q004: Experience
          if (data.containsKey('experience')) {
            _responses['Q004'] = data['experience'];
          }

          // Q005: Location
          if (data.containsKey('location')) {
            _responses['Q005'] = data['location'];
          }

          // Q006: Days per week
          if (data.containsKey('days_per_week')) {
            _responses['Q006'] = data['days_per_week'].toString();
          }

          // Q007: Session length
          if (data.containsKey('session_length')) {
            _responses['Q007'] = '${data['session_length']} mins';
          }

          // Q008: Injuries
          if (data.containsKey('injuries')) {
            final injs = (data['injuries'] as List?)?.cast<String>() ?? [];
            _multiSelections['Q008']?.addAll(injs);
            _responses['Q008'] = injs;
          }

          // Q010: Diet preference
          if (data.containsKey('diet_preference')) {
            _responses['Q010'] = data['diet_preference'];
          }

          // Q011: Allergies
          if (data.containsKey('allergies')) {
            final alls = (data['allergies'] as List?)?.cast<String>() ?? [];
            _multiSelections['Q011']?.addAll(alls);
            _responses['Q011'] = alls;
          }
        });
      }
    } catch (e) {
      debugPrint('[Questionnaire] Error loading existing data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
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
      final bmi = _calculateBmi(hVal, wVal, _useMetricBmi);
      _responses[q.id] = {
        'unit': _useMetricBmi ? 'metric' : 'imperial',
        'height': hVal,
        'weight': wVal,
        'bmi': bmi,
        'bmiClass': _bmiClassification(bmi),
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

  Future<void> _buildAndShowResult() async {
    // Ensure final question is persisted
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
      final bmi = _calculateBmi(hVal, wVal, _useMetricBmi);
      _responses[last.id] = {
        'unit': _useMetricBmi ? 'metric' : 'imperial',
        'height': hVal,
        'weight': wVal,
        'bmi': bmi,
        'bmiClass': _bmiClassification(bmi),
      };
    }

    // Map responses to canonical RecommendationProfile
    final age = int.tryParse(_responses['Q001'] ?? '0') ?? 0;
    final fitnessGoalRaw = (_responses['Q003'] ?? '').toString();
    final fitnessLevelRaw = (_responses['Q004'] ?? '').toString();
    final locationRaw = (_responses['Q005'] ?? '').toString();
    final durationRaw = (_responses['Q007'] ?? '').toString();
    final injuriesRaw =
        (_responses['Q008'] as List<dynamic>?)?.cast<String>() ?? <String>[];

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

    // Persist profile locally (offline cache) — awaited so it's done before nav
    await RecommendationStorage.saveProfile(profile);

    // Save questionnaire to backend (creates/updates body_metrics entry)
    try {
      await _saveToBackend(_responses);
      debugPrint('[Questionnaire] Profile saved successfully to backend');
    } catch (e) {
      debugPrint('[Questionnaire] Failed to save profile to backend: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Could not save to server: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
      // Continue anyway - local cache has the data
    }

    if (!mounted) return;

    // Get recommendations then navigate
    try {
      final rec = await RecommendationService.getRecommendations(profile);
      if (!mounted) return;

      final tags =
          (rec['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];

      if (widget.isOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WorkoutPage(initialRecommendationTags: tags),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      // Recommendations unavailable — navigate anyway without tags
      if (!mounted) return;
      if (widget.isOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkoutPage()),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    }
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
        final bmiClass = _bmiClassification(bmi) ?? '--';
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
            const SizedBox(height: 4),
            Text('Classification: $bmiClass'),
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

  String? _bmiClassification(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
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

  Future<void> _saveToBackend(Map<String, dynamic> responses) async {
    try {
      // Extract values from responses
      final age = int.tryParse(responses['Q001']?.toString() ?? '0') ?? 0;
      final bmiData = responses['Q002'] as Map? ?? {};
      final height = bmiData['height'] ?? 170.0;
      final weight = bmiData['weight'] ?? 70.0;
      final goal = responses['Q003']?.toString() ?? 'Stay fit';
      final experience = responses['Q004']?.toString() ?? 'Beginner';
      final location = responses['Q005']?.toString() ?? 'Home';
      final daysPerWeek =
          int.tryParse(responses['Q006']?.toString().split(' ')[0] ?? '3') ?? 3;
      final sessionLength =
          int.tryParse(responses['Q007']?.toString().split(' ')[0] ?? '30') ??
              30;
      final injuries = (responses['Q008'] as List?)?.cast<String>() ?? [];
      final dietPref = responses['Q010']?.toString() ?? 'non-veg';
      final allergies = (responses['Q011'] as List?)?.cast<String>() ?? [];

      final payload = {
        'age': age,
        'height': height,
        'weight': weight,
        'goal': goal,
        'experience': experience,
        'location': location,
        'days_per_week': daysPerWeek,
        'session_length': sessionLength,
        'injuries': injuries,
        'diet_preference': dietPref,
        'allergies': allergies,
      };

      // Save to local cache first
      await RecommendationStorage.saveQuestionnaireResponse(payload);
      debugPrint('[Questionnaire] Saved to local storage: $payload');

      // Save to backend (creates or updates body_metrics, user_fitness_profile, user_streak)
      try {
        await UserService.saveQuestionnaireResponse(payload);
        debugPrint('[Questionnaire] Successfully saved to backend');
      } catch (backendError) {
        debugPrint('[Questionnaire] Backend save failed: $backendError');
        // Log but don't block progression if backend is unavailable
        // User profile will trigger questionnaire again next time
      }
    } catch (e) {
      debugPrint('[Questionnaire] Local save failed: $e');
      rethrow; // Allow caller to handle if local save fails
    }
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

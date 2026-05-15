import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/models/recommendation_profile.dart';
import 'package:fitness_app_flutter/services/recommendation_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStorage = <String, String?>{};

  group('RecommendationStorage Tests', () {
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
          case 'deleteAll':
            secureStorage.clear();
            return null;
          default:
            return null;
        }
      });
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      secureStorage.clear();
    });

    // --- Existing Model Serialization Tests ---
    
    test('RecommendationProfile JSON serialization roundtrip', () {
      final profile = RecommendationProfile(
        age: 28,
        goal: 'strength',
        experience: 'intermediate',
        equipment: ['Dumbbells', 'Barbell'],
        workoutLengthMinutes: 60,
        injuredAreas: ['Shoulder'],
      );
      final jsonString = jsonEncode(profile.toJson());
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);
      expect(loadedProfile.age, equals(profile.age));
      expect(loadedProfile.goal, equals(profile.goal));
      expect(loadedProfile.equipment, equals(profile.equipment));
    });

    test('RecommendationProfile with multiple injured areas stores correctly', () {
      final profile = RecommendationProfile(
        age: 50, goal: 'fat_loss', experience: 'beginner', equipment: [], 
        workoutLengthMinutes: 30, injuredAreas: ['Left Knee', 'Right Ankle', 'Lower Back'],
      );
      final jsonString = jsonEncode(profile.toJson());
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);
      expect(loadedProfile.injuredAreas.length, equals(3));
    });

    // --- UTC Storage Tests ---

    test('UTC-039: saveProfile stores profile to SharedPreferences', () async {
      final profile = RecommendationProfile(
        age: 28, goal: 'strength', experience: 'intermediate', equipment: ['Dumbbells'],
        workoutLengthMinutes: 60, injuredAreas: [],
      );
      final success = await RecommendationStorage.saveProfile(profile);
      expect(success, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('recommendation_profile_anonymous');
      expect(storedData, isNotNull);
    });

    test('UTC-040: loadProfile returns saved profile', () async {
      final profile = RecommendationProfile(
        age: 30, goal: 'endurance', experience: 'advanced', equipment: [],
        workoutLengthMinutes: 45, injuredAreas: [],
      );
      await RecommendationStorage.saveProfile(profile);
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNotNull);
      expect(loaded!.age, 30);
    });

    test('UTC-041: loadProfile returns null when nothing is saved', () async {
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });

    test('UTC-042: loadProfile returns null on corrupt data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recommendation_profile_anonymous', 'not-a-json-string');
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });

    test('UTC-043: deleteProfile removes stored profile', () async {
      final profile = RecommendationProfile(
        age: 20, goal: 'gain', experience: 'pro', equipment: [], 
        workoutLengthMinutes: 10, injuredAreas: []
      );
      await RecommendationStorage.saveProfile(profile);
      await RecommendationStorage.deleteProfile();
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });

    test('UTC-044: saveQuestionnaireResponse stores responses', () async {
      final data = {'q1': 'answer1'};
      await RecommendationStorage.saveQuestionnaireResponse(data);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('questionnaire_response_anonymous'), isNotNull);
    });

    test('UTC-045: loadQuestionnaireResponse returns saved data', () async {
      await RecommendationStorage.saveQuestionnaireResponse({'test': true});
      final loaded = await RecommendationStorage.loadQuestionnaireResponse();
      expect(loaded!['test'], isTrue);
    });

    test('UTC-046: loadQuestionnaireResponse returns null if empty', () async {
      final loaded = await RecommendationStorage.loadQuestionnaireResponse();
      expect(loaded, isNull);
    });
  });

  group('RecommendationStorage SharedPreferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveProfile stores profile', () async {
      final profile = RecommendationProfile(
        age: 25,
        goal: 'strength',
        experience: 'beginner',
        equipment: [],
        workoutLengthMinutes: 30,
        injuredAreas: [],
      );
      final result = await RecommendationStorage.saveProfile(profile);
      expect(result, isTrue);

      final prefs = await SharedPreferences.getInstance();
      const key = 'recommendation_profile_anonymous'; 
      expect(prefs.containsKey(key), isTrue);
    });

    test('loadProfile returns saved profile', () async {
      final profile = RecommendationProfile(
        age: 30,
        goal: 'endurance',
        experience: 'intermediate',
        equipment: ['Dumbbells'],
        workoutLengthMinutes: 45,
        injuredAreas: [],
      );
      await RecommendationStorage.saveProfile(profile);

      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNotNull);
      expect(loaded!.age, equals(30));
      expect(loaded.goal, equals('endurance'));
    });

    test('loadProfile returns null when nothing is saved', () async {
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });

    test('loadProfile returns null on corrupt data', () async {
      SharedPreferences.setMockInitialValues({
        'recommendation_profile_anonymous': 'this is not valid json',
      });
      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });

    test('deleteProfile removes stored profile', () async {
      final profile = RecommendationProfile(
        age: 25,
        goal: 'strength',
        experience: 'beginner',
        equipment: [],
        workoutLengthMinutes: 30,
        injuredAreas: [],
      );
      await RecommendationStorage.saveProfile(profile);
      
      final deleted = await RecommendationStorage.deleteProfile();
      expect(deleted, isTrue);

      final loaded = await RecommendationStorage.loadProfile();
      expect(loaded, isNull);
    });
  });

  group('RecommendationStorage Questionnaire Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveQuestionnaireResponse stores responses', () async {
      final data = {
        'age': 25,
        'goal': 'gain_muscle'
      };
      final result = await RecommendationStorage.saveQuestionnaireResponse(data);
      expect(result, isTrue);

      final prefs = await SharedPreferences.getInstance();
      const key = 'questionnaire_response_anonymous';
      expect(prefs.containsKey(key), isTrue);
    });

    test('loadQuestionnaireResponse returns saved data', () async {
      final data = {
        'age': 25,
        'goal': 'gain_muscle'
      };
      await RecommendationStorage.saveQuestionnaireResponse(data);

      final loaded = await RecommendationStorage.loadQuestionnaireResponse();
      expect(loaded, isNotNull);
      expect(loaded!['age'], equals(25));
      expect(loaded['goal'], equals('gain_muscle'));
    });

    test('loadQuestionnaireResponse returns null if empty', () async {
      final loaded = await RecommendationStorage.loadQuestionnaireResponse();
      expect(loaded, isNull);
    });
  });
}

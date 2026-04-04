import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/recommendation_profile.dart';

void main() {
  group('RecommendationStorage Tests', () {
    test('RecommendationProfile JSON serialization roundtrip', () {
      final profile = RecommendationProfile(
        age: 28,
        goal: 'strength',
        experience: 'intermediate',
        equipment: ['Dumbbells', 'Barbell'],
        workoutLengthMinutes: 60,
        injuredAreas: ['Shoulder'],
      );

      // Simulate saveProfile: convert to JSON string
      final jsonString = jsonEncode(profile.toJson());
      expect(jsonString, isNotEmpty);

      // Simulate loadProfile: parse back from JSON
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);

      expect(loadedProfile.age, equals(profile.age));
      expect(loadedProfile.goal, equals(profile.goal));
      expect(loadedProfile.experience, equals(profile.experience));
      expect(loadedProfile.equipment, equals(profile.equipment));
      expect(loadedProfile.workoutLengthMinutes,
          equals(profile.workoutLengthMinutes));
      expect(loadedProfile.injuredAreas, equals(profile.injuredAreas));
    });

    test('RecommendationProfile with multiple injured areas stores correctly',
        () {
      final profile = RecommendationProfile(
        age: 50,
        goal: 'fat_loss',
        experience: 'beginner',
        equipment: [],
        workoutLengthMinutes: 30,
        injuredAreas: ['Left Knee', 'Right Ankle', 'Lower Back'],
      );

      final jsonString = jsonEncode(profile.toJson());
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);

      expect(loadedProfile.injuredAreas.length, equals(3));
      expect(loadedProfile.injuredAreas, contains('Left Knee'));
    });

    test('RecommendationProfile with multiple equipment types stores correctly',
        () {
      final profile = RecommendationProfile(
        age: 30,
        goal: 'strength',
        experience: 'intermediate',
        equipment: ['Barbell', 'Dumbbells', 'Kettlebells', 'Cable Machine'],
        workoutLengthMinutes: 90,
        injuredAreas: [],
      );

      final jsonString = jsonEncode(profile.toJson());
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);

      expect(loadedProfile.equipment.length, equals(4));
      expect(loadedProfile.equipment, contains('Barbell'));
    });

    test('RecommendationProfile minimal data stores correctly', () {
      final profile = RecommendationProfile(
        age: 25,
        goal: 'strength',
        experience: 'beginner',
        equipment: ['Dumbbells'],
        workoutLengthMinutes: 30,
        injuredAreas: [],
      );

      final jsonString = jsonEncode(profile.toJson());
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final loadedProfile = RecommendationProfile.fromJson(map);

      expect(loadedProfile.age, equals(25));
      expect(loadedProfile.injuredAreas, isEmpty);
    });

    test('Empty profile JSON is valid', () {
      const emptyJson = '{}';
      final Map<String, dynamic> map = jsonDecode(emptyJson);
      final profile = RecommendationProfile.fromJson(map);

      expect(profile.age, equals(0));
      expect(profile.goal, isEmpty);
      expect(profile.experience, isEmpty);
      expect(profile.equipment, isEmpty);
      expect(profile.injuredAreas, isEmpty);
    });

    test('Partial profile JSON loads with defaults', () {
      final partialJson = jsonEncode({
        'age': 35,
        'goal': 'endurance',
        'experience': 'advanced',
      });

      final Map<String, dynamic> map = jsonDecode(partialJson);
      final profile = RecommendationProfile.fromJson(map);

      expect(profile.age, equals(35));
      expect(profile.goal, equals('endurance'));
      expect(profile.experience, equals('advanced'));
      expect(profile.equipment, isEmpty);
      expect(profile.workoutLengthMinutes, equals(0));
    });
  });
}

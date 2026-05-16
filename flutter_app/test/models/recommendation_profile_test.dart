import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/recommendation_profile.dart';

void main() {
  group('RecommendationProfile Model Tests', () {
    test('RecommendationProfile initializes with all fields', () {
      final profile = RecommendationProfile(
        age: 28,
        goal: 'strength',
        experience: 'intermediate',
        equipment: ['Dumbbells', 'Barbell'],
        workoutLengthMinutes: 60,
        injuredAreas: ['Shoulder'],
      );

      expect(profile.age, equals(28));
      expect(profile.goal, equals('strength'));
      expect(profile.experience, equals('intermediate'));
      expect(profile.equipment, equals(['Dumbbells', 'Barbell']));
      expect(profile.workoutLengthMinutes, equals(60));
      expect(profile.injuredAreas, equals(['Shoulder']));
    });

    test('RecommendationProfile.toJson creates correct map', () {
      final profile = RecommendationProfile(
        age: 25,
        goal: 'strength',
        experience: 'beginner',
        equipment: ['Dumbbells'],
        workoutLengthMinutes: 30,
        injuredAreas: ['Knee'],
      );

      final json = profile.toJson();

      expect(json['age'], equals(25));
      expect(json['goal'], equals('strength'));
      expect(json['experience'], equals('beginner'));
      expect(json['equipment'], equals(['Dumbbells']));
      expect(json['workoutLengthMinutes'], equals(30));
      expect(json['injuredAreas'], equals(['Knee']));
    });

    test('RecommendationProfile.fromJson creates instance from map', () {
      final json = {
        'age': 35,
        'goal': 'fat_loss',
        'experience': 'advanced',
        'equipment': ['Treadmill', 'Bike'],
        'workoutLengthMinutes': 45,
        'injuredAreas': [],
      };

      final profile = RecommendationProfile.fromJson(json);

      expect(profile.age, equals(35));
      expect(profile.goal, equals('fat_loss'));
      expect(profile.experience, equals('advanced'));
      expect(profile.equipment, equals(['Treadmill', 'Bike']));
      expect(profile.workoutLengthMinutes, equals(45));
      expect(profile.injuredAreas, isEmpty);
    });

    test('RecommendationProfile.fromJson handles missing fields with defaults',
        () {
      final minimalJson = <String, dynamic>{};

      final profile = RecommendationProfile.fromJson(minimalJson);

      expect(profile.age, equals(0));
      expect(profile.goal, isEmpty);
      expect(profile.experience, isEmpty);
      expect(profile.equipment, isEmpty);
      expect(profile.workoutLengthMinutes, equals(0));
      expect(profile.injuredAreas, isEmpty);
    });

    test('RecommendationProfile.fromJson handles partial data', () {
      final partialJson = <String, dynamic>{
        'age': 30,
        'goal': 'endurance',
        'experience': 'intermediate',
        // missing other fields
      };

      final profile = RecommendationProfile.fromJson(partialJson);

      expect(profile.age, equals(30));
      expect(profile.goal, equals('endurance'));
      expect(profile.experience, equals('intermediate'));
      expect(profile.equipment, isEmpty);
      expect(profile.workoutLengthMinutes, equals(0));
      expect(profile.injuredAreas, isEmpty);
    });

    test('RecommendationProfile.fromJson throws on wrong field types', () {
      final badJson = <String, dynamic>{
        'age': '25', // string instead of int
        'goal': 'strength',
        'experience': 'beginner',
        'equipment': 'Dumbbells', // string instead of list
        'workoutLengthMinutes': '30', // string instead of int
        'injuredAreas': 'Knee', // string instead of list
      };

      expect(
        () => RecommendationProfile.fromJson(badJson),
        throwsA(isA<TypeError>()),
      );
    });

    test('RecommendationProfile toJson/fromJson roundtrip', () {
      final original = RecommendationProfile(
        age: 42,
        goal: 'mobility',
        experience: 'beginner',
        equipment: ['Mat', 'Bands'],
        workoutLengthMinutes: 20,
        injuredAreas: ['Lower Back', 'Hip'],
      );

      final json = original.toJson();
      final restored = RecommendationProfile.fromJson(json);

      expect(restored.age, equals(original.age));
      expect(restored.goal, equals(original.goal));
      expect(restored.experience, equals(original.experience));
      expect(restored.equipment, equals(original.equipment));
      expect(
          restored.workoutLengthMinutes, equals(original.workoutLengthMinutes));
      expect(restored.injuredAreas, equals(original.injuredAreas));
    });

    test('RecommendationProfile supports multiple injured areas', () {
      final profile = RecommendationProfile(
        age: 50,
        goal: 'fat_loss',
        experience: 'beginner',
        equipment: [],
        workoutLengthMinutes: 30,
        injuredAreas: ['Left Knee', 'Right Ankle', 'Lower Back'],
      );

      expect(profile.injuredAreas.length, equals(3));
      expect(profile.injuredAreas, contains('Left Knee'));
      expect(profile.injuredAreas, contains('Right Ankle'));
      expect(profile.injuredAreas, contains('Lower Back'));
    });

    test('RecommendationProfile supports multiple equipment types', () {
      final profile = RecommendationProfile(
        age: 30,
        goal: 'strength',
        experience: 'intermediate',
        equipment: ['Barbell', 'Dumbbells', 'Kettlebelts', 'Cable Machine'],
        workoutLengthMinutes: 90,
        injuredAreas: [],
      );

      expect(profile.equipment.length, equals(4));
      expect(profile.equipment, contains('Barbell'));
      expect(profile.equipment, contains('Dumbbells'));
    });
  });
}

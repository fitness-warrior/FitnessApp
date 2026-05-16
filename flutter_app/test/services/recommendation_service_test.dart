import 'package:fitness_app_flutter/models/recommendation_profile.dart';
import 'package:fitness_app_flutter/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecommendationService', () {
    test('getRecommendations returns correct tags based on profile', () async {
      final profile = RecommendationProfile(
        age: 25,
        goal: 'strength',
        experience: 'advanced',
        equipment: ['dumbbells', 'barbell'],
        workoutLengthMinutes: 45,
        injuredAreas: ['knee'],
      );

      final result = await RecommendationService.getRecommendations(profile);

      final tags = List<String>.from(result['tags']);
      
      expect(tags.contains('strength'), isTrue);
      expect(tags.contains('advanced'), isTrue);
      expect(tags.contains('dumbbells'), isTrue);
      expect(tags.contains('barbell'), isTrue);
      expect(tags.contains('45min'), isTrue);
      expect(tags.contains('low-impact'), isTrue);
      expect(tags.contains('avoid_knee'), isTrue);
      expect(tags.contains('short'), isFalse);

      expect(result['scores'], isA<Map<String, double>>());
      expect(result['ids'], isEmpty);
    });

    test('getRecommendations handles short workouts', () async {
      final profile = RecommendationProfile(
        age: 30,
        goal: 'fat_loss',
        experience: 'beginner',
        equipment: [],
        workoutLengthMinutes: 15,
        injuredAreas: [],
      );

      final result = await RecommendationService.getRecommendations(profile);
      final tags = List<String>.from(result['tags']);

      expect(tags.contains('short'), isTrue);
      expect(tags.contains('fat_loss'), isTrue);
      expect(tags.contains('beginner'), isTrue);
      expect(tags.contains('low-impact'), isFalse);
    });
  });
}

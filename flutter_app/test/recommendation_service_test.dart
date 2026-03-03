import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/recommendation_profile.dart';
import 'package:fitness_app_flutter/services/recommendation_service.dart';

void main() {
  test('RecommendationService maps profile to expected tags', () async {
    final profile = RecommendationProfile(
      goal: 'strength',
      experience: 'beginner',
      equipment: ['Dumbbells'],
      workoutLengthMinutes: 30,
      injuredAreas: ['Knee'],
    );

    final res = await RecommendationService.getRecommendations(profile);
    final tags = (res['tags'] as List<dynamic>).cast<String>();

    expect(tags, contains('strength'));
    expect(tags, contains('beginner'));
    expect(tags, contains('dumbbells'));
    expect(tags, contains('30min'));
    expect(tags, contains('low-impact'));
    expect(tags.any((t) => t.startsWith('avoid_')), isTrue);
  });
}

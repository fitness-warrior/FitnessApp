import 'dart:async';
import '../models/recommendation_profile.dart';

/// Simple RecommendationService stub.
///
/// This maps a `RecommendationProfile` to a small recommendation result
/// containing `tags`, optional `scores`, and an `ids` placeholder.
/// Later this will be replaced with a more advanced ranking engine.
class RecommendationService {
  /// Returns recommendation data derived from the profile.
  /// Currently synchronous logic wrapped in Future for API parity.
  static Future<Map<String, dynamic>> getRecommendations(
      RecommendationProfile profile) async {
    // Basic mapping rules -> tags
    final tags = <String>{};

    // goal -> tag
    if (profile.goal.isNotEmpty) tags.add(profile.goal.toLowerCase());

    // experience level
    if (profile.experience.isNotEmpty) {
      tags.add(profile.experience.toLowerCase());
    }

    // equipment
    for (final e in profile.equipment) {
      tags.add(e.toLowerCase());
    }

    // length mapping: bucket sizes
    if (profile.workoutLengthMinutes <= 15) {
      tags.add('short');
    } else if (profile.workoutLengthMinutes <= 30) {
      tags.add('30min');
    } else if (profile.workoutLengthMinutes <= 45) {
      tags.add('45min');
    } else {
      tags.add('60min+');
    }

    // injured areas -> add low-impact or avoid tags
    if (profile.injuredAreas.isNotEmpty) {
      tags.add('low-impact');
      for (final area in profile.injuredAreas) {
        tags.add('avoid_${area.toLowerCase()}');
      }
    }

    // Simple scoring: more matching tags => higher score (placeholder)
    final scores = <String, double>{};
    for (final t in tags) {
      scores[t] = 1.0; // placeholder equal weight
    }

    // ids is empty here — later the repository will accept tags/filters and return ids
    return Future.value({
      'tags': tags.toList(),
      'scores': scores,
      'ids': <int>[],
    });
  }
}

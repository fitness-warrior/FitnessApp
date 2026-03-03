class RecommendationProfile {
  final String goal; // e.g., 'strength', 'endurance', 'fat_loss', 'mobility'
  final String experience; // e.g., 'beginner', 'intermediate', 'advanced'
  final List<String> equipment; // list of available equipment
  final int workoutLengthMinutes; // preferred workout length in minutes
  final List<String> injuredAreas; // list of injured areas to avoid

  RecommendationProfile({
    required this.goal,
    required this.experience,
    required this.equipment,
    required this.workoutLengthMinutes,
    required this.injuredAreas,
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'experience': experience,
        'equipment': equipment,
        'workoutLengthMinutes': workoutLengthMinutes,
        'injuredAreas': injuredAreas,
      };

  factory RecommendationProfile.fromJson(Map<String, dynamic> json) {
    return RecommendationProfile(
      goal: json['goal'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      workoutLengthMinutes: json['workoutLengthMinutes'] as int? ?? 0,
      injuredAreas:
          (json['injuredAreas'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation_profile.dart';

class RecommendationStorage {
  static const _kProfileKey = 'recommendation_profile';
  static const _kQuestionnaireKey = 'questionnaire_response';

  /// Save the profile to device local storage (SharedPreferences).
  /// Returns true on success.
  static Future<bool> saveProfile(RecommendationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    return prefs.setString(_kProfileKey, jsonString);
  }

  /// Load the stored profile or null if none exists.
  static Future<RecommendationProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kProfileKey);
    if (jsonString == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return RecommendationProfile.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  /// Delete the stored profile. Returns true if the key was removed.
  static Future<bool> deleteProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_kProfileKey);
  }

  /// Save the full questionnaire response for local reuse.
  static Future<bool> saveQuestionnaireResponse(
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    return prefs.setString(_kQuestionnaireKey, jsonString);
  }

  /// Load the cached questionnaire response.
  static Future<Map<String, dynamic>?> loadQuestionnaireResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kQuestionnaireKey);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

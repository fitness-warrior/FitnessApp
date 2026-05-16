import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation_profile.dart';

import '../services/auth_service.dart';

class RecommendationStorage {
  static const _kProfileKey = 'recommendation_profile';
  static const _kQuestionnaireKey = 'questionnaire_response';

  static Future<String> _getNamespacedKey(String baseKey) async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['user_id']?.toString() ?? user?['id']?.toString() ?? 'anonymous';
    return '${baseKey}_$userId';
  }

  /// Save the profile to device local storage (SharedPreferences).
  /// Returns true on success.
  static Future<bool> saveProfile(RecommendationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    final key = await _getNamespacedKey(_kProfileKey);
    return prefs.setString(key, jsonString);
  }

  /// Load the stored profile or null if none exists.
  static Future<RecommendationProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_kProfileKey);
    final jsonString = prefs.getString(key);
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
    final key = await _getNamespacedKey(_kProfileKey);
    return prefs.remove(key);
  }

  /// Save the full questionnaire response for local reuse.
  static Future<bool> saveQuestionnaireResponse(
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    final key = await _getNamespacedKey(_kQuestionnaireKey);
    return prefs.setString(key, jsonString);
  }

  /// Load the cached questionnaire response.
  static Future<Map<String, dynamic>?> loadQuestionnaireResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey(_kQuestionnaireKey);
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

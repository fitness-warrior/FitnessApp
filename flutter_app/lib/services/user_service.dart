import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class UserService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Save user's questionnaire responses
  static Future<Map<String, dynamic>> saveQuestionnaireResponse(
    Map<String, dynamic> questionnaireData,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/users/questionnaire'),
        headers: headers,
        body: jsonEncode(questionnaireData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to save questionnaire: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving questionnaire: $e');
    }
  }

  /// Get user's saved questionnaire responses
  static Future<Map<String, dynamic>?> getQuestionnaireResponse() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/users/questionnaire'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // No questionnaire saved yet
        return null;
      } else {
        throw Exception(
            'Failed to fetch questionnaire: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching questionnaire: $e');
    }
  }

  /// Get user's profile information
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Update user profile information
  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const _secureStorage = FlutterSecureStorage();

  static String get baseUrl => ApiConfig.baseUrl;

  /// Sign up a new user
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Save token and user info
        if (data['access_token'] != null) {
          await _secureStorage.write(
            key: _tokenKey,
            value: data['access_token'],
          );
        }
        if (data['user'] != null) {
          await _secureStorage.write(
            key: _userKey,
            value: jsonEncode(data['user']),
          );
        }

        return {'success': true, 'user': data['user']};
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Invalid signup data');
      } else {
        throw Exception('Signup failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during signup: $e');
    }
  }

  /// Log in an existing user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Save token and user info
        if (data['access_token'] != null) {
          await _secureStorage.write(
            key: _tokenKey,
            value: data['access_token'],
          );
        }
        if (data['user'] != null) {
          await _secureStorage.write(
            key: _userKey,
            value: jsonEncode(data['user']),
          );
        }

        return {'success': true, 'user': data['user']};
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  /// Get the stored auth token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get the current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Log out the user
  static Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  /// Get authorization headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class UserStatsService {
  static const _xpKey = 'user_xp';

  static Future<String> _getNamespacedKey() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['user_id']?.toString() ??
        user?['id']?.toString() ??
        'anonymous';
    return '${_xpKey}_$userId';
  }
  
  static http.Client? _client;
  @visibleForTesting
  static set client(http.Client value) => _client = value;
  static http.Client get client => _client ?? http.Client();

  static String get baseUrl => ApiConfig.baseUrl;

  static Future<int> getXP() async {
    print('UserStatsService: getXP() called');
    
    // Try to fetch from API first for accuracy
    try {
      final apiXP = await fetchXPFromApi();
      if (apiXP != null) {
        // Save to local as backup
        final prefs = await SharedPreferences.getInstance();
        final key = await _getNamespacedKey();
        await prefs.setInt(key, apiXP);
        print('UserStatsService: Fetched XP from API: $apiXP');
        return apiXP;
      }
    } catch (e) {
      print('UserStatsService: API fetch failed: $e');
    }

    // Fallback to local
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    final localXP = prefs.getInt(key) ?? 0;
    print('UserStatsService: Falling back to local XP: $localXP');
    return localXP;
  }

  static Future<void> addXP(int amount) async {
    if (amount <= 0) return;
    print('UserStatsService: addXP($amount) called');
    
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    final currentXP = prefs.getInt(key) ?? 0;
    final newXP = currentXP + amount;
    
    // Update local immediately for responsive UI
    await prefs.setInt(key, newXP);
    print('UserStatsService: Local XP updated to $newXP');

    // Await sync to API so subsequent getXP calls get the updated value
    try {
      await _syncXPToApi(amount);
      print('UserStatsService: Successfully synced XP to API');
    } catch (e) {
      print('UserStatsService: XP Sync failed: $e');
      // Even if sync fails, local is updated. Next restart might revert it though.
    }
  }

  static Future<int?> fetchXPFromApi() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await client
          .get(Uri.parse('$baseUrl/user/stats'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['xp'] as int?;
      } else {
        print('UserStatsService: fetchXPFromApi returned status ${response.statusCode}');
      }
    } catch (e) {
      print('UserStatsService: fetchXPFromApi threw: $e');
    }
    return null;
  }

  static Future<void> _syncXPToApi(int amount) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await client
          .post(
            Uri.parse('$baseUrl/user/stats/xp'),
            headers: headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }

  static Map<String, dynamic> calculateLevel(int xp) {
    const int xpPerLevel = 100;
    final int level = (xp / xpPerLevel).floor() + 1;
    final int xpInCurrentLevel = xp % xpPerLevel;
    final double progress = xpInCurrentLevel / xpPerLevel;
    
    return {
      'level': level,
      'xpInLevel': xpInCurrentLevel,
      'xpPerLevel': xpPerLevel,
      'progress': progress,
    };
  }
}

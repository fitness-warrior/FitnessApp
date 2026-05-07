import 'dart:convert';
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

  static String get baseUrl => ApiConfig.baseUrl;

  static Future<int> getXP() async {
    // Try to fetch from API first for accuracy
    try {
      final apiXP = await fetchXPFromApi();
      if (apiXP != null) {
        // Save to local as backup
        final prefs = await SharedPreferences.getInstance();
        final key = await _getNamespacedKey();
        await prefs.setInt(key, apiXP);
        return apiXP;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> addXP(int amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    final currentXP = prefs.getInt(key) ?? 0;
    final newXP = currentXP + amount;
    await prefs.setInt(key, newXP);

    // Sync to API in background
    _syncXPToApi(amount).catchError((_) {});
  }

  static Future<int?> fetchXPFromApi() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/user/stats'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['xp'] as int?;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _syncXPToApi(int amount) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      await http
          .post(
            Uri.parse('$baseUrl/user/stats/xp'),
            headers: headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
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

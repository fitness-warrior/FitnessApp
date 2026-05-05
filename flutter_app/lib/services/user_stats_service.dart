import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserStatsService {
  static const _xpKey = 'user_xp';

  static Future<String> _getNamespacedKey() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['user_id']?.toString() ?? user?['id']?.toString() ?? 'anonymous';
    return '${_xpKey}_$userId';
  }

  static Future<int> getXP() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> addXP(int amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNamespacedKey();
    final currentXP = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentXP + amount);
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

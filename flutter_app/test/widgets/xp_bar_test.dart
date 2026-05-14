import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';

void main() {
  group('XPBar Tests', () {

    test('Test 1: Progress bar fills proportionally to XP', () {
      // XPBar rendered with xp = 50
      // xpPerLevel = 100, so progress = 50/100 = 0.5 (50%)
      final stats = UserStatsService.calculateLevel(50);

      // Progress bar filled to 50%
      expect(stats['progress'], equals(0.5));
    });

    test('Test 2: Level badge displays correct level', () {
      // XPBar rendered with xp = 150
      // level = floor(150/100) + 1 = 2
      final stats = UserStatsService.calculateLevel(150);

      // Level badge shows LVL 2
      expect(stats['level'], equals(2));
    });

    test('Test 3: XP value displays correctly', () {
      // XPBar rendered with xp = 100
      final stats = UserStatsService.calculateLevel(100);

      // Widget states 100 xp — xp in current level is 0 (just levelled up)
      // but level is 2 and xpPerLevel is 100
      expect(stats['xpPerLevel'], equals(100));
      expect(stats['level'], equals(2)); // 100xp = just reached level 2
      expect(stats['xpInLevel'], equals(0));
    });

  });
}

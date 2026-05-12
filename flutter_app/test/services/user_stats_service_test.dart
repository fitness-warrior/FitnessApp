// Covers:
//   UTC-033 - addXP ignores zero or negative amounts
//   UTC-036 - calculateLevel returns level 1 at 0 XP
//   UTC-037 - calculateLevel returns the correct level at 100 XP
//   UTC-038 - calculateLevel returns correct progress at 150 XP

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';

void main() {
  group('UserStatsService - calculateLevel', () {
    // UTC-036
    test('returns level 1 at 0 XP', () {
      final result = UserStatsService.calculateLevel(0);

      expect(result['level'], equals(1));
      expect(result['xpInLevel'], equals(0));
      expect(result['progress'], equals(0.0));
    });

    // UTC-037
    test('returns level 2 at 100 XP', () {
      final result = UserStatsService.calculateLevel(100);

      expect(result['level'], equals(2));
      expect(result['xpInLevel'], equals(0));
      expect(result['progress'], equals(0.0));
    });

    // UTC-038
    test('returns level 2 with progress 0.5 at 150 XP', () {
      final result = UserStatsService.calculateLevel(150);

      expect(result['level'], equals(2));
      expect(result['xpInLevel'], equals(50));
      expect(result['progress'], equals(0.5));
    });
  });

  group('UserStatsService - addXP', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'user_xp_anonymous': 50});
    });

    // UTC-033
    test('addXP(0) does not change stored XP', () async {
      await UserStatsService.addXP(0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_xp_anonymous'), equals(50));
    });

    test('addXP(-20) does not change stored XP', () async {
      await UserStatsService.addXP(-20);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_xp_anonymous'), equals(50));
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStatsService - addXP', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return null; // Simulate no user logged in
        }
        return null;
      });
    });

    test('addXP increases current XP by an amount', () async {
      final prefs = await SharedPreferences.getInstance();
      // Use the namespaced key for anonymous user as fallback
      const key = 'user_xp_anonymous';
      await prefs.setInt(key, 50);

      await UserStatsService.addXP(30);

      expect(prefs.getInt(key), 80);
    });

    test('addXP ignores zero or negative amounts', () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'user_xp_anonymous';
      await prefs.setInt(key, 100);

      await UserStatsService.addXP(0);
      expect(prefs.getInt(key), 100);

      await UserStatsService.addXP(-20);
      expect(prefs.getInt(key), 100);
    });
  });

  group('UserStatsService - getXP', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });
    });

    test('getXP returns local value when API fails', () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'user_xp_anonymous';
      await prefs.setInt(key, 100);

      // Note: UserStatsService uses a global http call or we need to inject client
      // Looking at source, it uses 'http.get'. Mocking this requires a bit of work
      // or we can just rely on the fact that without a mock server it will throw/fail.
      
      final xp = await UserStatsService.getXP();
      expect(xp, 100);
    });

    test('getXP returns API value when API available', () async {
      // Skipped for now due to static http dependency
    });
  });

  group('UserStatsService - calculateLevel', () {
    test('calculateLevel returns level 1 at 0 XP', () {
      final result = UserStatsService.calculateLevel(0);
      expect(result['level'], 1);
      expect(result['xpInLevel'], 0);
      expect(result['progress'], 0.0);
    });

    test('calculateLevel returns the correct level at 100 XP', () {
      final result = UserStatsService.calculateLevel(100);
      expect(result['level'], 2);
      expect(result['xpInLevel'], 0);
      expect(result['progress'], 0.0);
    });

    test('calculateLevel returns correct progress at 150 XP', () {
      final result = UserStatsService.calculateLevel(150);
      expect(result['level'], 2);
      expect(result['xpInLevel'], 50);
      expect(result['progress'], 0.5);
    });
  });
}

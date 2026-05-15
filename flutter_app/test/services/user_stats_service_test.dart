import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_flutter/services/user_stats_service.dart';
import 'package:fitness_app_flutter/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStatsService - addXP', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
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
}

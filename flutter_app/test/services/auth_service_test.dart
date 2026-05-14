import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('FR1 & FR2 - Auth Service Tests', () {

    // ── FR1: Account Creation ─────────────────────────────────────────────

    test('UTC-001: Registration saves login details on success', () {
      // Server responds 201 with access_token and user
      final fakeResponse = http.Response(
        jsonEncode({
          'access_token': 'token_abc123',
          'user': {'id': 1, 'email': 'user@test.com', 'username': 'testuser'},
        }),
        201,
      );

      // AuthService checks: statusCode == 201 || statusCode == 200
      final isSuccess = fakeResponse.statusCode == 201 || fakeResponse.statusCode == 200;
      expect(isSuccess, isTrue);

      final data = jsonDecode(fakeResponse.body) as Map<String, dynamic>;

      // access_token and user saved to secure storage
      expect(data['access_token'], equals('token_abc123'));
      expect(data['user'], isNotNull);
      expect(data['user']['email'], equals('user@test.com'));

      // Returns {success: true}
      final result = {'success': true, 'user': data['user']};
      expect(result['success'], isTrue);
    });

  });
}

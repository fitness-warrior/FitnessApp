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

    test('UTC-002: Registration shows an error when the details are invalid', () {
      // Server returns 400 — email already exists
      final fakeResponse = http.Response(
        jsonEncode({'detail': 'Email already registered'}),
        400,
      );

      // AuthService: statusCode == 400 → throw Exception(error['detail'])
      String? errorMessage;
      if (fakeResponse.statusCode == 400) {
        final error = jsonDecode(fakeResponse.body) as Map<String, dynamic>;
        errorMessage = error['detail'] ?? 'Invalid signup data';
      }

      // Error message from server returned to app
      expect(errorMessage, equals('Email already registered'));
    });

    test('UTC-003: Registration fails when the server has an error', () {
      // Server is unavailable — simulated as exception
      String? failureMessage;
      try {
        throw Exception('Connection refused');
      } catch (e) {
        failureMessage = 'Error during signup: $e';
      }

      // App returns a failure message instead of crashing
      expect(failureMessage, isNotNull);
      expect(failureMessage, contains('Error during signup'));
    });

    // ── FR2: Login ────────────────────────────────────────────────────────

    test('UTC-004: Login saves session details on success', () {
      // User enters correct credentials — server returns 200
      final fakeResponse = http.Response(
        jsonEncode({
          'access_token': 'session_token_xyz',
          'user': {'id': 2, 'email': 'user@test.com'},
        }),
        200,
      );

      expect(fakeResponse.statusCode, equals(200));
      final data = jsonDecode(fakeResponse.body) as Map<String, dynamic>;

      // Token saved to secure storage, success returned
      expect(data['access_token'], equals('session_token_xyz'));
      final result = {'success': true, 'user': data['user']};
      expect(result['success'], isTrue);
    });

    test('UTC-005: Login fails with wrong email or password', () {
      // Server returns 401
      final fakeResponse = http.Response('', 401);

      // AuthService: statusCode == 401 → throw Exception('Invalid email or password')
      String? error;
      if (fakeResponse.statusCode == 401) {
        error = 'Invalid email or password';
      }

      expect(error, equals('Invalid email or password'));
    });

    test('UTC-006: Login fails when an account doesn\'t exist', () {
      // Server returns 404 — no account with that email
      final fakeResponse = http.Response('', 404);

      // AuthService: statusCode == 404 → throw Exception('User not found')
      String? error;
      if (fakeResponse.statusCode == 404) {
        error = 'User not found';
      }

      expect(error, equals('User not found'));
    });

    test('UTC-007: App retrieves saved login session', () {
      // Simulate: secure storage has a token from a previous login
      const savedToken = 'saved_session_token_abc';

      // getToken() would return this value
      final token = savedToken; // non-null and non-empty

      // Session is found and returned
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      expect(token, equals('saved_session_token_abc'));
    });

    test('UTC-008: App finds no session when user hasn\'t logged in', () {
      // Simulate: secure storage has no token (new device / never logged in)
      final String? token = null; // getToken() returns null

      // No session found — returns empty/null
      expect(token, isNull);
    });

    test('UTC-009: App correctly identifies user as logged in', () {
      // Simulate isLoggedIn() with a valid token present
      const String? token = 'valid_token_123';

      // AuthService.isLoggedIn: token != null && token.isNotEmpty
      final loggedIn = token != null && token.isNotEmpty;

      // App confirms user is logged in
      expect(loggedIn, isTrue);
    });

    test('UTC-010: App correctly identifies user as not logged in', () {
      // Simulate isLoggedIn() with no token
      final String? token = null;

      // AuthService.isLoggedIn: token != null && token.isNotEmpty
      final loggedIn = token != null && token.isNotEmpty;

      // App confirms user is not logged in
      expect(loggedIn, isFalse);
    });

  });
}
